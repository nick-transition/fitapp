import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import {
  ACCESS_TOKEN_EXPIRES_IN_SECONDS,
  ACCESS_TOKEN_PREFIX,
  ACCESS_TOKEN_TTL_MS,
  AUTH_CODE_PREFIX,
  AUTH_CODE_TTL_MS,
  CLIENT_ID_PREFIX,
  REFRESH_TOKEN_PREFIX,
  REFRESH_TOKEN_TTL_MS,
  SUPPORTED_SCOPES,
  createExpiry,
  generateSecret,
  isExpired,
  isRedirectUriAllowed,
  isValidRedirectUri,
  parseScopes,
  sha256Hex,
  unknownScopes,
  verifyPkceS256,
} from './oauthSecurity.js';

// Firebase web API key for the consent page's sign-in widget. Not a bearer
// credential (Firebase web keys are public identifiers), kept in Secret
// Manager only to keep it out of the repo.
export const FIREBASE_API_KEY = defineSecret('APP_FIREBASE_API_KEY');

const FIREBASE_CONFIG = {
  authDomain: 'fitapp-ns.firebaseapp.com',
  projectId: 'fitapp-ns',
};

const MAX_REDIRECT_URIS = 10;
const MAX_CLIENT_NAME_LENGTH = 100;

/**
 * Absolute base URL of this function, derived from the incoming request so
 * discovery metadata is correct on the run.app domain, the cloudfunctions.net
 * alias, and the local emulator alike. OAUTH_BASE_URL overrides for tests.
 */
export function requestBaseUrl(req: any): string {
  if (process.env.OAUTH_BASE_URL) {
    return process.env.OAUTH_BASE_URL;
  }
  const forwardedProto = (req.headers['x-forwarded-proto'] as string | undefined)?.split(',')[0];
  const proto = forwardedProto || req.protocol || 'https';
  const host = (req.headers['x-forwarded-host'] as string | undefined) || req.headers.host;
  const original: string = (req.originalUrl || req.url || '').split('?')[0];
  const path: string = req.path || '';
  const prefix = path && original.endsWith(path) ? original.slice(0, original.length - path.length) : '';
  return `${proto}://${host}${prefix}`;
}

export function protectedResourceMetadataUrl(req: any): string {
  return `${requestBaseUrl(req)}/.well-known/oauth-protected-resource`;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

interface ConsentPageParams {
  clientId: string;
  clientName: string;
  redirectUri: string;
  state: string;
  scopes: string[];
  codeChallenge: string;
}

function consentPage(params: ConsentPageParams): string {
  const apiKey = FIREBASE_API_KEY.value();
  const { clientId, clientName, redirectUri, state, scopes, codeChallenge } = params;

  const denyUrl = new URL(redirectUri);
  denyUrl.searchParams.set('error', 'access_denied');
  if (state) denyUrl.searchParams.set('state', state);

  const scopeRows = scopes
    .map(
      (s) => `
        <label class="perm-item">
          <input type="checkbox" class="scope-box" value="${escapeHtml(s)}" checked>
          <span class="perm-text">
            <strong>${escapeHtml(s)}</strong>
            <span>${escapeHtml(SUPPORTED_SCOPES[s])}</span>
          </span>
        </label>`
    )
    .join('');

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Authorize ${escapeHtml(clientName)} — FitApp</title>
  <style>
    body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f5f5f5; }
    .card { background: white; padding: 2.5rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); text-align: center; max-width: 440px; width: 100%; }
    .logo { font-size: 2.5rem; margin-bottom: 0.5rem; }
    h1 { font-size: 1.5rem; margin: 0 0 0.5rem; color: #1a1a1a; }
    .subtitle { color: #666; margin: 0 0 1.5rem; font-size: 0.95rem; }
    .permissions { text-align: left; background: #fcfcfc; border: 1px solid #eee; border-radius: 8px; padding: 1.25rem; margin-bottom: 1.5rem; }
    .permissions h2 { font-size: 0.85rem; text-transform: uppercase; color: #888; margin: 0 0 0.75rem; letter-spacing: 0.5px; }
    .perm-item { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 0.85rem; font-size: 0.9rem; color: #333; cursor: pointer; }
    .perm-item:last-child { margin-bottom: 0; }
    .perm-item input { margin-top: 3px; accent-color: #0d9488; }
    .perm-text { display: flex; flex-direction: column; gap: 2px; }
    .perm-text strong { font-family: ui-monospace, monospace; font-size: 0.8rem; color: #0f766e; }
    #allow-btn { display: inline-flex; align-items: center; justify-content: center; gap: 10px; padding: 12px 24px; border: none; border-radius: 6px; background: #0d9488; color: white; cursor: pointer; font-size: 0.95rem; font-weight: 500; width: 100%; }
    #allow-btn:hover { background: #0f766e; }
    #deny-btn { display: inline-block; margin-top: 0.75rem; padding: 10px; color: #666; font-size: 0.9rem; text-decoration: none; width: 100%; box-sizing: border-box; border-radius: 6px; }
    #deny-btn:hover { background: #f3f4f6; }
    .note { font-size: 0.8rem; color: #999; margin-top: 1.25rem; line-height: 1.4; }
    .error { color: #d32f2f; margin-top: 1rem; display: none; font-size: 0.9rem; }
    .loading { display: none; color: #666; margin-top: 1rem; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">💪</div>
    <h1>Authorize ${escapeHtml(clientName)}</h1>
    <p class="subtitle"><strong>${escapeHtml(clientName)}</strong> wants to access your FitApp account</p>

    <div class="permissions">
      <h2>It will be allowed to:</h2>
      ${scopeRows}
    </div>

    <button id="allow-btn" onclick="approve()">Sign in with Google &amp; Allow</button>
    <a id="deny-btn" href="${escapeHtml(denyUrl.toString())}">Deny</a>
    <div class="loading" id="loading">Authorizing…</div>
    <div class="error" id="error"></div>
    <p class="note">Only the permissions checked above are granted. You can review and revoke this access at any time under Connected Apps in FitApp settings.</p>
  </div>

  <script src="https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.12.0/firebase-auth-compat.js"></script>
  <script>
    firebase.initializeApp({
      apiKey: ${JSON.stringify(apiKey)},
      authDomain: ${JSON.stringify(FIREBASE_CONFIG.authDomain)},
      projectId: ${JSON.stringify(FIREBASE_CONFIG.projectId)},
    });

    async function approve() {
      const btn = document.getElementById('allow-btn');
      const loading = document.getElementById('loading');
      const errorEl = document.getElementById('error');
      errorEl.style.display = 'none';

      const scopes = Array.from(document.querySelectorAll('.scope-box:checked')).map(function (el) { return el.value; });
      if (scopes.length === 0) {
        errorEl.textContent = 'Select at least one permission, or press Deny.';
        errorEl.style.display = 'block';
        return;
      }

      btn.style.display = 'none';
      loading.style.display = 'block';

      try {
        const provider = new firebase.auth.GoogleAuthProvider();
        const result = await firebase.auth().signInWithPopup(provider);
        const idToken = await result.user.getIdToken();

        const resp = await fetch(new URL('callback', window.location.href), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            idToken: idToken,
            clientId: ${JSON.stringify(clientId)},
            redirectUri: ${JSON.stringify(redirectUri)},
            state: ${JSON.stringify(state)},
            scope: scopes.join(' '),
            codeChallenge: ${JSON.stringify(codeChallenge)},
            codeChallengeMethod: 'S256',
          }),
        });

        if (!resp.ok) {
          const err = await resp.json();
          throw new Error(err.error_description || err.error || 'Authorization failed');
        }

        const body = await resp.json();
        window.location.href = body.redirectTo;
      } catch (err) {
        btn.style.display = 'inline-flex';
        loading.style.display = 'none';
        errorEl.textContent = err.message;
        errorEl.style.display = 'block';
      }
    }
  </script>
</body>
</html>`;
}

function oauthError(res: any, status: number, error: string, description?: string) {
  res.status(status).json({ error, ...(description ? { error_description: description } : {}) });
}

function redirectWithError(res: any, redirectUri: string, error: string, state: string, description?: string) {
  const url = new URL(redirectUri);
  url.searchParams.set('error', error);
  if (description) url.searchParams.set('error_description', description);
  if (state) url.searchParams.set('state', state);
  res.redirect(url.toString());
}

async function getClient(clientId: unknown): Promise<FirebaseFirestore.DocumentSnapshot | null> {
  if (typeof clientId !== 'string' || !clientId) return null;
  const doc = await admin.firestore().doc(`oauthClients/${clientId}`).get();
  return doc.exists ? doc : null;
}

interface IssuedTokens {
  access_token: string;
  refresh_token: string;
  token_type: 'Bearer';
  expires_in: number;
  scope: string;
}

/**
 * Issues an access + refresh token pair for a grant. Only SHA-256 digests of
 * the tokens are persisted; the plaintext exists solely in the response.
 */
async function issueTokens(userId: string, clientId: string, scope: string, grantId: string): Promise<IssuedTokens> {
  const db = admin.firestore();
  const accessToken = generateSecret(ACCESS_TOKEN_PREFIX);
  const refreshToken = generateSecret(REFRESH_TOKEN_PREFIX);
  const now = FieldValue.serverTimestamp();

  const batch = db.batch();
  batch.set(db.doc(`oauthTokens/${sha256Hex(accessToken)}`), {
    userId,
    clientId,
    grantId,
    scope,
    createdAt: now,
    expiresAt: createExpiry(ACCESS_TOKEN_TTL_MS),
  });
  batch.set(db.doc(`oauthRefreshTokens/${sha256Hex(refreshToken)}`), {
    userId,
    clientId,
    grantId,
    scope,
    createdAt: now,
    expiresAt: createExpiry(REFRESH_TOKEN_TTL_MS),
  });
  await batch.commit();

  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    token_type: 'Bearer',
    expires_in: ACCESS_TOKEN_EXPIRES_IN_SECONDS,
    scope,
  };
}

async function deleteTokensForGrant(grantId: string): Promise<void> {
  const db = admin.firestore();
  for (const collection of ['oauthTokens', 'oauthRefreshTokens']) {
    const snapshot = await db.collection(collection).where('grantId', '==', grantId).get();
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

export async function handleOAuthRequest(req: any, res: any) {
  const path = req.path.replace(/\/$/, '') || '/';
  const base = requestBaseUrl(req);

  // --- Discovery metadata (RFC 8414 / RFC 9728) ---
  // Lets MCP clients find the authorization server, register, and run the
  // code + PKCE flow with zero manual configuration.
  if (req.method === 'GET' && path.includes('/.well-known/oauth-protected-resource')) {
    res.status(200).json({
      resource: base,
      authorization_servers: [base],
      scopes_supported: Object.keys(SUPPORTED_SCOPES),
      bearer_methods_supported: ['header'],
    });
    return;
  }

  if (req.method === 'GET' && path.includes('/.well-known/oauth-authorization-server')) {
    res.status(200).json({
      issuer: base,
      authorization_endpoint: `${base}/authorize`,
      token_endpoint: `${base}/token`,
      registration_endpoint: `${base}/register`,
      revocation_endpoint: `${base}/revoke`,
      scopes_supported: Object.keys(SUPPORTED_SCOPES),
      response_types_supported: ['code'],
      grant_types_supported: ['authorization_code', 'refresh_token'],
      code_challenge_methods_supported: ['S256'],
      token_endpoint_auth_methods_supported: ['none'],
    });
    return;
  }

  // --- Dynamic client registration (RFC 7591) ---
  // Public clients only: no secret is ever issued, PKCE is what binds the
  // code to the client that requested it.
  if (req.method === 'POST' && path.endsWith('/register')) {
    const body = req.body ?? {};
    const redirectUris: unknown = body.redirect_uris;

    if (!Array.isArray(redirectUris) || redirectUris.length === 0 || redirectUris.length > MAX_REDIRECT_URIS) {
      oauthError(res, 400, 'invalid_redirect_uri', 'redirect_uris must be a non-empty array');
      return;
    }
    if (!redirectUris.every((uri) => typeof uri === 'string' && isValidRedirectUri(uri))) {
      oauthError(res, 400, 'invalid_redirect_uri', 'redirect_uris must be exact https URLs (or localhost) without fragments');
      return;
    }

    const clientName =
      typeof body.client_name === 'string' && body.client_name.trim()
        ? body.client_name.trim().slice(0, MAX_CLIENT_NAME_LENGTH)
        : 'Unnamed application';

    const clientId = generateSecret(CLIENT_ID_PREFIX);
    await admin.firestore().doc(`oauthClients/${clientId}`).set({
      name: clientName,
      redirectUris,
      tokenEndpointAuthMethod: 'none',
      createdAt: FieldValue.serverTimestamp(),
    });

    res.status(201).json({
      client_id: clientId,
      client_name: clientName,
      redirect_uris: redirectUris,
      token_endpoint_auth_method: 'none',
      grant_types: ['authorization_code', 'refresh_token'],
      response_types: ['code'],
    });
    return;
  }

  // --- Authorization endpoint: renders the consent page ---
  if (req.method === 'GET' && path.endsWith('/authorize')) {
    const {
      client_id,
      redirect_uri,
      state = '',
      response_type,
      scope,
      code_challenge,
      code_challenge_method,
    } = req.query as Record<string, string>;

    // Client and redirect URI problems must never redirect (open-redirect risk).
    const clientDoc = await getClient(client_id);
    if (!clientDoc) {
      oauthError(res, 400, 'invalid_client', 'Unknown client_id');
      return;
    }
    if (!redirect_uri || !isRedirectUriAllowed(clientDoc.data()!, redirect_uri)) {
      oauthError(res, 400, 'invalid_request', 'redirect_uri is not registered for this client');
      return;
    }

    if (response_type !== 'code') {
      redirectWithError(res, redirect_uri, 'unsupported_response_type', state);
      return;
    }
    if (!code_challenge || code_challenge_method !== 'S256') {
      redirectWithError(res, redirect_uri, 'invalid_request', state, 'PKCE with S256 code_challenge is required');
      return;
    }

    // No scope requested → offer every supported scope on the consent page;
    // the user decides what is actually granted.
    const requestedScopes = parseScopes(scope);
    const invalid = unknownScopes(requestedScopes);
    if (invalid.length > 0) {
      redirectWithError(res, redirect_uri, 'invalid_scope', state, `Unknown scope(s): ${invalid.join(' ')}`);
      return;
    }
    const scopes = requestedScopes.length > 0 ? requestedScopes : Object.keys(SUPPORTED_SCOPES);

    const clientName = (clientDoc.data()!.name as string) || 'Unnamed application';
    res.status(200).send(
      consentPage({
        clientId: client_id,
        clientName,
        redirectUri: redirect_uri,
        state,
        scopes,
        codeChallenge: code_challenge,
      })
    );
    return;
  }

  // --- Consent approval: sign-in result → single-use authorization code ---
  if (req.method === 'POST' && path.endsWith('/callback')) {
    const { idToken, clientId, redirectUri, state = '', scope, codeChallenge, codeChallengeMethod } = req.body ?? {};

    if (!idToken || !clientId || !redirectUri || !codeChallenge) {
      oauthError(res, 400, 'invalid_request', 'Missing required fields');
      return;
    }
    if (codeChallengeMethod !== 'S256') {
      oauthError(res, 400, 'invalid_request', 'code_challenge_method must be S256');
      return;
    }

    const clientDoc = await getClient(clientId);
    if (!clientDoc) {
      oauthError(res, 400, 'invalid_client', 'Unknown client_id');
      return;
    }
    if (!isRedirectUriAllowed(clientDoc.data()!, redirectUri)) {
      oauthError(res, 400, 'invalid_request', 'redirect_uri is not registered for this client');
      return;
    }

    const grantedScopes = parseScopes(scope);
    if (grantedScopes.length === 0 || unknownScopes(grantedScopes).length > 0) {
      oauthError(res, 400, 'invalid_scope', 'Granted scopes must be a non-empty subset of supported scopes');
      return;
    }

    let userId: string;
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      userId = decoded.uid;
    } catch {
      oauthError(res, 401, 'invalid_request', 'Invalid ID token');
      return;
    }

    const code = generateSecret(AUTH_CODE_PREFIX);
    await admin.firestore().doc(`oauthCodes/${sha256Hex(code)}`).set({
      userId,
      clientId,
      redirectUri,
      scope: grantedScopes.join(' '),
      codeChallenge,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: createExpiry(AUTH_CODE_TTL_MS),
    });

    const redirectUrl = new URL(redirectUri);
    redirectUrl.searchParams.set('code', code);
    if (state) redirectUrl.searchParams.set('state', state);

    res.status(200).json({ redirectTo: redirectUrl.toString() });
    return;
  }

  // --- Token endpoint (PKCE only, no client secrets) ---
  if (req.method === 'POST' && path.endsWith('/token')) {
    const body = req.body ?? {};
    const grantType = body.grant_type;
    const db = admin.firestore();

    if (grantType === 'authorization_code') {
      const { code, client_id, redirect_uri, code_verifier } = body;
      if (!code || !client_id || !code_verifier || !redirect_uri) {
        oauthError(res, 400, 'invalid_request', 'code, client_id, redirect_uri and code_verifier are required');
        return;
      }

      const codeRef = db.doc(`oauthCodes/${sha256Hex(String(code))}`);
      const codeDoc = await codeRef.get();
      if (!codeDoc.exists) {
        oauthError(res, 400, 'invalid_grant', 'Invalid or expired code');
        return;
      }
      // Single use: burn the code no matter how the rest of the exchange goes.
      await codeRef.delete();

      const codeData = codeDoc.data()!;
      if (isExpired(codeData)) {
        oauthError(res, 400, 'invalid_grant', 'Code expired');
        return;
      }
      if (codeData.clientId !== client_id) {
        oauthError(res, 400, 'invalid_grant', 'Client mismatch');
        return;
      }
      if (codeData.redirectUri !== redirect_uri) {
        oauthError(res, 400, 'invalid_grant', 'Redirect URI mismatch');
        return;
      }
      if (!verifyPkceS256(String(code_verifier), codeData.codeChallenge)) {
        oauthError(res, 400, 'invalid_grant', 'PKCE verification failed');
        return;
      }

      const clientDoc = await getClient(client_id);
      const clientName = clientDoc ? (clientDoc.data()!.name as string) || 'Unnamed application' : 'Unnamed application';

      const grantId = `${codeData.userId}__${client_id}`;
      await db.doc(`oauthGrants/${grantId}`).set(
        {
          userId: codeData.userId,
          clientId: client_id,
          clientName,
          scope: codeData.scope,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      const tokens = await issueTokens(codeData.userId, client_id, codeData.scope, grantId);
      res.status(200).json(tokens);
      return;
    }

    if (grantType === 'refresh_token') {
      const { refresh_token, client_id } = body;
      if (!refresh_token || !client_id) {
        oauthError(res, 400, 'invalid_request', 'refresh_token and client_id are required');
        return;
      }

      const refreshRef = db.doc(`oauthRefreshTokens/${sha256Hex(String(refresh_token))}`);
      const refreshDoc = await refreshRef.get();
      if (!refreshDoc.exists) {
        oauthError(res, 400, 'invalid_grant', 'Invalid refresh token');
        return;
      }
      // Rotation: each refresh token works exactly once.
      await refreshRef.delete();

      const data = refreshDoc.data()!;
      if (isExpired(data) || data.clientId !== client_id) {
        oauthError(res, 400, 'invalid_grant', 'Invalid refresh token');
        return;
      }

      // The grant is the source of truth for revocation.
      const grantDoc = await db.doc(`oauthGrants/${data.grantId}`).get();
      if (!grantDoc.exists) {
        oauthError(res, 400, 'invalid_grant', 'Access has been revoked');
        return;
      }

      const tokens = await issueTokens(data.userId, data.clientId, data.scope, data.grantId);
      res.status(200).json(tokens);
      return;
    }

    oauthError(res, 400, 'unsupported_grant_type', 'Use authorization_code or refresh_token');
    return;
  }

  // --- Token revocation (RFC 7009) ---
  // (checked after /grants/revoke below would also match endsWith('/revoke'))
  if (req.method === 'POST' && path.endsWith('/revoke') && !path.endsWith('/grants/revoke')) {
    const token = req.body?.token;
    if (typeof token === 'string' && token) {
      const hash = sha256Hex(token);
      await admin.firestore().doc(`oauthTokens/${hash}`).delete();
      await admin.firestore().doc(`oauthRefreshTokens/${hash}`).delete();
    }
    // Per RFC 7009 the endpoint answers 200 whether or not the token existed.
    res.status(200).json({});
    return;
  }

  // --- Grant revocation from the FitApp UI (Firebase ID token auth) ---
  if (req.method === 'POST' && path.endsWith('/grants/revoke')) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      oauthError(res, 401, 'invalid_request', 'Missing Authorization header');
      return;
    }

    let userId: string;
    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.slice(7));
      userId = decoded.uid;
    } catch {
      oauthError(res, 401, 'invalid_request', 'Invalid ID token');
      return;
    }

    const grantId = req.body?.grantId;
    if (typeof grantId !== 'string' || !grantId) {
      oauthError(res, 400, 'invalid_request', 'grantId is required');
      return;
    }

    const grantRef = admin.firestore().doc(`oauthGrants/${grantId}`);
    const grantDoc = await grantRef.get();
    if (!grantDoc.exists || grantDoc.data()!.userId !== userId) {
      oauthError(res, 404, 'not_found', 'No such grant');
      return;
    }

    await deleteTokensForGrant(grantId);
    await grantRef.delete();
    res.status(200).json({ revoked: true });
    return;
  }

  res.status(404).json({ error: 'not_found' });
}
