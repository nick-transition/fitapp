# Changelog

All notable changes to FitApp will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Open Source Model page with revenue protocol explanation and email capture
- Stripe Billing integration (checkout, webhooks, customer portal)
- MCP tools for workout logging, session queries, and exercise history
- Coach sharing feature with invite codes
- CI/CD pipeline (GitHub Actions: PR checks + deploy on merge)

### Changed
- MCP prompts improved for better plan creation (schedule, notes, weight strings)
- YouTube video tiles collapse behavior

### Fixed
- Google Analytics tag restored after accidental removal
- Dart SDK version constraint for CI compatibility
- Google sign-in web redirect flow

### Security
- OAuth redirect_uri validation (issue #6 - pending)
- Access token expiry (issue #7 - pending)
- Timing-safe secret comparison (issue #8 - pending)
