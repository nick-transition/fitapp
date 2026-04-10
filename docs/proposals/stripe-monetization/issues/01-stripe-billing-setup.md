# Issue: Set up Stripe Billing integration

## Description
Integrate Stripe Billing for subscription management. Create Customer objects on user signup, handle checkout sessions, and sync subscription status to Firestore via webhooks.

## Acceptance Criteria
- [ ] Stripe Customer created when user signs up
- [ ] Checkout session creates subscription (Free/Pro/Coach tiers)
- [ ] Webhook handler updates user.subscriptionTier and user.subscriptionStatus in Firestore
- [ ] Subscription status survives page reloads (persisted in Firestore, not just client state)

## Technical Notes
- Use Stripe Checkout (hosted) for initial implementation
- Webhook endpoint as Firebase Cloud Function
- Verify webhook signatures with Stripe signing secret
- Store stripeCustomerId on user document

## Dependencies
- Stripe account setup
- Firebase Cloud Functions (already deployed)

## Estimate: Medium (2-3 days)
