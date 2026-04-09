# Issue: Coach program marketplace

## Description
Allow coaches to publish workout programs to a marketplace. Users can browse and purchase programs. Coaches earn revenue share via Stripe Connect.

## Acceptance Criteria
- [ ] Coach can publish a program as a marketplace template
- [ ] Published programs appear in /marketplace collection with pricing
- [ ] Users can purchase programs (creates Stripe payment + copies program to their account)
- [ ] Coach receives revenue share via Stripe Connect
- [ ] Coach dashboard shows published programs and earnings

## Technical Notes
- Stripe Connect Standard accounts for coaches
- Coach onboarding via Stripe-hosted Connect flow
- Revenue split configured in Stripe (e.g., 80% coach / 20% platform)
- Purchase flow: Stripe Checkout → webhook → copy program template to buyer's account
- Marketplace collection: programId, coachId, name, description, price, stripePriceId, purchaseCount

## Dependencies
- Issue #01 (Stripe Billing)
- Issue #02 (subscription gating — Coach tier required)

## Estimate: Large (5-7 days)
