# Open Source Strategy

## Overview

FitApp will be released under **AGPL-3.0** with an on-chain contributor compensation protocol. The goal is to build a self-sustaining open source fitness platform where contributors are paid proportionally to their impact — not just thanked in a README.

---

## License: AGPL-3.0

**Why AGPL-3.0 and not MIT or Apache-2.0:**

- AGPL's network copyleft clause requires any SaaS deployment of FitApp to either release their modifications or purchase a commercial license
- This protects against large fitness platforms (Peloton, Garmin, Whoop) forking FitApp without contributing back
- Commercial license revenue flows into the contributor pool
- wger (the closest comparable) uses AGPL-3.0 for the same reason; it works

**Dual licensing path (Phase 2+):**

- Open source: AGPL-3.0 (free, copyleft)
- Commercial: paid license for organizations that cannot open-source their modifications
- Commercial license fee: tiered by company size ($500–$5,000/yr)

---

## Revenue Protocol: Proof of Contribution

Inspired by **tea.xyz** (Proof of Contribution), **Drips Protocol**, and **Open Collective**, FitApp's revenue protocol streams payments to contributors based on verifiable on-chain contribution metrics.

### Revenue Split

| Recipient | Share | Rationale |
|---|---|---|
| Founder | 40% | Sustained development, infrastructure costs, business operations |
| Contributor Pool | 25% | Distributed to OSS contributors via Drips Protocol |
| Infrastructure | 15% | Hosting, Firebase, CDN, CI/CD |
| Coach Revenue | 20% | Direct payments to certified coaches on the platform |

> The revenue split is encoded in a smart contract. All distributions are on-chain and publicly auditable.

### Contributor Pool Distribution

The 25% Contributor Pool is allocated monthly using a weighted scoring formula:

```
contributor_share = (contributor_score / total_score) * pool_amount
```

**Contributor score inputs:**

- Merged PRs (weighted by complexity label: `small=1`, `medium=3`, `large=10`)
- Issue reports with reproduction steps (`+2` each)
- Reviewed PRs with substantive feedback (`+1` each)
- Documentation contributions (`+1` per merged doc page)
- Dependency maintenance (automated, `+0.5` per upstream patch applied)

Scores are computed from GitHub events via a GitHub Action, published to IPFS, and used as input to the Drips allocation contract.

---

## Protocol Stack

### Drips Protocol (Primary)

**What it is:** Ethereum-native streaming payments protocol. DAOs and projects stream ERC-20 tokens continuously to contributors.

**Precedent:** ENS DAO streamed $50,000 to 7 open source projects via Drips in 2023. Gitcoin and Uniswap Foundation use it for sustained contributor funding.

**FitApp usage:**
- Subscription and commercial license revenue converted to USDC monthly
- USDC streamed proportionally to contributor addresses via Drips
- No manual payroll; contributors receive funds in real-time

**Chain:** Ethereum mainnet or Base (lower gas, same security model)

### tea.xyz (Inspiration)

**What it is:** Proof of Contribution protocol that scores open source packages by downstream dependency weight and streams rewards to maintainers.

**What FitApp borrows:** The concept that contribution value is measurable on-chain and should flow automatically without governance votes or grant applications.

**Difference:** tea.xyz scores by package dependency graph; FitApp scores by direct GitHub contribution metrics (more appropriate for a single-repo project).

### Open Collective (Web2 fallback)

**What it is:** Fiscal hosting platform for open source projects. Handles invoicing, expense reimbursement, and transparent ledger.

**FitApp usage (Phase 1 only):** Before the on-chain protocol is live, Open Collective hosts the contributor fund. All income and expenses are public. Contributors submit expenses; maintainers approve.

**Transition:** When Drips integration ships, the Open Collective balance migrates on-chain and streaming payments replace manual expense reimbursement.

---

## Phased Contribution Tracking Plan

### Phase 1 — Manual (Month 0–3)

- Open Collective fiscal host active
- Contributions tracked manually in `CONTRIBUTORS.md`
- Monthly maintainer review allocates pool share
- No automation; relies on trust and transparency

**Exit criteria:** >5 external contributors, >$500/mo flowing through the pool

### Phase 2 — GitHub Automation (Month 3–6)

- GitHub Action computes contributor scores weekly from event API
- Scores published as JSON to repo (`contributors/scores.json`)
- Pool allocation still manual but based on published scores
- Contributors can audit and dispute scores via PR

**Exit criteria:** Score computation trusted by contributors, <2 disputes per month

### Phase 3 — On-Chain Streaming (Month 6–12)

- Drips Protocol contract deployed on Base
- Score JSON published to IPFS; contract reads allocation weights
- USDC streaming activated; contributors receive funds continuously
- Open Collective wound down; all financials on-chain

**Exit criteria:** 3 consecutive months of uninterrupted on-chain payouts

### Phase 4 — Protocol Decentralization (Month 12+)

- Governance token introduced (optional; only if community requests it)
- Score formula parameters moveable via on-chain vote
- Commercial license fee structure governed by contributor DAO
- Founder share vests down from 40% to 30% as contributor pool grows

---

## Contributor Onboarding

```markdown
## How to Get Paid for Contributing to FitApp

1. Open an issue or pick one labeled `good first issue`
2. Submit a PR with your change
3. Once merged, add your Ethereum address to `contributors/addresses.json`
4. Scores are computed weekly; distributions happen monthly
5. Check `contributors/scores.json` to see your current allocation weight
```

All of the above is documented in `CONTRIBUTING.md` (to be written in Phase 1).

---

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Contributor gaming (spam PRs for score) | Maintainer veto on complexity labels; score decay for reverted PRs |
| Gas costs make micro-payments uneconomical | Use Base (L2); batch monthly rather than stream if amounts are <$10 |
| AGPL license friction for enterprise adoption | Commercial license path available from Day 1 |
| Drips Protocol smart contract risk | Use audited v2 contracts; cap on-chain balance, sweep monthly |
| Contributor address privacy | Allow pseudonymous ENS addresses; no KYC required |

---

## References

- [Drips Protocol](https://drips.network) — streaming payment infrastructure
- [tea.xyz Whitepaper](https://tea.xyz/tea.white-paper.pdf) — Proof of Contribution
- [Open Collective](https://opencollective.com) — fiscal hosting
- [wger on Open Collective](https://opencollective.com/wger) — fitness OSS precedent
- [ENS x Drips case study](https://blog.drips.network/ens-funds-open-source) — $50K to 7 projects
