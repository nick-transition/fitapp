import * as crypto from 'crypto';
import { Timestamp } from 'firebase-admin/firestore';

// Every scope the authorization server can grant, with the description shown
// on the consent page. Tokens can never carry a scope outside this list.
export const SUPPORTED_SCOPES: Record<string, string> = {
  'profile:read': 'Read your basic profile information',
  'workout:read': 'View your workout plans, sessions, and history',
  'workout:write': 'Create workout plans and log sessions',
};

export const AUTH_CODE_TTL_MS = 5 * 60 * 1000;
export const ACCESS_TOKEN_TTL_MS = 60 * 60 * 1000;
export const ACCESS_TOKEN_EXPIRES_IN_SECONDS = Math.floor(ACCESS_TOKEN_TTL_MS / 1000);
export const REFRESH_TOKEN_TTL_MS = 60 * 24 * 60 * 60 * 1000;

export const ACCESS_TOKEN_PREFIX = 'fit_at_';
export const REFRESH_TOKEN_PREFIX = 'fit_rt_';
export const AUTH_CODE_PREFIX = 'fit_code_';
export const CLIENT_ID_PREFIX = 'fit_client_';

export function generateSecret(prefix: string): string {
  return `${prefix}${crypto.randomBytes(32).toString('base64url')}`;
}

/**
 * Credentials are stored under their SHA-256 digest, never verbatim: a read
 * of the database yields no usable bearer credential.
 */
export function sha256Hex(value: string): string {
  return crypto.createHash('sha256').update(value).digest('hex');
}

const PKCE_VERIFIER_RE = /^[A-Za-z0-9\-._~]{43,128}$/;

export function verifyPkceS256(codeVerifier: unknown, codeChallenge: unknown): boolean {
  if (typeof codeVerifier !== 'string' || typeof codeChallenge !== 'string') {
    return false;
  }
  if (!PKCE_VERIFIER_RE.test(codeVerifier)) {
    return false;
  }
  const computed = crypto.createHash('sha256').update(codeVerifier).digest('base64url');
  const computedBuf = Buffer.from(computed);
  const challengeBuf = Buffer.from(codeChallenge);
  return (
    computedBuf.length === challengeBuf.length &&
    crypto.timingSafeEqual(computedBuf, challengeBuf)
  );
}

export function parseScopes(scope: unknown): string[] {
  if (typeof scope !== 'string') return [];
  return [...new Set(scope.split(/\s+/).filter(Boolean))];
}

export function unknownScopes(scopes: string[]): string[] {
  return scopes.filter((s) => !(s in SUPPORTED_SCOPES));
}

interface OAuthClientData {
  redirectUris?: unknown;
  redirectUri?: unknown;
}

interface ExpiringData {
  expiresAt?: unknown;
}

function toDate(value: unknown): Date | undefined {
  if (value instanceof Date) {
    return value;
  }
  if (value && typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function') {
    return value.toDate() as Date;
  }
  return undefined;
}

export function createExpiry(ttlMs: number, now = Date.now()): Timestamp {
  return Timestamp.fromDate(new Date(now + ttlMs));
}

export function isExpired(data: ExpiringData, now = Date.now()): boolean {
  const expiresAt = toDate(data.expiresAt);
  if (!expiresAt) {
    return true;
  }
  return expiresAt.getTime() <= now;
}

/**
 * Redirect URIs must be pre-registered and match exactly. https only, with a
 * loopback exception for local development.
 */
export function isValidRedirectUri(uri: string): boolean {
  let parsed: URL;
  try {
    parsed = new URL(uri);
  } catch {
    return false;
  }
  if (parsed.hash) {
    return false;
  }
  if (parsed.protocol === 'https:') {
    return true;
  }
  return (
    parsed.protocol === 'http:' &&
    (parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1')
  );
}

export function isRedirectUriAllowed(clientData: OAuthClientData, redirectUri: string): boolean {
  if (!isValidRedirectUri(redirectUri)) {
    return false;
  }

  const redirectUris = Array.isArray(clientData.redirectUris)
    ? clientData.redirectUris.filter((uri): uri is string => typeof uri === 'string')
    : [];

  if (typeof clientData.redirectUri === 'string') {
    redirectUris.push(clientData.redirectUri);
  }

  return redirectUris.includes(redirectUri);
}
