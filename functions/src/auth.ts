import * as admin from 'firebase-admin';
import { Request } from 'firebase-functions/v2/https';

/**
 * Resolves the authenticated user from the request.
 *
 * Supports two auth methods:
 * 1. Firebase ID token (from Flutter app or OAuth flow) - "Bearer <idToken>"
 * 2. API key fallback (for simple MCP client config) - "Bearer <apiKey>"
 *
 * ID tokens are tried first. If token verification fails (not a valid JWT),
 * falls back to API key lookup.
 */
export interface AuthContext {
  userId: string;
  scopes: string[];
}

/**
 * Resolves the authenticated user and their scopes from the request.
 *
 * Supports three auth methods:
 * 1. Firebase ID token (from Flutter app) - "Bearer <idToken>"
 * 2. OAuth access token (from Claude connector) - "Bearer <accessToken>"
 * 3. API key fallback (for manual MCP config) - "Bearer <apiKey>"
 */
export async function resolveUser(req: Request): Promise<AuthContext> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing Authorization header');
  }

  const token = authHeader.slice(7);
  if (!token) throw new Error('Missing token');

  // 1. Try Firebase ID token (user's personal session)
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    return {
      userId: decoded.uid,
      scopes: ['profile:read', 'workout:read', 'workout:write'], // Full access for personal tokens
    };
  } catch {
    // Not a valid ID token — move to token lookups
  }

  // 2. OAuth access token lookup (from Claude connector)
  const oauthDoc = await admin.firestore().doc(`oauthTokens/${token}`).get();
  if (oauthDoc.exists) {
    const data = oauthDoc.data()!;
    let scopes = (data.scope as string || 'profile:read workout:read').split(' ');
    
    // If Claude requested the generic 'claudeai' scope, grant full workout access
    if (scopes.includes('claudeai')) {
      if (!scopes.includes('workout:read')) scopes.push('workout:read');
      if (!scopes.includes('workout:write')) scopes.push('workout:write');
    }

    return {
      userId: data.userId as string,
      scopes: scopes,
    };
  }

  // 3. API key fallback
  const apiKeyDoc = await admin.firestore().doc(`apiKeys/${token}`).get();
  if (apiKeyDoc.exists) {
    return {
      userId: apiKeyDoc.data()!.userId as string,
      scopes: ['profile:read', 'workout:read', 'workout:write'], // Full access for API keys
    };
  }

  throw new Error('Invalid credentials');
}
