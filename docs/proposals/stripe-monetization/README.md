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

## Comparable Projects & Market Context

### Fitness App Landscape
The fitness app market is $13.9B in 2026, growing at 13.4% CAGR to $33.6B by 2033. The dominant model is subscription-based with coaching tiers. Key comparables:

**Strava** — The closest analog to FitApp's social/coaching model. 40%+ of revenue from premium subscriptions. Free tier with activity tracking, paid tier ($5.99/mo) for advanced analytics, route building, and training plans. Strava's moat is its social network — FitApp's moat would be the AI coaching layer.

**Trainerize** — Coach-to-athlete platform. Coaches pay $5-$200/mo to manage clients, set programs, and track progress. Revenue model is B2B (coaches pay) not B2C. FitApp could combine both: athletes pay for AI features, coaches pay for marketplace access.

**wger** (github.com/wger-project/wger) — The most direct open-source comparable. Self-hosted FLOSS fitness/workout/nutrition tracker with 35K+ users and 500+ exercises. Licensed AGPL 3+. Funded entirely by donations — no revenue model. This is exactly the gap FitApp fills: open source fitness tracking with a sustainable business model on top.

**Future.co** — Premium AI + human coaching at $199/mo. Demonstrates willingness to pay for AI coaching features at premium price points. FitApp at $9.99/mo would be 20x cheaper.

### AI Agent Marketplace Comparables

**Virtuals Protocol** (virtuals.io) — Decentralized platform on Base for creating, deploying, and monetizing AI agents. Tokenizes agents and enables co-ownership + revenue sharing. Relevant pattern: FitApp coaches could "own" their AI coaching agent (trained on their methodology) and earn revenue from users who train with it.

**OpenAI GPT Store** — Marketplace where creators publish custom GPTs and earn based on usage. Revenue share model (though specifics have been controversial). Directly analogous to FitApp's coach marketplace: coaches publish program templates, users access them via AI.

---

## Open Source Strategy

### License
AGPL-3.0 — same as wger. This ensures the codebase stays open while requiring anyone who hosts a modified version to share their changes. The AGPL's network clause is key: if someone forks FitApp and runs it as a service, they must open-source their modifications.

### Revenue Protocol
Inspired by three existing open-source funding mechanisms:

**tea.xyz** — A permissionless protocol that rewards open-source contributors via cryptographic signatures. Uses "Proof of Contribution" to score projects and distribute TEA tokens. Relevant for tracking contributor impact.

**Drips Protocol** (drips.network) — Ethereum-based protocol enabling organizations to fund OSS dependencies. ENS streamed $50K USDC over 6 months to 7 projects. Relevant model for FitApp's infrastructure: subscription revenue streams to contributors via Drips.

**Open Collective** — Traditional (non-crypto) fiscal hosting for open-source projects. Transparent budgets, expense tracking, contributor payouts. Could serve as Phase 1 before moving to on-chain.

### Proposed Revenue Split

| Recipient | Share | Mechanism |
|-----------|-------|-----------|
| Founder/Core Team | 40% | Direct Stripe payout |
| Contributor Pool | 25% | Drips or Open Collective, weighted by contribution |
| Infrastructure/Hosting | 15% | Automated via GCP billing |
| Coach Revenue Share | 20% | Stripe Connect (from marketplace sales only) |

### Contribution Tracking
- Phase 1: Manual allocation based on PRs merged, issues closed, features shipped
- Phase 2: Automated via GitHub API integration — weight by lines changed, review activity, issue resolution
- Phase 3: On-chain via tea.xyz-style Proof of Contribution or custom smart contract on Base

### Why Open Source?
1. **Trust**: Users trust open-source fitness apps with their health data more than closed-source alternatives
2. **Contributions**: Community contributions accelerate development (wger has 100+ contributors)
3. **Moat**: The AI coaching layer and marketplace are the moat, not the codebase. Open-sourcing the tracker doesn't give away the competitive advantage
4. **Alignment**: Protocol-style companies align contributor incentives with company growth

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
