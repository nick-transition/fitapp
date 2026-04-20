# Bounties

FitApp pilots a **fixed-dollar bounty program** for select roadmap items. Bounties are paid via a one-time [GitHub Sponsors](https://github.com/sponsors) sponsorship on PR merge. They are **in addition to** the [revenue-pool contribution points](CONTRIBUTING.md) — claiming a bounty does not reduce your monthly pool share.

> **Trust-based, no escrow.** There's no platform holding funds. Maintainer commits publicly in the issue to pay on merge; payment happens within 48 hours of merge. If this is a blocker for you, don't claim — open an issue instead and we'll discuss.

## How it works

1. A maintainer opens an issue labeled [`bounty`](https://github.com/nick-transition/fitapp/issues?q=is%3Aissue+label%3Abounty) with scope, acceptance criteria, and a dollar amount stated in the issue body.
2. You comment on the issue saying you're attempting it (`"I'd like to work on this"` is fine — this isn't slash-command-driven). A maintainer replies to approve, which marks the bounty claimed so others don't duplicate work.
3. You open a PR that says `Closes #N`, follows the PR template (including AI disclosure), and meets the acceptance criteria.
4. On merge, the maintainer sends you a one-time GitHub Sponsors sponsorship for the stated amount.

## Receiving payment

Preferred: you have [GitHub Sponsors](https://github.com/sponsors) enabled on your account to receive a one-time sponsorship. Setup is free and takes ~10 minutes.

If you can't use GitHub Sponsors (not available in your region, don't want to set it up for $100, etc.), mention it in the PR and we'll arrange PayPal, Wise, or a direct Stripe invoice instead.

## What a bountied issue looks like

Every bountied issue has:

- **Scope** — a numbered list of what must ship
- **Out of scope** — explicit non-goals to prevent scope creep
- **Acceptance criteria** — the checklist a PR must satisfy
- **Size** — S / M / L (drives the bounty $)
- A maintainer comment stating the dollar amount and payment commitment

## Sizing

| Size | Lines | Scope hint | Suggested $ |
|------|-------|------------|-------------|
| S    | <50   | Config, single widget, docs fix | $100–$200 |
| M    | 50–200 | Feature touching 2–4 files, tests included | $300–$600 |
| L    | 200+  | New screen, new service, or migration | $800–$2000 |

## Relationship to the revenue pool

Bounties are separate from, and additive to, the 25% revenue pool described in
[CONTRIBUTING.md](CONTRIBUTING.md) and
[docs/proposals/stripe-monetization/open-source-strategy.md](docs/proposals/stripe-monetization/open-source-strategy.md).

A merged bountied PR:
- Triggers the GitHub Sponsors bounty payout within 48 hours
- Still earns you PR points (S=1, M=3, L=5) toward the monthly pool distribution

## Proposing a new bounty

Roadmap items only become bounties once they have tight scope and acceptance
criteria. To propose one, open a [Bounty Proposal](.github/ISSUE_TEMPLATE/bounty_proposal.md)
issue. A maintainer converts approved proposals into the live bountied issue.

## Etiquette

- Don't claim more than one bounty at a time without merging the prior one.
- If a claimed bounty goes quiet for 14+ days with no PR, the maintainer releases it back to the queue.
- Ambiguous scope → ask in the issue before starting. Clarifications are free.

## Why GitHub Sponsors (and not a bounty platform)?

As of April 2026, the two established bounty platforms (Algora and Polar) have both pivoted away from self-serve issue bounties — Algora toward recruiting, Polar toward SaaS billing. Rather than fight the platform question for a small pilot, bounties here are paid directly via GitHub Sponsors on merge. If the pilot scales, we'll revisit OpenCollective or a rolled-own escrow.

## History

_First bounty pending — this section will track completed bounties, time-to-merge, and any scope adjustments once the pilot runs._
