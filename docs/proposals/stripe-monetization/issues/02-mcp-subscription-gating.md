# Issue: Gate MCP tool access behind subscription tier

## Description
Add middleware to the MCP server that checks the user's subscription tier before allowing tool execution. Free users get limited access, Pro users get full access.

## Acceptance Criteria
- [ ] Free tier: 5 MCP tool calls per day (tracked in Firestore)
- [ ] Pro tier: Unlimited MCP tool calls
- [ ] Coach tier: Unlimited + coach-specific tools
- [ ] Rate limit returns clear error message with upgrade CTA
- [ ] Usage counter resets daily

## Technical Notes
- Add subscription check in auth.ts middleware (before tool handler)
- Track daily usage in users/{uid}/usage/{date} document
- Return structured error that Claude can present as upgrade prompt

## Dependencies
- Issue #01 (Stripe Billing setup)

## Estimate: Small (1 day)
