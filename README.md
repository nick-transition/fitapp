# FitApp

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

A Flutter-based fitness coaching app built as a protocol-style open source company — contributors earn from the revenue pool.

## What is FitApp?

FitApp connects users with AI-powered workout plans, coach sharing, and progress tracking. Built on Firebase + Flutter with Stripe for billing and MCP tools for AI-assisted coaching workflows.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/nick-transition/fitapp.git
cd fitapp

# 2. Install Flutter dependencies
flutter pub get

# 3. Install Firebase Functions dependencies
cd functions && npm install && cd ..

# 4. Start Firebase emulators
firebase emulators:start

# 5. Run the app
flutter run -d chrome
```

## Architecture

```
fitapp/
├── lib/               # Flutter app (Dart)
│   ├── models/        # Data models
│   ├── screens/       # UI screens
│   ├── services/      # Firebase, Stripe, auth services
│   └── widgets/       # Reusable UI components
├── functions/         # Firebase Cloud Functions (TypeScript)
│   └── src/           # Stripe webhooks, MCP tools, auth
├── android/           # Android platform code
├── ios/               # iOS platform code
└── .github/           # CI/CD workflows, PR template, issue templates
```

**Stack:** Flutter · Firebase (Auth, Firestore, Hosting, Functions) · Stripe · GitHub Actions

## Contributing

Contributors earn from FitApp's revenue pool — 25% of subscription revenue is distributed monthly based on contribution points.

See [CONTRIBUTING.md](CONTRIBUTING.md) for full details on getting started, the contributor scoring model, AI usage standards, and code guidelines.

## Open Source Model

Learn how FitApp's revenue-sharing protocol works on the [Open Source page](https://fitapp.web.app/open-source).

## License

AGPL-3.0 — see [LICENSE](LICENSE).
