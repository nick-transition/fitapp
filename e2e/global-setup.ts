import { execSync } from 'node:child_process';
import * as path from 'node:path';

// Resets the Firebase emulators to a known state before every Playwright run
// so tests never depend on leftover data from a previous run or manual poking.

const PROJECT_ID = 'fitapp-ns';
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST ?? 'localhost:8081';
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? 'localhost:9099';

async function clear(url: string, what: string) {
  const res = await fetch(url, { method: 'DELETE' });
  if (!res.ok) {
    throw new Error(`Failed to clear ${what}: ${url} responded ${res.status}`);
  }
}

export default async function globalSetup() {
  try {
    await fetch(`http://${AUTH_HOST}/`);
  } catch {
    throw new Error(
      `Firebase emulators are not reachable (auth: ${AUTH_HOST}). ` +
        'Start them with `firebase emulators:start --only auth,firestore` ' +
        'or run the suite via scripts/run_e2e.sh.',
    );
  }

  await clear(
    `http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
    'Firestore emulator',
  );
  await clear(
    `http://${AUTH_HOST}/emulator/v1/projects/${PROJECT_ID}/accounts`,
    'Auth emulator',
  );

  execSync(`node ${path.join(__dirname, '..', 'scripts', 'seed_emulator.js')}`, {
    stdio: 'inherit',
    env: {
      ...process.env,
      FIRESTORE_EMULATOR_HOST: FIRESTORE_HOST,
      FIREBASE_AUTH_EMULATOR_HOST: AUTH_HOST,
    },
  });
}
