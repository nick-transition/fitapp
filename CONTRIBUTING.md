# Contributing to FitApp

Thank you for your interest in contributing to FitApp! This project is built as a protocol-style open source company where contributors earn from the revenue pool.

## Bounties

Select roadmap items have fixed-dollar bounties paid via a one-time [GitHub Sponsors](https://github.com/sponsors) sponsorship on PR merge. Bounties are **additive to** the revenue-pool points below — a bountied PR earns both. See [BOUNTIES.md](BOUNTIES.md) for the workflow (claiming, acceptance criteria, sizing).

Browse open bounties: [issues labeled `bounty`](https://github.com/nick-transition/fitapp/issues?q=is%3Aissue+label%3Abounty).

## How Contributors Earn

FitApp allocates 25% of subscription revenue to the contributor pool. Contributions are scored based on:

| Contribution | Points |
|---|---|
| Small PR (< 50 lines) | 1 |
| Medium PR (50-200 lines) | 3 |
| Large PR (200+ lines) | 5 |
| Issue resolved | 2 |
| Code review | 1 |
| Documentation | 2 |

Payouts are calculated monthly based on your share of total points.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/fitapp.git`
3. Install dependencies: `flutter pub get && cd functions && npm install`
4. Start Firebase emulators: `firebase emulators:start`
5. Run the app: `flutter run -d chrome`

## Development Workflow

1. Create a branch from `main`: `git checkout -b feat/your-feature`
2. Make your changes
3. Run tests: `flutter test`
4. Push and open a PR against `main`
5. CI will run build checks automatically
6. Get a review and merge

## AI Usage Standards

We embrace AI-assisted development. When using AI tools:

- **Always disclose** AI tool usage in your PR using the template
- **Review all AI output** — you are responsible for the code you submit
- **Don't blindly commit** AI-generated code without understanding it
- **Security-sensitive code** (auth, payments, data access) must be human-reviewed
- **Tests** should validate AI-generated code independently

Recommended tools: Claude Code, GitHub Copilot, Cursor

## Code Standards

- Dart: Follow the [Effective Dart](https://dart.dev/effective-dart) guidelines
- TypeScript (Functions): Use strict mode, no `any` types
- Commits: Use conventional commits (`feat:`, `fix:`, `docs:`, `test:`)
- PRs: One feature/fix per PR, use the PR template

## License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 license.
