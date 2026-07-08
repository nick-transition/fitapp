# OAuth Connector for MCP Clients (Claude.ai / Claude Desktop)

## Overview

FitApp acts as an OAuth 2.1 authorization server so MCP clients (Claude.ai
custom connectors, Claude Desktop, or any spec-compliant client) can access
user data on the user's behalf. There is **nothing to copy or configure**
beyond the MCP server URL: clients discover the endpoints, register
themselves, and run the authorization-code + PKCE flow. No client secrets
exist anywhere in the system, and no credential is ever stored verbatim.

## Architecture

```
MCP Client (Claude)                  FitApp (Firebase Functions)
   │                                      │
   │ 1. POST /mcp (no token)              │
   │ ←── 401 + WWW-Authenticate: ─────────┤  points at resource metadata
   │      resource_metadata=…             │
   │ 2. GET /.well-known/… ──────────────→│  discovery (RFC 8414 / 9728)
   │ 3. POST /register ──────────────────→│  dynamic client registration
   │ ←── client_id (public, NO secret) ───┤  (RFC 7591)
   │ 4. GET /authorize?code_challenge=… ─→│  PKCE S256 required
   │ ←── consent page ────────────────────┤  privileges listed as checkboxes;
   │      user signs in with Google,      │  user can untick any, or Deny
   │      picks the permissions to grant  │
   │ ←── redirect with one-time code ─────┤  code stored as SHA-256 digest
   │ 5. POST /token (code + verifier) ───→│  PKCE verified, code burned
   │ ←── access (1 h) + refresh token ────┤  only digests stored
   │ 6. POST /mcp with Bearer token ─────→│  scopes enforced per tool
   │ 7. POST /token (refresh_token) ─────→│  rotation: each refresh works once
```

## Scopes

| Scope | Grants |
|-------|--------|
| `profile:read` | Read basic profile information |
| `workout:read` | View workout plans, sessions, and history |
| `workout:write` | Create workout plans and log sessions |

- Requesting no scope offers **all** supported scopes on the consent page;
  the user decides what is actually granted.
- Unknown scopes are rejected (`invalid_scope`), never silently granted.
- Tokens carry exactly the scopes the user left checked; every MCP tool
  checks its required scope (`functions/src/tools/index.ts`).

## Endpoints (all under the `mcp` Cloud Function)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/.well-known/oauth-protected-resource` | Resource metadata → points at the authorization server |
| GET | `/.well-known/oauth-authorization-server` | AS metadata (endpoints, PKCE S256, auth method `none`) |
| POST | `/register` | Dynamic client registration; public clients only, no secret issued |
| GET | `/authorize` | Validates client/redirect/PKCE/scopes, serves the consent page |
| POST | `/callback` | Consent approval: Firebase ID token + chosen scopes → one-time code |
| POST | `/token` | `authorization_code` (PKCE) and `refresh_token` (rotating) grants |
| POST | `/revoke` | RFC 7009 token revocation |
| POST | `/grants/revoke` | App-only (Firebase ID token): revoke a grant and delete all its tokens |

## Firestore Collections

| Collection | Keyed by | Contents | Lifetime |
|------------|----------|----------|----------|
| `oauthClients/{clientId}` | client id | name, redirect URIs, auth method `none` — **no secret** | permanent |
| `oauthCodes/{sha256(code)}` | digest | user, client, scopes, PKCE challenge | 5 min, single use |
| `oauthTokens/{sha256(token)}` | digest | user, client, grant, scopes | 1 hour |
| `oauthRefreshTokens/{sha256(token)}` | digest | user, client, grant, scopes | 60 days, single use (rotation) |
| `oauthGrants/{userId}__{clientId}` | grant id | client name, granted scopes — what the Connected Apps UI shows | until revoked |

Because only SHA-256 digests are stored, a read of the database (backup,
dump, console access) yields no usable bearer credential. All collections
are closed to client SDKs except `oauthGrants`, which the owning user can
read (it contains no secrets).

## Auth Resolution (`functions/src/auth.ts`)

`resolveUser()` accepts exactly two credentials:

1. **OAuth access token** (`fit_at_…`) — looked up by digest; scopes are
   exactly what the user approved.
2. **Firebase ID token** — the user's own app session; full access.

Static API keys and the `claudeai` scope-escalation shortcut are gone.
Unauthenticated MCP requests get `401` with a `WWW-Authenticate` header
pointing at the resource metadata, which is what lets MCP clients start the
flow automatically.

## Flutter App

`lib/screens/connected_apps_screen.dart` (replaces `api_token_screen.dart`):

- Shows the MCP server URL (the only thing a user ever copies).
- Lists authorized apps from `oauthGrants` with their exact permissions.
- Revoke button calls `POST /grants/revoke`, which deletes the grant and
  every access/refresh token belonging to it.

## Setup

1. **Claude.ai:** Settings → Connectors → Add custom connector → paste the
   MCP URL. Leave client ID/secret blank — discovery + dynamic registration
   handle everything. Sign in with Google on the consent page and choose the
   permissions to grant.
2. There is no step 2.

## Testing

`functions/test-oauth-flow.mjs` exercises the whole flow against the local
emulators (discovery, registration, consent page, PKCE enforcement, scoped
issuance, hashed storage, MCP tool scope checks, refresh rotation, grant
revocation):

```bash
cd functions && npm run build && cd .. && \
OAUTH_BASE_URL=http://localhost:5001/fitapp-ns/us-central1/mcp \
npx firebase emulators:exec --only functions,firestore,auth \
  "node functions/test-oauth-flow.mjs"
```

Requires `functions/.secret.local` with `APP_FIREBASE_API_KEY=<any value>`
for the emulator.

## Migration Notes

- Existing static API keys (`apiKeys` collection) and legacy plaintext
  `oauthTokens` no longer authenticate; users reconnect via the OAuth flow.
- Legacy `oauthClients` docs with a `secret` field still work as clients
  (the secret is simply ignored), but connectors should be re-added without
  credentials to use discovery.
- The `apiKeys`, legacy `oauthCodes`/`oauthTokens` docs can be deleted from
  Firestore once the new flow is deployed.
