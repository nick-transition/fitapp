# Issue: Design open-source revenue protocol

## Description
Design the protocol-style revenue sharing system. Contributors, hosting costs, and the founder all get automatic splits from subscription revenue.

## Acceptance Criteria
- [ ] Revenue split model defined (founder %, contributor pool %, hosting/infra %)
- [ ] Contributor attribution system designed (git commits? Issues closed? Manual allocation?)
- [ ] Smart contract or traditional payment split mechanism selected
- [ ] Monthly payout schedule defined

## Technical Notes
- Phase 1: Traditional Stripe splits (manual or scheduled payouts)
- Phase 2: On-chain revenue splits via smart contracts (if desired)
- Consider: Open Collective, Drips.network, or custom solution
- Contributor tracking could integrate with GitHub API (commits, PRs merged)

## Open Questions
- What blockchain/L2 for smart contracts? (Ethereum? Base? Solana?)
- How to value different contribution types?
- Minimum payout threshold?

## Dependencies
- Issue #01 (Stripe Billing — revenue to split)
- Issue #03 (Coach marketplace — coach revenue share)

## Estimate: Research + Design (3-5 days), Implementation (TBD)
