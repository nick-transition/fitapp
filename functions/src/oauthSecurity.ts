import * as crypto from 'crypto';
import * as admin from 'firebase-admin';

export const OAUTH_ACCESS_TOKEN_TTL_MS = 90 * 24 * 60 * 60 * 1000;
export const OAUTH_ACCESS_TOKEN_EXPIRES_IN_SECONDS = Math.floor(OAUTH_ACCESS_TOKEN_TTL_MS / 1000);

interface OAuthClientData {
  redirectUris?: unknown;
  redirectUri?: unknown;
  secret?: unknown;
}

interface OAuthTokenData {
  createdAt?: unknown;
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

export function createOAuthTokenExpiry(now = Date.now()): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(now + OAUTH_ACCESS_TOKEN_TTL_MS));
}

export function isOAuthTokenExpired(data: OAuthTokenData, now = Date.now()): boolean {
  const expiresAt = toDate(data.expiresAt);
  if (expiresAt) {
    return expiresAt.getTime() <= now;
  }

  const createdAt = toDate(data.createdAt);
  if (!createdAt) {
    return true;
  }

  return createdAt.getTime() + OAUTH_ACCESS_TOKEN_TTL_MS <= now;
}

export function isRedirectUriAllowed(clientData: OAuthClientData, redirectUri: string): boolean {
  try {
    new URL(redirectUri);
  } catch {
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

export function isClientSecretValid(storedSecret: unknown, providedSecret: unknown): boolean {
  if (typeof storedSecret !== 'string' || typeof providedSecret !== 'string') {
    return false;
  }

  const storedHash = crypto.createHash('sha256').update(storedSecret).digest();
  const providedHash = crypto.createHash('sha256').update(providedSecret).digest();
  return crypto.timingSafeEqual(storedHash, providedHash);
}
