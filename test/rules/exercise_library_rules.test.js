/**
 * Firestore security-rules tests for the global exercise library
 * (/exerciseLibrary). Runs against the Firestore emulator via node:test.
 *
 * From the project root:
 *   npm run test:rules
 * (starts the emulator, runs this file, and tears the emulator down)
 */

const { test, before, after } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

let testEnv;

const EXERCISE = {
  name: 'Barbell Back Squat',
  description: 'Squat with a barbell across the upper back.',
  videoUrl: null,
  tags: ['legs', 'barbell'],
  aliases: ['back squat'],
};

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'fitapp-ns-rules-test',
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: Number(process.env.FIRESTORE_EMULATOR_PORT || 8081),
    },
  });

  // Seed one entry with rules disabled so read/update/delete cases have data
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'exerciseLibrary/seeded-squat'), EXERCISE);
  });
});

after(async () => {
  await testEnv?.cleanup();
});

const adminDb = () => testEnv.authenticatedContext('admin-user', { admin: true }).firestore();
const userDb = () => testEnv.authenticatedContext('regular-user').firestore();
const anonDb = () => testEnv.unauthenticatedContext().firestore();

test('signed-in user can read library entries', async () => {
  await assertSucceeds(getDoc(doc(userDb(), 'exerciseLibrary/seeded-squat')));
});

test('unauthenticated user cannot read library entries', async () => {
  await assertFails(getDoc(doc(anonDb(), 'exerciseLibrary/seeded-squat')));
});

test('admin can create a library entry', async () => {
  await assertSucceeds(
    setDoc(doc(adminDb(), 'exerciseLibrary/admin-created'), EXERCISE)
  );
});

test('regular user cannot create a library entry', async () => {
  await assertFails(setDoc(doc(userDb(), 'exerciseLibrary/user-created'), EXERCISE));
});

test('unauthenticated user cannot create a library entry', async () => {
  await assertFails(setDoc(doc(anonDb(), 'exerciseLibrary/anon-created'), EXERCISE));
});

test('admin can update a library entry', async () => {
  await assertSucceeds(
    updateDoc(doc(adminDb(), 'exerciseLibrary/seeded-squat'), {
      description: 'Updated description',
    })
  );
});

test('regular user cannot update a library entry', async () => {
  await assertFails(
    updateDoc(doc(userDb(), 'exerciseLibrary/seeded-squat'), {
      description: 'Sneaky edit',
    })
  );
});

test('user with a non-admin claim cannot write', async () => {
  const db = testEnv.authenticatedContext('claimed-user', { admin: false }).firestore();
  await assertFails(setDoc(doc(db, 'exerciseLibrary/claimed-created'), EXERCISE));
});

test('admin can delete a library entry', async () => {
  await assertSucceeds(deleteDoc(doc(adminDb(), 'exerciseLibrary/admin-created')));
});

test('regular user cannot delete a library entry', async () => {
  await assertFails(deleteDoc(doc(userDb(), 'exerciseLibrary/seeded-squat')));
});
