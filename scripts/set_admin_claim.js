/**
 * set_admin_claim.js
 *
 * Grants or revokes the `admin` custom claim on a Firebase Auth user.
 * Admins are the only users allowed to write to the global exercise
 * library (/exerciseLibrary) — see firestore.rules.
 *
 * Usage (from the project root):
 *   # Against the local Auth emulator (default):
 *   node scripts/set_admin_claim.js grant <uid-or-email>
 *   node scripts/set_admin_claim.js revoke <uid-or-email>
 *
 *   # Against production (requires application-default credentials with
 *   # the Firebase Admin role, e.g. `gcloud auth application-default login`):
 *   node scripts/set_admin_claim.js grant <uid-or-email> --prod
 *
 * Note: custom claims propagate on the next ID token refresh, so a signed-in
 * user may need up to an hour (or a re-login) before rules see the claim.
 */

// firebase-admin lives in functions/node_modules
const admin = require('../functions/node_modules/firebase-admin');

const args = process.argv.slice(2).filter((a) => a !== '--prod');
const prod = process.argv.includes('--prod');
const [action, target] = args;

if (!['grant', 'revoke'].includes(action) || !target) {
  console.error('Usage: node scripts/set_admin_claim.js <grant|revoke> <uid-or-email> [--prod]');
  process.exit(1);
}

if (!prod) {
  process.env.FIREBASE_AUTH_EMULATOR_HOST =
    process.env.FIREBASE_AUTH_EMULATOR_HOST || 'localhost:9099';
}

admin.initializeApp({ projectId: 'fitapp-ns' });

async function main() {
  const auth = admin.auth();

  const user = target.includes('@')
    ? await auth.getUserByEmail(target)
    : await auth.getUser(target);

  // Preserve any other custom claims the user already has
  const claims = { ...(user.customClaims || {}) };
  if (action === 'grant') {
    claims.admin = true;
  } else {
    delete claims.admin;
  }

  await auth.setCustomUserClaims(user.uid, claims);

  console.log(
    `${action === 'grant' ? 'Granted' : 'Revoked'} admin claim for ${user.uid}` +
      ` (${user.email || 'no email'}) on ${prod ? 'PRODUCTION' : 'the Auth emulator'}.`
  );
  console.log(`Custom claims are now: ${JSON.stringify(claims)}`);
  process.exit(0);
}

main().catch((e) => {
  console.error('Failed:', e.message);
  process.exit(1);
});
