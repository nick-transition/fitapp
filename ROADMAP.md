# FitApp Roadmap

Last updated: April 2026

## Now — Security & Stability

Harden the foundation before scaling users.

- [ ] **HTTP referrer restrictions on Firebase API keys** ([#30](https://github.com/nick-transition/fitapp/issues/30))
- [ ] **OAuth redirect_uri validation** ([#6](https://github.com/nick-transition/fitapp/issues/6))
- [ ] **Access token expiry** ([#7](https://github.com/nick-transition/fitapp/issues/7))
- [ ] **Timing-safe secret comparison** ([#8](https://github.com/nick-transition/fitapp/issues/8))
- [ ] **Strip MCP debug toolkit from production builds** ([#9](https://github.com/nick-transition/fitapp/issues/9))
- [x] Stripe test/prod separation with live webhook endpoint
- [x] Inline YouTube videos on athlete detail screen ([#2](https://github.com/nick-transition/fitapp/issues/2))
- [x] E2E test harness with Playwright + screenshot capture
- [x] CI/CD: build, e2e, deploy on merge

## Next — Coach Experience

Make the coach side a first-class product.

- [ ] **Coach view matches athlete view for plans and sessions** ([#3](https://github.com/nick-transition/fitapp/issues/3))
- [ ] Coach can create/edit workout programs for athletes
- [ ] Coach can assign programs to athletes
- [ ] Coach dashboard with athlete compliance metrics
- [ ] Push notifications for session completion

## Later — Monetization & Marketplace

Turn on revenue and open up the platform.

- [ ] **Gate MCP tool access behind subscription tier** ([#20](https://github.com/nick-transition/fitapp/issues/20))
- [ ] **Coach program marketplace with Stripe Connect** ([#21](https://github.com/nick-transition/fitapp/issues/21))
- [ ] **Design open-source revenue protocol** ([#22](https://github.com/nick-transition/fitapp/issues/22))
- [ ] Free tier limits (programs, sessions per month)
- [ ] Coach payout dashboard via Stripe Connect

## Future — Platform Growth

- [ ] Mobile app (iOS/Android) release via App Store and Play Store
- [ ] Exercise library with community-contributed videos
- [ ] Progress photos and body composition tracking
- [ ] Social features (share workouts, follow coaches)
- [ ] AI form check via video analysis
