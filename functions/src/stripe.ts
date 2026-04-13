import * as admin from 'firebase-admin';
import { onRequest, Request } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import Stripe from 'stripe';
import { resolveUser } from './auth.js';

export const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
export const STRIPE_WEBHOOK_SECRET = defineSecret('STRIPE_WEBHOOK_SECRET');

type SubscriptionTier = 'free' | 'pro' | 'coach';
type SubscriptionStatus = 'active' | 'canceled' | 'past_due' | 'trialing';

// SubscriptionStatusRaw matches the Stripe SDK's Subscription.Status literal union
type StripeSubscriptionStatus = 'active' | 'canceled' | 'incomplete' | 'incomplete_expired' | 'past_due' | 'paused' | 'trialing' | 'unpaid';

// Stripe mode is determined by the secret key prefix (sk_test_ vs sk_live_).
// Price IDs differ between test and live mode — configure both sets.
const isTestMode = (): boolean => STRIPE_SECRET_KEY.value().startsWith('sk_test_');

const PRICE_IDS_LIVE: Record<SubscriptionTier, string | null> = {
  free: null,
  pro: process.env.STRIPE_PRO_PRICE_ID_LIVE || 'price_1TKcyWPtbwp1t4mSEwScBDRT',
  coach: process.env.STRIPE_COACH_PRICE_ID_LIVE || 'price_1TKcyWPtbwp1t4mScl7d3fyz',
};

const PRICE_IDS_TEST: Record<SubscriptionTier, string | null> = {
  free: null,
  pro: process.env.STRIPE_PRO_PRICE_ID_TEST || null,
  coach: process.env.STRIPE_COACH_PRICE_ID_TEST || null,
};

function getPriceIds(): Record<SubscriptionTier, string | null> {
  return isTestMode() ? PRICE_IDS_TEST : PRICE_IDS_LIVE;
}

function getStripe(): InstanceType<typeof Stripe> {
  return new Stripe(STRIPE_SECRET_KEY.value(), { apiVersion: '2026-03-25.dahlia' });
}

/**
 * Creates a Stripe Checkout session for subscription signup.
 * Expects JSON body: { tier: 'pro' | 'coach', successUrl: string, cancelUrl: string }
 * Returns: { url: string }
 */
export const createCheckoutSession = onRequest(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
    secrets: [STRIPE_SECRET_KEY],
  },
  async (req: Request, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
      const auth = await resolveUser(req);
      const { tier, successUrl, cancelUrl } = req.body as {
        tier: SubscriptionTier;
        successUrl: string;
        cancelUrl: string;
      };

      if (!tier || !successUrl || !cancelUrl) {
        res.status(400).json({ error: 'Missing required fields: tier, successUrl, cancelUrl' });
        return;
      }

      const priceIds = getPriceIds();
      const priceId = priceIds[tier];
      if (!priceId) {
        const mode = isTestMode() ? 'test' : 'live';
        res.status(400).json({
          error: `No price configured for tier "${tier}" in ${mode} mode. `
            + (isTestMode()
              ? 'Set STRIPE_PRO_PRICE_ID_TEST / STRIPE_COACH_PRICE_ID_TEST env vars.'
              : 'Check PRICE_IDS_LIVE in stripe.ts.'),
        });
        return;
      }

      const stripe = getStripe();

      // Get or create a Stripe Customer for this user
      const userDoc = await admin.firestore().doc(`users/${auth.userId}`).get();
      const userData = userDoc.data() ?? {};
      let customerId: string = userData.stripeCustomerId as string;

      if (!customerId) {
        const customer = await stripe.customers.create({
          metadata: { firebaseUid: auth.userId },
        });
        customerId = customer.id;
        await admin.firestore().doc(`users/${auth.userId}`).set(
          { stripeCustomerId: customerId },
          { merge: true }
        );
      }

      const session = await stripe.checkout.sessions.create({
        customer: customerId,
        mode: 'subscription',
        line_items: [{ price: priceId, quantity: 1 }],
        success_url: successUrl,
        cancel_url: cancelUrl,
        metadata: { firebaseUid: auth.userId, tier },
      });

      res.status(200).json({ url: session.url });
    } catch (error) {
      const message = (error as Error).message;
      if (
        message === 'Missing Authorization header' ||
        message === 'Missing token' ||
        message === 'Invalid credentials'
      ) {
        res.status(401).json({ error: message });
      } else {
        console.error('createCheckoutSession error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }
);

/**
 * Stripe webhook handler. Receives events from Stripe and syncs subscription
 * status to Firestore users/{uid}.
 */
export const handleStripeWebhook = onRequest(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
    secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET],
  },
  async (req: Request, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const sig = req.headers['stripe-signature'] as string;
    if (!sig) {
      res.status(400).json({ error: 'Missing stripe-signature header' });
      return;
    }

    let event: ReturnType<InstanceType<typeof Stripe>['webhooks']['constructEvent']>;
    try {
      const stripe = getStripe();
      event = stripe.webhooks.constructEvent(
        (req as unknown as { rawBody: Buffer }).rawBody,
        sig,
        STRIPE_WEBHOOK_SECRET.value()
      );
    } catch (err) {
      console.error('Webhook signature verification failed:', err);
      res.status(400).json({ error: 'Invalid signature' });
      return;
    }

    try {
      switch (event.type) {
        case 'checkout.session.completed': {
          const session = event.data.object as {
            customer: string;
            subscription: string;
            metadata: Record<string, string>;
          };
          await handleCheckoutCompleted(session);
          break;
        }
        case 'customer.subscription.updated': {
          const subscription = event.data.object as {
            id: string;
            customer: string;
            status: StripeSubscriptionStatus;
            items: { data: Array<{ price: { id: string } }> };
          };
          await handleSubscriptionUpdated(subscription);
          break;
        }
        case 'customer.subscription.deleted': {
          const subscription = event.data.object as {
            id: string;
            customer: string;
          };
          await handleSubscriptionDeleted(subscription);
          break;
        }
        default:
          // Unhandled event type — acknowledge receipt
          break;
      }

      res.status(200).json({ received: true });
    } catch (error) {
      console.error('Webhook handler error:', error);
      res.status(500).json({ error: 'Webhook handler failed' });
    }
  }
);

async function handleCheckoutCompleted(session: {
  customer: string;
  subscription: string;
  metadata: Record<string, string>;
}): Promise<void> {
  const firebaseUid = session.metadata?.firebaseUid;
  const tier = (session.metadata?.tier as SubscriptionTier) ?? 'pro';
  if (!firebaseUid) {
    console.error('checkout.session.completed: missing firebaseUid in metadata');
    return;
  }

  const stripe = getStripe();
  const subscription = await stripe.subscriptions.retrieve(session.subscription);
  const status = mapStripeStatus(subscription.status as StripeSubscriptionStatus);

  await admin.firestore().doc(`users/${firebaseUid}`).set(
    {
      stripeCustomerId: session.customer,
      stripeSubscriptionId: session.subscription,
      subscriptionTier: tier,
      subscriptionStatus: status,
    },
    { merge: true }
  );
}

async function handleSubscriptionUpdated(subscription: {
  id: string;
  customer: string;
  status: StripeSubscriptionStatus;
  items: { data: Array<{ price: { id: string } }> };
}): Promise<void> {
  const uid = await uidFromCustomer(subscription.customer);
  if (!uid) return;

  const tier = tierFromPriceId(subscription.items.data[0]?.price?.id);
  const status = mapStripeStatus(subscription.status);

  await admin.firestore().doc(`users/${uid}`).set(
    {
      stripeSubscriptionId: subscription.id,
      subscriptionTier: tier,
      subscriptionStatus: status,
    },
    { merge: true }
  );
}

async function handleSubscriptionDeleted(subscription: {
  id: string;
  customer: string;
}): Promise<void> {
  const uid = await uidFromCustomer(subscription.customer);
  if (!uid) return;

  await admin.firestore().doc(`users/${uid}`).set(
    {
      stripeSubscriptionId: subscription.id,
      subscriptionTier: 'free' as SubscriptionTier,
      subscriptionStatus: 'canceled' as SubscriptionStatus,
    },
    { merge: true }
  );
}

/**
 * Creates a Stripe Customer Portal session for managing subscriptions.
 * Expects JSON body: { returnUrl: string }
 * Returns: { url: string }
 */
export const createPortalSession = onRequest(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
    secrets: [STRIPE_SECRET_KEY],
  },
  async (req: Request, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
      const auth = await resolveUser(req);
      const { returnUrl } = req.body as { returnUrl: string };

      if (!returnUrl) {
        res.status(400).json({ error: 'Missing required field: returnUrl' });
        return;
      }

      const userDoc = await admin.firestore().doc(`users/${auth.userId}`).get();
      const customerId = userDoc.data()?.stripeCustomerId as string | undefined;

      if (!customerId) {
        res.status(400).json({ error: 'No Stripe customer found for this user' });
        return;
      }

      const stripe = getStripe();
      const portalSession = await stripe.billingPortal.sessions.create({
        customer: customerId,
        return_url: returnUrl,
      });

      res.status(200).json({ url: portalSession.url });
    } catch (error) {
      const message = (error as Error).message;
      if (
        message === 'Missing Authorization header' ||
        message === 'Missing token' ||
        message === 'Invalid credentials'
      ) {
        res.status(401).json({ error: message });
      } else {
        console.error('createPortalSession error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }
);

// --- Helpers ---

async function uidFromCustomer(customerId: string): Promise<string | null> {
  const snapshot = await admin
    .firestore()
    .collection('users')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    console.error(`No user found for Stripe customer: ${customerId}`);
    return null;
  }
  return snapshot.docs[0].id;
}

function mapStripeStatus(status: StripeSubscriptionStatus): SubscriptionStatus {
  switch (status) {
    case 'active':
      return 'active';
    case 'canceled':
      return 'canceled';
    case 'past_due':
      return 'past_due';
    case 'trialing':
      return 'trialing';
    default:
      return 'canceled';
  }
}

function tierFromPriceId(priceId: string | undefined): SubscriptionTier {
  const priceIds = getPriceIds();
  if (priceId === priceIds.coach) return 'coach';
  if (priceId === priceIds.pro) return 'pro';
  return 'pro';
}
