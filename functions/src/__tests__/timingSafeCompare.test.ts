import { isClientSecretValid } from '../utils/timingSafeCompare';

describe('isClientSecretValid', () => {
  it('returns true for identical secrets', () => {
    expect(isClientSecretValid('s3cr3t', 's3cr3t')).toBe(true);
  });

  it('returns false for different secrets with the same length', () => {
    expect(isClientSecretValid('password', 'passw0rd')).toBe(false);
  });

  it('returns false for different-length secrets', () => {
    expect(isClientSecretValid('short', 'averyverylongsecret')).toBe(false);
  });

  it('returns false for empty strings', () => {
    expect(isClientSecretValid('', '')).toBe(false);
    expect(isClientSecretValid('', 'nonempty')).toBe(false);
  });

  it('returns false for non-string inputs without throwing', () => {
    expect(isClientSecretValid(null, 'foo')).toBe(false);
    expect(isClientSecretValid('foo', undefined)).toBe(false);
    expect(isClientSecretValid(null, undefined)).toBe(false);
  });

  it('handles very long secrets', () => {
    const longSecret = 'a'.repeat(100_000);
    expect(isClientSecretValid(longSecret, longSecret)).toBe(true);
    expect(isClientSecretValid(longSecret, 'b'.repeat(100_000))).toBe(false);
  }, 20_000);
});
