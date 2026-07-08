import * as admin from 'firebase-admin';
import { Request } from 'firebase-functions/v2/https';
import { ACCESS_TOKEN_PREFIX, SUPPORTED_SCOPES, isExpired, sha256Hex } from './oauthSecurity.js';

export interface AuthContext {
  userId: string;
  scopes: string[];
}

/**
 * Resolves the authenticated user and their scopes from the request.
 *
 * Two auth methods:
 * 1. Firebase ID token (the user's own app session) — full access
 * 2. OAuth access token (from the MCP connector flow) — exactly the scopes
 *    the user approved on the consent page
 *
 * Access tokens are looked up by SHA-256 digest; the plaintext token is never
 * stored anywhere server-side.
 */
export async function resolveUser(req: Request): Promise<AuthContext> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing Authorization header');
  }

  const token = authHeader.slice(7);
  if (!token) throw new Error('Missing token');

  if (token.startsWith(ACCESS_TOKEN_PREFIX)) {
    const ref = admin.firestore().doc(`oauthTokens/${sha256Hex(token)}`);
    const doc = await ref.get();
    if (!doc.exists) {
      throw new Error('Invalid credentials');
    }
    const data = doc.data()!;
    if (isExpired(data)) {
      await ref.delete();
      throw new Error('Invalid credentials');
    }
    return {
      userId: data.userId as string,
      scopes: (data.scope as string || '').split(' ').filter(Boolean),
    };
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    return {
      userId: decoded.uid,
      scopes: Object.keys(SUPPORTED_SCOPES),
    };
  } catch {
    throw new Error('Invalid credentials');
  }
}
