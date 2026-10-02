/**
 * Tool/dispatcher regression tests for the exercise-library MCP tools
 * (search_exercise_library, get_library_exercise, update_library_exercise,
 * add_library_exercise). Runs against the Firestore emulator via node:test,
 * exercising the real handler code compiled from functions/src.
 *
 * From the project root:
 *   npm run test:tools
 * (builds functions, starts the Firestore emulator, runs this file, and
 * tears the emulator down)
 */

const { test, before, after } = require('node:test');
const assert = require('node:assert');
const path = require('node:path');
const { createRequire } = require('node:module');

// Point the admin SDK at the emulator BEFORE anything initializes Firestore.
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8081';

const functionsRequire = createRequire(path.resolve(__dirname, '../../functions/package.json'));
const admin = functionsRequire('firebase-admin');
const projectId = 'fitapp-tools-test';

let handleToolCall;
let handleExerciseLibraryTool;

before(async () => {
  admin.initializeApp({ projectId });

  // The compiled handlers — real code, no mocks.
  ({ handleExerciseLibraryTool } = functionsRequire('./lib/tools/exercise-library-tools.js'));
  ({ handleToolCall } = functionsRequire('./lib/tools/index.js'));

  // Fresh collection for every run.
  await clearLibrary();
});

after(async () => {
  await Promise.all(admin.apps.map((app) => app.delete()));
});

async function clearLibrary() {
  const db = admin.firestore();
  const snapshot = await db.collection('exerciseLibrary').get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

const adminAuth = { userId: 'admin-user', scopes: ['workout:read', 'workout:write'], isAdmin: true };
const userAuth = { userId: 'regular-user', scopes: ['workout:read', 'workout:write'], isAdmin: false };

function seedEntry(id, data) {
  return admin.firestore().collection('exerciseLibrary').doc(id).set(data);
}

function parse(result) {
  assert.equal(result.isError, undefined, `unexpected isError: ${result.content[0].text}`);
  return JSON.parse(result.content[0].text);
}

function parseError(result) {
  assert.equal(result.isError, true, `expected isError, got: ${result.content[0].text}`);
  return JSON.parse(result.content[0].text);
}

const SQUAT = {
  name: 'Barbell Back Squat',
  description: 'Squat with a barbell across the upper back.',
  videoUrl: 'https://youtube.com/watch?v=squat',
  tags: ['legs', 'barbell'],
  aliases: ['back squat'],
};
const BENCH = {
  name: 'Bench Press',
  description: 'Horizontal press on a bench.',
  videoUrl: '',
  tags: ['chest', 'barbell'],
  aliases: ['bench'],
};
const PUSHUP = {
  name: 'Push-Up',
  description: 'Bodyweight horizontal press.',
  videoUrl: '',
  tags: ['chest', 'bodyweight'],
  aliases: ['press up', 'pushup'],
};

before(async () => {
  await seedEntry('barbell-back-squat', SQUAT);
  await seedEntry('bench-press', BENCH);
  await seedEntry('push-up', PUSHUP);
});

// ── dispatcher registration ─────────────────────────────────────────────────

test('all four library tools are registered for MCP discovery', async () => {
  const { toolDefinitions } = functionsRequire('./lib/tools/index.js');
  const names = toolDefinitions.map((t) => t.name);
  for (const expected of [
    'search_exercise_library',
    'get_library_exercise',
    'update_library_exercise',
    'add_library_exercise',
  ]) {
    assert.ok(names.includes(expected), `missing tool: ${expected}`);
  }
});

test('handleToolCall routes library reads and enforces the read scope', async () => {
  const ok = await handleToolCall('get_library_exercise', { exerciseId: 'bench-press' }, userAuth);
  assert.equal(parse(ok).name, 'Bench Press');

  const noScope = await handleToolCall(
    'search_exercise_library',
    {},
    { userId: 'regular-user', scopes: [], isAdmin: false }
  );
  assert.equal(parseError(noScope).error, 'Missing required scope: workout:read');
});

// ── search ──────────────────────────────────────────────────────────────────

test('search matches case-insensitively on name and aliases', async () => {
  const byName = parse(await handleExerciseLibraryTool('search_exercise_library', { query: 'push' }, userAuth));
  assert.deepEqual(byName.results.map((r) => r.id), ['push-up']);

  const byAlias = parse(await handleExerciseLibraryTool('search_exercise_library', { query: 'BACK SQUAT' }, userAuth));
  assert.deepEqual(byAlias.results.map((r) => r.id), ['barbell-back-squat']);

  const byFragment = parse(await handleExerciseLibraryTool('search_exercise_library', { query: 'squa' }, userAuth));
  assert.deepEqual(byFragment.results.map((r) => r.id), ['barbell-back-squat']);
});

test('search tag filters require ALL requested tags, case-insensitively', async () => {
  const both = parse(
    await handleExerciseLibraryTool('search_exercise_library', { tags: ['CHEST', 'Barbell'] }, userAuth)
  );
  assert.deepEqual(both.results.map((r) => r.id), ['bench-press']);

  const one = parse(await handleExerciseLibraryTool('search_exercise_library', { tags: ['chest'] }, userAuth));
  assert.deepEqual(one.results.map((r) => r.id), ['bench-press', 'push-up']);
});

test('search combines query and tag filters with AND semantics', async () => {
  const combined = parse(
    await handleExerciseLibraryTool('search_exercise_library', { query: 'press', tags: ['bodyweight'] }, userAuth)
  );
  // "press" matches Bench Press (name/alias) and Push-Up (alias "press up"),
  // but only Push-Up carries the bodyweight tag.
  assert.deepEqual(combined.results.map((r) => r.id), ['push-up']);
});

test('search results are deterministic and bounded', async () => {
  const all = parse(await handleExerciseLibraryTool('search_exercise_library', {}, userAuth));
  assert.deepEqual(
    all.results.map((r) => r.name),
    ['Barbell Back Squat', 'Bench Press', 'Push-Up'] // sorted by name
  );

  const limited = parse(await handleExerciseLibraryTool('search_exercise_library', { limit: 2 }, userAuth));
  assert.equal(limited.results.length, 2);
  assert.equal(limited.total, 2);

  const invalidLimit = parse(await handleExerciseLibraryTool('search_exercise_library', { limit: 0 }, userAuth));
  assert.equal(invalidLimit.results.length, 3, 'non-positive limit falls back to the default');
});

// ── get ─────────────────────────────────────────────────────────────────────

test('get returns the full entry with its document ID', async () => {
  const entry = parse(await handleExerciseLibraryTool('get_library_exercise', { exerciseId: 'bench-press' }, userAuth));
  assert.equal(entry.id, 'bench-press');
  assert.equal(entry.name, 'Bench Press');
  assert.deepEqual(entry.tags, ['chest', 'barbell']);
});

test('get on a missing ID returns an explicit error, not a fake entry', async () => {
  const err = parseError(
    await handleExerciseLibraryTool('get_library_exercise', { exerciseId: 'no-such-exercise' }, userAuth)
  );
  assert.match(err.error, /not found/);
});

// ── update ──────────────────────────────────────────────────────────────────

test('admin partial update preserves omitted fields and creation metadata', async () => {
  const before = parse(await handleExerciseLibraryTool('get_library_exercise', { exerciseId: 'push-up' }, userAuth));

  const result = parse(
    await handleExerciseLibraryTool('update_library_exercise', { exerciseId: 'push-up', description: 'New cues.' }, adminAuth)
  );
  assert.deepEqual(result.updatedFields, ['description']);

  const after = parse(await handleExerciseLibraryTool('get_library_exercise', { exerciseId: 'push-up' }, userAuth));
  assert.equal(after.description, 'New cues.');
  assert.equal(after.name, before.name, 'name preserved');
  assert.deepEqual(after.tags, before.tags, 'tags preserved');
  assert.deepEqual(after.aliases, before.aliases, 'aliases preserved');
  assert.equal(after.videoUrl, before.videoUrl, 'videoUrl preserved');
});

test('update rejects unknown fields', async () => {
  const err = parseError(
    await handleExerciseLibraryTool(
      'update_library_exercise',
      { exerciseId: 'push-up', sets: 5 },
      adminAuth
    )
  );
  assert.match(err.error, /Unknown field: sets/);
});

test('update on a missing document fails instead of silently creating one', async () => {
  const err = parseError(
    await handleExerciseLibraryTool(
      'update_library_exercise',
      { exerciseId: 'never-existed', name: 'Ghost Lift' },
      adminAuth
    )
  );
  assert.match(err.error, /not found/);

  const stillMissing = await admin.firestore().collection('exerciseLibrary').doc('never-existed').get();
  assert.equal(stillMissing.exists, false, 'update must not create the document');
});

test('non-admin update is denied — even for documents that do not exist', async () => {
  const existing = parseError(
    await handleExerciseLibraryTool('update_library_exercise', { exerciseId: 'push-up', name: 'Hacked' }, userAuth)
  );
  assert.match(existing.error, /Only admins/);

  const missing = parseError(
    await handleExerciseLibraryTool('update_library_exercise', { exerciseId: 'never-existed', name: 'Hacked' }, userAuth)
  );
  assert.match(missing.error, /Only admins/, 'denied calls must not leak document existence');
});

test('renaming the display name keeps the stable document ID', async () => {
  const renamed = parse(
    await handleExerciseLibraryTool('update_library_exercise', { exerciseId: 'bench-press', name: 'Barbell Bench Press' }, adminAuth)
  );
  assert.equal(renamed.exerciseId, 'bench-press');

  const after = parse(await handleExerciseLibraryTool('get_library_exercise', { exerciseId: 'bench-press' }, userAuth));
  assert.equal(after.id, 'bench-press');
  assert.equal(after.name, 'Barbell Bench Press');

  // Restore for later cases.
  await handleExerciseLibraryTool('update_library_exercise', { exerciseId: 'bench-press', name: 'Bench Press' }, adminAuth);
});

// ── add ─────────────────────────────────────────────────────────────────────

test('admin add creates a new entry keyed by name slug with createdBy', async () => {
  const result = parse(
    await handleExerciseLibraryTool(
      'add_library_exercise',
      { name: 'Romanian Deadlift', tags: ['Posterior Chain', 'barbell'], aliases: ['rdl'] },
      adminAuth
    )
  );
  assert.equal(result.exerciseId, 'romanian-deadlift');

  const doc = await admin.firestore().collection('exerciseLibrary').doc('romanian-deadlift').get();
  assert.equal(doc.data().name, 'Romanian Deadlift');
  assert.equal(doc.data().createdBy, 'admin-user');
  assert.deepEqual(doc.data().tags, ['Posterior Chain', 'barbell']);
  assert.ok(doc.data().createdAt, 'createdAt set');
  assert.ok(doc.data().updatedAt, 'updatedAt set');

  // And it is immediately searchable by its alias.
  const found = parse(
    await handleExerciseLibraryTool('search_exercise_library', { query: 'rdl' }, userAuth)
  );
  assert.deepEqual(found.results.map((r) => r.id), ['romanian-deadlift']);
});

test('add over an existing ID is rejected without overwriting the entry', async () => {
  const err = parseError(
    await handleExerciseLibraryTool(
      'add_library_exercise',
      { name: 'Malware Squat', exerciseId: 'barbell-back-squat' },
      adminAuth
    )
  );
  assert.match(err.error, /already exists/);

  const doc = await admin.firestore().collection('exerciseLibrary').doc('barbell-back-squat').get();
  assert.equal(doc.data().name, 'Barbell Back Squat', 'original entry untouched');
});

test('non-admin add is denied', async () => {
  const err = parseError(
    await handleExerciseLibraryTool('add_library_exercise', { name: 'Sneaky Curl' }, userAuth)
  );
  assert.match(err.error, /Only admins/);

  const doc = await admin.firestore().collection('exerciseLibrary').doc('sneaky-curl').get();
  assert.equal(doc.exists, false);
});

test('add validates field types and requires a name', async () => {
  const noName = parseError(await handleExerciseLibraryTool('add_library_exercise', {}, adminAuth));
  assert.match(noName.error, /name is required/);

  const badTags = parseError(
    await handleExerciseLibraryTool('add_library_exercise', { name: 'X', tags: 'legs' }, adminAuth)
  );
  assert.match(badTags.error, /tags must be an array/);
});
