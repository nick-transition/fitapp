import * as crypto from 'crypto';

/**
 * Compare OAuth client secrets without leaking length via early returns.
 * Hash both values to fixed-size digests before timingSafeEqual.
 */
export function isClientSecretValid(
  storedSecret: unknown,
  providedSecret: unknown,
): boolean {
  if (typeof storedSecret !== 'string' || typeof providedSecret !== 'string') {
    return false;
  }
  if (storedSecret.length === 0 || providedSecret.length === 0) {
    return false;
  }

  const storedHash = crypto.createHash('sha256').update(storedSecret).digest();
  const providedHash = crypto.createHash('sha256').update(providedSecret).digest();
  return crypto.timingSafeEqual(storedHash, providedHash);
}
