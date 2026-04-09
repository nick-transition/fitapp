# FitApp Stripe Monetization — System Design Proposal

## Vision

Build a sustainable business model around FitApp as a protocol-style company. Open source codebase, automatic revenue splits for coaches/contributors/hosting/founder, subscription-based AI coaching features.

---

## Subscription Tiers

| Tier | Price | Features |
|------|-------|----------|
| **Free** | $0 | View programs, limited MCP interactions (5/day) |
| **Pro** | $9.99/mo | Unlimited MCP interactions, full session logging, exercise history queries, calendar features |
| **Coach** | $29.99/mo | Everything in Pro + publish programs to marketplace, revenue share on program sales, athlete management dashboard |

---

## Architecture

### Stripe Billing (Subscriptions)
- Stripe Customer object created on user signup
- Stripe Subscription object manages tier lifecycle
- Stripe Checkout (hosted) for payment UI — no PCI scope
- Webhook → Firebase Cloud Function → update `user.subscription` in Firestore

### Stripe Connect (Coach Revenue Share)
- Connected Accounts for coaches (Standard flow)
- Coach onboarding via Stripe-hosted Connect flow
- Revenue splits configured at the Stripe level
- Marketplace purchases → Stripe → automatic split to coach Connected Account

### MCP Subscription Gating
- Auth middleware in `auth.ts` checks `subscriptionTier` before tool execution
- Free tier tracked via `users/{uid}/usage/{date}` document (daily counter)
- Structured error response on limit hit — includes upgrade CTA Claude can surface

### Coach Program Marketplace
- `/marketplace/{programId}` Firestore collection
- Coach publishes program template with pricing
- Buyer checkout → webhook → copy program template to buyer's account
- Coach earnings visible in coach dashboard

---

## Data Model Changes

### `users/{uid}` — new fields
```
stripeCustomerId:       string        // Stripe Customer ID
subscriptionTier:       "free" | "pro" | "coach"
subscriptionStatus:     "active" | "canceled" | "past_due" | "trialing"
stripeConnectAccountId: string?       // coaches only
```

### New collection: `marketplace/{programId}`
```
programId:      string
coachId:        string        // users/{uid} ref
name:           string
description:    string
price:          number        // in cents
stripePriceId:  string        // Stripe Price ID
purchaseCount:  number
createdAt:      timestamp
publishedAt:    timestamp
```

---

## API Changes

### New Firebase Cloud Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `createCheckoutSession` | HTTPS | Creates Stripe Checkout session for subscription or program purchase |
| `handleWebhook` | HTTPS (Stripe webhook) | Handles subscription lifecycle events, purchase confirmations |
| `createConnectAccount` | HTTPS | Initiates Stripe Connect onboarding for coaches |
| `publishProgram` | HTTPS | Coach publishes program to marketplace (requires Coach tier) |

### MCP Tool Middleware

Add subscription check in `auth.ts` before routing to tool handler:

```
request → verify Firebase token → load user.subscriptionTier → check tier/usage → tool handler
```

Free tier: increment `users/{uid}/usage/{today}` counter, reject if > 5.

---

## Security

- Webhook signature verification via `stripe.webhooks.constructEvent()`
- Subscription status checked server-side on every MCP request — not trusted from client
- Coach Connect onboarding via Stripe-hosted flow (no raw bank details touch our servers)
- Firestore rules: users can only read their own subscription status; marketplace programs readable by all, writable only by owning coach

---

## Open Questions

1. **Free tier Claude access?** Should free tier have Claude/MCP access at all (limited), or is the free tier app-only (no AI)?
2. **Revenue split ratio?** 70/30 or 80/20 for coach/platform on marketplace sales?
3. **MCP gating granularity?** Do we gate individual MCP tools differently, or all-or-nothing per tier?
4. **Cancellation mid-month?** Grace period? Immediate downgrade? Retain access through billing period end?
5. **Open-source revenue protocol?** Traditional Stripe payouts to contributors, or on-chain splits (Base, Drips.network)?

---

## Issue Breakdown

| # | Issue | Size | Est. |
|---|-------|------|------|
| [01](issues/01-stripe-billing-setup.md) | Stripe Billing setup | Medium | 2-3 days |
| [02](issues/02-mcp-subscription-gating.md) | MCP subscription gating | Small | 1 day |
| [03](issues/03-coach-marketplace.md) | Coach program marketplace | Large | 5-7 days |
| [04](issues/04-open-source-revenue-protocol.md) | Open-source revenue protocol | Research | 3-5 days |
