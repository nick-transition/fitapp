import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { defineSecret } from 'firebase-functions/params';

// Define the secret (it will be injected from Secret Manager)
export const FIREBASE_API_KEY = defineSecret('APP_FIREBASE_API_KEY');

const FIREBASE_CONFIG = {
  authDomain: 'fitapp-ns.firebaseapp.com',
  projectId: 'fitapp-ns',
};

const CODE_TTL_MS = 5 * 60 * 1000; // 5 minutes

function loginPage(clientId: string, redirectUri: string, state: string, scope: string): string {
  const apiKey = FIREBASE_API_KEY.value();
  const scopeList = (scope || 'profile:read').split(' ');
  const scopeDescriptions: Record<string, string> = {
    'profile:read': 'Read your basic profile information',
    'workout:read': 'View your workout plans, sessions, and calendar',
    'workout:write': 'Log new workout sessions and create plans',
    'claudeai': 'Connect to Claude.ai for AI-powered tracking',
  };

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Authorize FitApp</title>
  <style>
    body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f5f5f5; }
    .card { background: white; padding: 2.5rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); text-align: center; max-width: 420px; width: 100%; }
    .logo { font-size: 2.5rem; margin-bottom: 0.5rem; }
    h1 { font-size: 1.5rem; margin: 0 0 0.5rem; color: #1a1a1a; }
    .subtitle { color: #666; margin: 0 0 1.5rem; font-size: 0.95rem; }
    .permissions { text-align: left; background: #fcfcfc; border: 1px solid #eee; border-radius: 8px; padding: 1.25rem; margin-bottom: 1.5rem; }
    .permissions h2 { font-size: 0.85rem; text-transform: uppercase; color: #888; margin: 0 0 0.75rem; letter-spacing: 0.5px; }
    .perm-item { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 0.75rem; font-size: 0.9rem; color: #333; }
    .perm-item:last-child { margin-bottom: 0; }
    .perm-icon { color: #34A853; font-weight: bold; }
    .divider { border: none; border-top: 1px solid #eee; margin: 0 0 1.5rem; }
    #google-btn { display: inline-flex; align-items: center; justify-content: center; gap: 10px; padding: 12px 24px; border: 1px solid #dadce0; border-radius: 6px; background: white; color: #3c4043; cursor: pointer; font-size: 0.95rem; font-weight: 500; width: 100%; transition: background 0.2s; }
    #google-btn:hover { background: #f8f9fa; border-color: #d2d4d7; }
    .note { font-size: 0.8rem; color: #999; margin-top: 1.25rem; line-height: 1.4; }
    .error { color: #d32f2f; margin-top: 1rem; display: none; font-size: 0.9rem; }
    .loading { display: none; color: #666; margin-top: 1rem; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">💪</div>
    <h1>Authorize Claude</h1>
    <p class="subtitle">Claude.ai wants to access your FitApp account</p>

    <div class="permissions">
      <h2>This will allow Claude to:</h2>
      ${scopeList.map(s => `
        <div class="perm-item">
          <span class="perm-icon">✓</span>
          <span>${scopeDescriptions[s] || s}</span>
        </div>
      `).join('')}
    </div>

    <button id="google-btn" onclick="signIn()">
      <svg width="18" height="18" viewBox="0 0 48 48"><path fill="#4285F4" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#34A853" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#EA4335" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>
      Allow and Continue
    </button>
    <div class="loading" id="loading">Authorizing...</div>
    <div class="error" id="error"></div>
    <p class="note">You can revoke this access at any time in your FitApp settings. Your Google password is never shared with FitApp.</p>
  </div>

  <script src="https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.12.0/firebase-auth-compat.js"></script>
  <script>
    firebase.initializeApp({
      apiKey: ${JSON.stringify(apiKey)},
      authDomain: ${JSON.stringify(FIREBASE_CONFIG.authDomain)},
      projectId: ${JSON.stringify(FIREBASE_CONFIG.projectId)},
    });

    async function signIn() {
      const btn = document.getElementById('google-btn');
      const loading = document.getElementById('loading');
      const errorEl = document.getElementById('error');
      btn.style.display = 'none';
      loading.style.display = 'block';
      errorEl.style.display = 'none';

      try {
        const provider = new firebase.auth.GoogleAuthProvider();
        const result = await firebase.auth().signInWithPopup(provider);
        const idToken = await result.user.getIdToken();

        const resp = await fetch(window.location.origin + '/callback', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            idToken,
            clientId: ${JSON.stringify(clientId)},
            redirectUri: ${JSON.stringify(redirectUri)},
            state: ${JSON.stringify(state)},
            scope: ${JSON.stringify(scope)},
          }),
        });

        if (!resp.ok) {
          const err = await resp.json();
          throw new Error(err.error || 'Authorization failed');
        }

        const { redirectTo } = await resp.json();
        window.location.href = redirectTo;
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

export async function handleOAuthRequest(req: any, res: any) {
    const path = req.path.replace(/\/$/, '') || '/';

    // GET /authorize — validate client and redirect to login
    if (req.method === 'GET' && path.endsWith('/authorize')) {
      const { client_id, redirect_uri, state, response_type, scope } = req.query as Record<string, string>;

      if (response_type !== 'code') {
        res.status(400).json({ error: 'Unsupported response_type. Must be "code".' });
        return;
      }
      if (!client_id || !redirect_uri || !state) {
        res.status(400).json({ error: 'Missing required parameters: client_id, redirect_uri, state' });
        return;
      }

      const clientDoc = await admin.firestore().doc(`oauthClients/${client_id}`).get();
      if (!clientDoc.exists) {
        res.status(400).json({ error: 'Invalid client_id' });
        return;
      }

      const params = new URLSearchParams({ 
        client_id, 
        redirect_uri, 
        state,
        scope: scope || 'profile:read workout:read workout:write' // Default to full access
      });
      // Redirect to /login relative to the function base
      res.redirect(`./login?${params.toString()}`);
      return;
    }

    // GET /login — serve sign-in page
    if (req.method === 'GET' && path.endsWith('/login')) {
      const { client_id, redirect_uri, state, scope } = req.query as Record<string, string>;
      if (!client_id || !redirect_uri || !state) {
        res.status(400).json({ error: 'Missing required parameters' });
        return;
      }

      const html = loginPage(client_id, redirect_uri, state, scope || '');
      res.status(200).send(html);
      return;
    }

    // POST /callback — exchange Firebase ID token for auth code, return redirect URL
    if (req.method === 'POST' && path.endsWith('/callback')) {
      const { idToken, clientId, redirectUri, state, scope } = req.body;
      if (!idToken || !clientId || !redirectUri || !state) {
        res.status(400).json({ error: 'Missing required fields' });
        return;
      }

      // Validate client
      const clientDoc = await admin.firestore().doc(`oauthClients/${clientId}`).get();
      if (!clientDoc.exists) {
        res.status(400).json({ error: 'Invalid client_id' });
        return;
      }

      // Verify Firebase ID token
      let userId: string;
      try {
        const decoded = await admin.auth().verifyIdToken(idToken);
        userId = decoded.uid;
      } catch {
        res.status(401).json({ error: 'Invalid ID token' });
        return;
      }

      // Generate auth code and store it with scopes
      const code = crypto.randomBytes(32).toString('hex');
      await admin.firestore().doc(`oauthCodes/${code}`).set({
        userId,
        clientId,
        redirectUri,
        scope: scope || 'profile:read workout:read workout:write',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const redirectUrl = new URL(redirectUri);
      redirectUrl.searchParams.set('code', code);
      redirectUrl.searchParams.set('state', state);

      res.status(200).json({ redirectTo: redirectUrl.toString() });
      return;
    }

    // POST /token — exchange auth code for access token
    if (req.method === 'POST' && path.endsWith('/token')) {
      const { code, client_id, client_secret, grant_type, redirect_uri } = req.body;

      if (grant_type !== 'authorization_code') {
        res.status(400).json({ error: 'unsupported_grant_type' });
        return;
      }
      if (!code || !client_id || !client_secret) {
        res.status(400).json({ error: 'invalid_request', error_description: 'Missing required parameters' });
        return;
      }

      // Validate client credentials
      const clientDoc = await admin.firestore().doc(`oauthClients/${client_id}`).get();
      if (!clientDoc.exists || clientDoc.data()!.secret !== client_secret) {
        res.status(401).json({ error: 'invalid_client' });
        return;
      }

      // Look up auth code
      const codeDoc = await admin.firestore().doc(`oauthCodes/${code}`).get();
      if (!codeDoc.exists) {
        res.status(400).json({ error: 'invalid_grant', error_description: 'Invalid or expired code' });
        return;
      }

      const codeData = codeDoc.data()!;

      // Verify client and redirect_uri match
      if (codeData.clientId !== client_id) {
        res.status(400).json({ error: 'invalid_grant', error_description: 'Client mismatch' });
        return;
      }
      if (redirect_uri && codeData.redirectUri !== redirect_uri) {
        res.status(400).json({ error: 'invalid_grant', error_description: 'Redirect URI mismatch' });
        return;
      }

      // Check code expiry (5 minutes)
      const createdAt = codeData.createdAt?.toDate?.();
      if (createdAt && Date.now() - createdAt.getTime() > CODE_TTL_MS) {
        await admin.firestore().doc(`oauthCodes/${code}`).delete();
        res.status(400).json({ error: 'invalid_grant', error_description: 'Code expired' });
        return;
      }

      // Generate access token and store with scopes
      const accessToken = crypto.randomBytes(32).toString('hex');
      await admin.firestore().doc(`oauthTokens/${accessToken}`).set({
        userId: codeData.userId,
        clientId: client_id,
        scope: codeData.scope, // Inherit scope from authorization code
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Delete used code
      await admin.firestore().doc(`oauthCodes/${code}`).delete();

      res.status(200).json({
        access_token: accessToken,
        token_type: 'Bearer',
        scope: codeData.scope,
      });
      return;
    }

    res.status(404).json({ error: 'Not found' });
}
