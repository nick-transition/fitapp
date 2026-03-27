# OAuth Connector for Claude.ai

## Overview

FitApp acts as an OAuth 2.0 provider so Claude.ai can access user data through a Custom MCP Connector. Users sign in with their Google account, and FitApp issues tokens that let Claude act on their behalf.

## Architecture

```
Claude.ai                        FitApp (Firebase)
   │                                  │
   │  1. User clicks "Connect"        │
   ├─────────────────────────────────→ GET /oauth/authorize
   │                                  │ validates client_id
   │  2. Redirect to login            │
   │ ←────────────────────────────────┤ GET /oauth/login (HTML page)
   │                                  │
   │  3. User signs in with Google    │
   │  ─────────────────────────────→  POST /oauth/callback
   │                                  │ verifies Firebase ID token
   │                                  │ generates auth code
   │  4. Redirect back with code      │
   │ ←────────────────────────────────┤
   │                                  │
   │  5. Exchange code for token      │
   ├─────────────────────────────────→ POST /oauth/token
   │                                  │ validates client secret
   │  6. Access token returned        │ generates long-lived token
   │ ←────────────────────────────────┤
   │                                  │
   │  7. MCP requests with token      │
   ├─────────────────────────────────→ POST /mcp
   │                                  │ resolveUser() checks oauthTokens
```

## Files

| File | What changed |
|------|-------------|
| `functions/src/oauth.ts` | New. Cloud Function with path-based routing for `/authorize`, `/login`, `/callback`, `/token` |
| `functions/src/auth.ts` | Updated `resolveUser()` to check `oauthTokens` collection as a third auth method |
| `functions/src/index.ts` | Exports the `oauth` Cloud Function, fixed error message matching |
| `lib/screens/api_token_screen.dart` | Redesigned UI with step-by-step Claude Desktop setup instructions |

## Firestore Collections

| Collection | Purpose | Lifetime |
|------------|---------|----------|
| `oauthClients/{clientId}` | Registered OAuth clients. Fields: `secret`, `name` | Permanent |
| `oauthCodes/{code}` | Ephemeral authorization codes. Fields: `userId`, `clientId`, `redirectUri`, `createdAt` | 5 minutes |
| `oauthTokens/{token}` | Long-lived access tokens. Fields: `userId`, `clientId`, `createdAt` | Until revoked |

## Auth Resolution Order

`resolveUser()` tries three methods in order:

1. **Firebase ID token** — from the Flutter app or any Firebase Auth flow
2. **API key** — static keys in `apiKeys/{token}` for simple MCP clients
3. **OAuth token** — long-lived tokens in `oauthTokens/{token}` from the OAuth flow

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/oauth/authorize` | Validates `client_id`, `redirect_uri`, `state`, `response_type=code`. Redirects to `/login` |
| GET | `/oauth/login` | Serves HTML sign-in page with Google auth button |
| POST | `/oauth/callback` | Receives Firebase ID token from login page, creates auth code, returns redirect URL |
| POST | `/oauth/token` | Exchanges auth code + client credentials for a long-lived access token |

## URLs (Production)

- **Authorize:** `https://us-central1-fitapp-ns.cloudfunctions.net/oauth/authorize`
- **Token:** `https://us-central1-fitapp-ns.cloudfunctions.net/oauth/token`
- **MCP Server:** `https://us-central1-fitapp-ns.cloudfunctions.net/mcp`

## Setup Steps

1. **Create OAuth client in Firestore:** Add a doc to `oauthClients` with an ID (the client_id) and fields `{ secret: "<generated>", name: "Claude.ai" }`
2. **Configure in Claude.ai:** Add as a Custom Connector with the authorize/token URLs and client credentials
3. **Test:** Connect in Claude.ai → sign in with Google → ask "list my workout plans"

## Flutter App Changes

The "AI Client Setup" screen (`api_token_screen.dart`) was redesigned with:

- Step-by-step numbered instructions for Claude Desktop
- Real MCP URL pre-filled in the config block
- Token auto-inserted into the copyable config
- Example prompts users can try
- Expiry reminder (tokens last 1 hour)

This screen is for **Claude Desktop** (static token). The OAuth flow is for **Claude.ai** (automatic token via connector).
