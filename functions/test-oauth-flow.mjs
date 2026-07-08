/**
 * End-to-end exercise of the OAuth 2.1 + MCP flow against the local emulators.
 *
 * Run with:
 *   cd functions && npm run build && \
 *   OAUTH_BASE_URL=http://localhost:5001/fitapp-ns/us-central1/mcp \
 *   firebase emulators:exec --only functions,firestore,auth "node test-oauth-flow.mjs"
 *
 * Covers: discovery metadata, dynamic client registration, consent page,
 * PKCE enforcement, scoped token issuance, hashed storage, MCP tool calls
 * with scope enforcement, refresh rotation, and grant revocation.
 */
import crypto from 'crypto';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';

const BASE = process.env.OAUTH_BASE_URL || 'http://localhost:5001/fitapp-ns/us-central1/mcp';
const AUTH_EMULATOR = 'http://localhost:9099';
const FIRESTORE_EMULATOR = 'http://localhost:8081';
const REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback';

let failures = 0;
function check(name, cond, extra = '') {
  console.log(`${cond ? '  ✅' : '  ❌'} ${name}${cond ? '' : `  ${extra}`}`);
  if (!cond) failures += 1;
}

async function postJson(url, body, headers = {}) {
  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  return { status: resp.status, body: await resp.json().catch(() => ({})) };
}

async function postForm(url, params) {
  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(params).toString(),
  });
  return { status: resp.status, body: await resp.json().catch(() => ({})) };
}

function makePkce() {
  const verifier = crypto.randomBytes(32).toString('base64url');
  const challenge = crypto.createHash('sha256').update(verifier).digest('base64url');
  return { verifier, challenge };
}

async function mintCode(idToken, clientId, scope, challenge) {
  const { status, body } = await postJson(`${BASE}/callback`, {
    idToken,
    clientId,
    redirectUri: REDIRECT_URI,
    state: 'st4te',
    scope,
    codeChallenge: challenge,
    codeChallengeMethod: 'S256',
  });
  if (status !== 200) throw new Error(`callback failed: ${JSON.stringify(body)}`);
  return new URL(body.redirectTo).searchParams.get('code');
}

async function mcpClient(accessToken) {
  const client = new Client({ name: 'oauth-e2e', version: '1.0.0' });
  const transport = new StreamableHTTPClientTransport(new URL(BASE), {
    requestInit: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
  await client.connect(transport);
  return client;
}

async function main() {
  console.log('\n— Discovery —');
  const asMeta = await (await fetch(`${BASE}/.well-known/oauth-authorization-server`)).json();
  check('authorization server metadata served', asMeta.issuer === BASE, JSON.stringify(asMeta));
  check('advertises PKCE S256', (asMeta.code_challenge_methods_supported || []).includes('S256'));
  check('public clients only (auth method "none")',
    JSON.stringify(asMeta.token_endpoint_auth_methods_supported) === '["none"]');
  check('advertises registration endpoint', asMeta.registration_endpoint === `${BASE}/register`);

  const prMeta = await (await fetch(`${BASE}/.well-known/oauth-protected-resource`)).json();
  check('protected resource metadata points at AS', (prMeta.authorization_servers || [])[0] === BASE);

  console.log('\n— Unauthenticated MCP request —');
  const unauth = await fetch(BASE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'ping' }),
  });
  check('returns 401', unauth.status === 401, `got ${unauth.status}`);
  check('WWW-Authenticate advertises resource metadata',
    (unauth.headers.get('www-authenticate') || '').includes('/.well-known/oauth-protected-resource'),
    unauth.headers.get('www-authenticate') || '(missing)');

  console.log('\n— Dynamic client registration —');
  const reg = await postJson(`${BASE}/register`, {
    client_name: 'Claude',
    redirect_uris: [REDIRECT_URI],
    token_endpoint_auth_method: 'none',
  });
  check('client registered', reg.status === 201 && !!reg.body.client_id, JSON.stringify(reg.body));
  check('no client_secret issued', !('client_secret' in reg.body));
  const clientId = reg.body.client_id;

  const regBad = await postJson(`${BASE}/register`, { redirect_uris: ['javascript:alert(1)'] });
  check('rejects non-https redirect_uris', regBad.status === 400);

  console.log('\n— Authorization / consent page —');
  const { verifier, challenge } = makePkce();
  const authorizeParams = new URLSearchParams({
    client_id: clientId,
    redirect_uri: REDIRECT_URI,
    response_type: 'code',
    state: 'st4te',
    scope: 'profile:read workout:read workout:write',
    code_challenge: challenge,
    code_challenge_method: 'S256',
  });
  const consentResp = await fetch(`${BASE}/authorize?${authorizeParams}`);
  const consentHtml = await consentResp.text();
  check('consent page served', consentResp.status === 200);
  check('lists privilege descriptions', consentHtml.includes('View your workout plans, sessions, and history'));
  check('privileges are individually toggleable', (consentHtml.match(/class="scope-box"/g) || []).length === 3);
  check('shows registered client name', consentHtml.includes('Authorize Claude'));
  check('has a deny option', consentHtml.includes('error=access_denied'));

  const noPkce = await fetch(
    `${BASE}/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(REDIRECT_URI)}&response_type=code&state=x`,
    { redirect: 'manual' }
  );
  check('PKCE is mandatory', noPkce.status >= 300 && noPkce.status < 400 &&
    (noPkce.headers.get('location') || '').includes('error=invalid_request'));

  const badScope = await fetch(
    `${BASE}/authorize?${new URLSearchParams({
      client_id: clientId, redirect_uri: REDIRECT_URI, response_type: 'code', state: 'x',
      scope: 'admin:everything', code_challenge: challenge, code_challenge_method: 'S256',
    })}`,
    { redirect: 'manual' }
  );
  check('unknown scopes rejected', (badScope.headers.get('location') || '').includes('error=invalid_scope'));

  console.log('\n— Sign-in and consent (user grants a SUBSET: no workout:write) —');
  const signUp = await postJson(
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    { email: 'oauth-e2e@example.com', password: 'password123', returnSecureToken: true }
  );
  const idToken = signUp.body.idToken;
  const userId = signUp.body.localId;
  check('emulator user created', !!idToken);

  const code = await mintCode(idToken, clientId, 'profile:read workout:read', challenge);
  check('authorization code issued', !!code && code.startsWith('fit_code_'));

  console.log('\n— Token exchange (form-encoded, PKCE, no secret) —');
  const tok = await postForm(`${BASE}/token`, {
    grant_type: 'authorization_code',
    code,
    client_id: clientId,
    redirect_uri: REDIRECT_URI,
    code_verifier: verifier,
  });
  check('access token issued', tok.status === 200 && (tok.body.access_token || '').startsWith('fit_at_'), JSON.stringify(tok.body));
  check('refresh token issued', (tok.body.refresh_token || '').startsWith('fit_rt_'));
  check('token carries only user-granted scopes', tok.body.scope === 'profile:read workout:read');
  check('access token is short-lived (1h)', tok.body.expires_in === 3600);

  const replay = await postForm(`${BASE}/token`, {
    grant_type: 'authorization_code', code, client_id: clientId,
    redirect_uri: REDIRECT_URI, code_verifier: verifier,
  });
  check('authorization code is single-use', replay.status === 400 && replay.body.error === 'invalid_grant');

  const pkce2 = makePkce();
  const code2 = await mintCode(idToken, clientId, 'workout:read', pkce2.challenge);
  const badVerifier = await postForm(`${BASE}/token`, {
    grant_type: 'authorization_code', code: code2, client_id: clientId,
    redirect_uri: REDIRECT_URI, code_verifier: crypto.randomBytes(32).toString('base64url'),
  });
  check('wrong PKCE verifier rejected', badVerifier.status === 400 && badVerifier.body.error === 'invalid_grant');

  console.log('\n— Hashed at-rest storage —');
  const emulatorAuth = { Authorization: 'Bearer owner' };
  const rawTokenDoc = await fetch(
    `${FIRESTORE_EMULATOR}/v1/projects/fitapp-ns/databases/(default)/documents/oauthTokens/${tok.body.access_token}`,
    { headers: emulatorAuth }
  );
  check('access token is NOT stored verbatim', rawTokenDoc.status === 404, `got ${rawTokenDoc.status}`);
  const hash = crypto.createHash('sha256').update(tok.body.access_token).digest('hex');
  const hashedTokenDoc = await fetch(
    `${FIRESTORE_EMULATOR}/v1/projects/fitapp-ns/databases/(default)/documents/oauthTokens/${hash}`,
    { headers: emulatorAuth }
  );
  check('only its SHA-256 digest is stored', hashedTokenDoc.status === 200, `got ${hashedTokenDoc.status}`);

  console.log('\n— MCP calls with scoped token —');
  const client = await mcpClient(tok.body.access_token);
  const tools = await client.listTools();
  check('MCP client connects, tools listed', tools.tools.length > 0);

  const readCall = await client.callTool({ name: 'list_sessions', arguments: {} });
  check('workout:read tool allowed', !readCall.isError, JSON.stringify(readCall.content));

  const writeCall = await client.callTool({
    name: 'log_quick_exercise',
    arguments: { exerciseName: 'Bench Press', sets: [{ reps: 5, weight: 100 }] },
  });
  const writeText = writeCall.content?.[0]?.text || '';
  check('workout:write tool denied (scope not granted)',
    writeCall.isError && writeText.includes('Missing required scope: workout:write'), writeText);
  await client.close();

  console.log('\n— Refresh token rotation —');
  const refreshed = await postForm(`${BASE}/token`, {
    grant_type: 'refresh_token', refresh_token: tok.body.refresh_token, client_id: clientId,
  });
  check('refresh grant issues new pair', refreshed.status === 200 && !!refreshed.body.access_token);
  check('scopes preserved across refresh', refreshed.body.scope === 'profile:read workout:read');

  const refreshReplay = await postForm(`${BASE}/token`, {
    grant_type: 'refresh_token', refresh_token: tok.body.refresh_token, client_id: clientId,
  });
  check('old refresh token unusable after rotation', refreshReplay.status === 400);

  console.log('\n— Grant management + revocation —');
  const grantDoc = await fetch(
    `${FIRESTORE_EMULATOR}/v1/projects/fitapp-ns/databases/(default)/documents/oauthGrants/${userId}__${clientId}`,
    { headers: { Authorization: 'Bearer owner' } }
  );
  check('grant record exists for Connected Apps UI', grantDoc.status === 200, `got ${grantDoc.status}`);

  const revoke = await postJson(`${BASE}/grants/revoke`, { grantId: `${userId}__${clientId}` },
    { Authorization: `Bearer ${idToken}` });
  check('grant revoked via app endpoint', revoke.status === 200 && revoke.body.revoked === true);

  const afterRevoke = await fetch(BASE, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json, text/event-stream',
      Authorization: `Bearer ${refreshed.body.access_token}`,
    },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'ping' }),
  });
  check('revocation kills live access tokens', afterRevoke.status === 401, `got ${afterRevoke.status}`);

  const refreshAfterRevoke = await postForm(`${BASE}/token`, {
    grant_type: 'refresh_token', refresh_token: refreshed.body.refresh_token, client_id: clientId,
  });
  check('revocation kills refresh tokens', refreshAfterRevoke.status === 400);

  console.log(`\n${failures === 0 ? '🎉 All checks passed' : `💥 ${failures} check(s) failed`}\n`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('Test run crashed:', err);
  process.exit(1);
});
