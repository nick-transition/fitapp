/**
 * seed_emulator.js
 *
 * Seeds the Firestore emulator with a realistic user, program, and 4-day plan
 * for testing the plan card day-header feature.
 *
 * Run from the project root after starting emulators:
 *   FIRESTORE_EMULATOR_HOST=localhost:8081 node scripts/seed_emulator.js
 *
 * Or just:
 *   node scripts/seed_emulator.js
 */

const admin = require('../functions/node_modules/firebase-admin');

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || 'localhost:9099';

admin.initializeApp({ projectId: 'fitapp-ns' });

const db = admin.firestore();
const auth = admin.auth();
const ts = (d) => admin.firestore.Timestamp.fromDate(d || new Date());
const daysAgo = (n) => { const d = new Date(); d.setDate(d.getDate() - n); return d; };

const USER_UID = 'mock-user-123';
const COACH_UID = 'mock-coach-456';
const PROGRAM_ID = 'prog-strength-001';
const PLAN_ID = 'plan-4day-001';
const WORKOUT_ID_1 = 'workout-push-001';
const WORKOUT_ID_2 = 'workout-hiit-001';
const SESSION_ID_1 = 'session-completed-001';
const SESSION_ID_2 = 'session-scheduled-001';

async function ensureAuthUser(uid, email, displayName, password) {
  try {
    await auth.getUser(uid);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      await auth.createUser({ uid, email, displayName, password });
    } else {
      throw e;
    }
  }
}

async function seed() {
  // Create auth emulator users with deterministic UIDs
  await ensureAuthUser(USER_UID, 'testuser@gmail.com', 'Test User', 'testpass123');
  await ensureAuthUser(COACH_UID, 'coach@gmail.com', 'Coach User', 'coachpass123');
  console.log('Auth users created/verified.');

  const batch = db.batch();
  const created = [];

  // ── Athlete User ──
  batch.set(db.collection('users').doc(USER_UID), {
    uid: USER_UID,
    displayName: 'Test User',
    email: 'testuser@gmail.com',
    createdAt: ts(daysAgo(30)),
  });
  created.push(`users/${USER_UID}`);

  // ── Coach User ──
  batch.set(db.collection('users').doc(COACH_UID), {
    uid: COACH_UID,
    displayName: 'Coach User',
    email: 'coach@gmail.com',
    createdAt: ts(daysAgo(30)),
  });
  created.push(`users/${COACH_UID}`);

  // ── Program ──
  batch.set(
    db.collection('users').doc(USER_UID).collection('programs').doc(PROGRAM_ID),
    {
      name: '4-Day Strength & Conditioning',
      description: 'Full-body strength block with conditioning and aerobic work.',
      workoutIds: [],
      createdAt: ts(daysAgo(14)),
      updatedAt: ts(daysAgo(2)),
    }
  );
  created.push(`users/${USER_UID}/programs/${PROGRAM_ID}`);

  // ── Plan with 4 days ──
  const plan = {
    programId: PROGRAM_ID,
    name: '4-Day Strength & Conditioning',
    description: 'Lower body strength, upper body strength, metabolic conditioning, and aerobic base work.',
    type: 'custom',
    schedule: 'Mon / Tue / Thu / Fri',
    days: [
      {
        id: 'day-lower-001',
        name: 'Lower Body',
        description: 'Quad and posterior chain focus',
        order: 0,
        exercises: [
          { id: 'ex-001', name: 'Back Squat', sets: 4, reps: 6, weight: '225 lbs', order: 0, tags: ['legs', 'compound'], restSeconds: 180, notes: 'Belt up on sets 3–4' },
          { id: 'ex-002', name: 'Romanian Deadlift', sets: 3, reps: 8, weight: '185 lbs', order: 1, tags: ['hamstrings'], restSeconds: 120 },
          { id: 'ex-003', name: 'Leg Press', sets: 3, reps: 12, weight: '360 lbs', order: 2, tags: ['quads'], restSeconds: 90 },
          { id: 'ex-004', name: 'Walking Lunges', sets: 3, reps: 10, weight: '50 lbs', order: 3, tags: ['legs'], restSeconds: 60, notes: '10 reps per leg' },
          { id: 'ex-005', name: 'Standing Calf Raise', sets: 4, reps: 15, weight: '135 lbs', order: 4, tags: ['calves'], restSeconds: 45 },
        ],
      },
      {
        id: 'day-upper-001',
        name: 'Upper Body',
        description: 'Push and pull balance',
        order: 1,
        exercises: [
          { id: 'ex-006', name: 'Barbell Bench Press', sets: 4, reps: 8, weight: '185 lbs', order: 0, tags: ['chest', 'compound'], restSeconds: 120, videoUrl: 'https://www.youtube.com/watch?v=vcBig73ojpE' },
          { id: 'ex-007', name: 'Barbell Row', sets: 4, reps: 8, weight: '165 lbs', order: 1, tags: ['back', 'compound'], restSeconds: 120 },
          { id: 'ex-008', name: 'Overhead Press', sets: 3, reps: 8, weight: '115 lbs', order: 2, tags: ['shoulders'], restSeconds: 90 },
          { id: 'ex-009', name: 'Pull-Ups', sets: 3, reps: 8, weight: 'Bodyweight', order: 3, tags: ['back'], restSeconds: 90, notes: 'Use band if needed' },
          { id: 'ex-010', name: 'Tricep Pushdown', sets: 3, reps: 12, weight: '50 lbs', order: 4, tags: ['triceps'], restSeconds: 60 },
          { id: 'ex-011', name: 'Barbell Curl', sets: 3, reps: 10, weight: '75 lbs', order: 5, tags: ['biceps'], restSeconds: 60 },
        ],
      },
      {
        id: 'day-conditioning-001',
        name: 'Conditioning',
        description: 'Metabolic circuit — 4 rounds, 40s on / 20s off',
        order: 2,
        exercises: [
          { id: 'ex-012', name: 'Kettlebell Swing', sets: 4, reps: 20, weight: '53 lbs', order: 0, tags: ['cardio', 'posterior chain'], restSeconds: 20 },
          { id: 'ex-013', name: 'Box Jump', sets: 4, reps: 10, weight: 'Bodyweight', order: 1, tags: ['plyometric', 'legs'], restSeconds: 20, notes: '24" box' },
          { id: 'ex-014', name: 'Battle Ropes', sets: 4, reps: null, durationSeconds: 40, order: 2, tags: ['cardio', 'upper body'], restSeconds: 20 },
          { id: 'ex-015', name: 'Burpees', sets: 4, reps: 12, weight: 'Bodyweight', order: 3, tags: ['full body', 'cardio'], restSeconds: 20 },
          { id: 'ex-016', name: 'Assault Bike Sprint', sets: 4, reps: null, durationSeconds: 30, order: 4, tags: ['cardio'], restSeconds: 90, notes: 'Max effort each round' },
        ],
      },
      {
        id: 'day-zone2-001',
        name: 'Zone 2',
        description: 'Steady-state aerobic base building — keep HR 130–150 bpm',
        order: 3,
        exercises: [
          { id: 'ex-017', name: 'Treadmill Incline Walk', sets: 1, reps: null, durationSeconds: 2400, order: 0, tags: ['cardio', 'zone 2'], restSeconds: 0, notes: '3.5 mph / 8% incline — 40 min' },
          { id: 'ex-018', name: 'Stationary Bike', sets: 1, reps: null, durationSeconds: 1800, order: 1, tags: ['cardio', 'zone 2'], restSeconds: 0, notes: 'Moderate resistance — 30 min alternative' },
        ],
      },
    ],
    createdAt: ts(daysAgo(14)),
    updatedAt: ts(daysAgo(2)),
  };

  batch.set(
    db.collection('users').doc(USER_UID).collection('plans').doc(PLAN_ID),
    plan
  );
  created.push(`users/${USER_UID}/plans/${PLAN_ID}`);

  // ── Workouts (linked to program) ──
  batch.set(
    db.collection('users').doc(USER_UID).collection('workouts').doc(WORKOUT_ID_1),
    {
      programId: PROGRAM_ID,
      name: 'Push Day',
      description: 'Chest, shoulders, and triceps compound movements',
      type: 'strength',
      schedule: 'Mon',
      exercises: [
        { name: 'Bench Press', sets: 4, reps: 8, weight: '185 lbs', order: 0, tags: ['chest'], videoUrl: 'https://www.youtube.com/watch?v=vcBig73ojpE' },
        { name: 'Overhead Press', sets: 3, reps: 8, weight: '95 lbs', order: 1, tags: ['shoulders'] },
        { name: 'Tricep Pushdown', sets: 3, reps: 12, weight: '50 lbs', order: 2, tags: ['triceps'] },
      ],
      createdAt: ts(daysAgo(10)),
      updatedAt: ts(daysAgo(3)),
    }
  );
  created.push(`users/${USER_UID}/workouts/${WORKOUT_ID_1}`);

  batch.set(
    db.collection('users').doc(USER_UID).collection('workouts').doc(WORKOUT_ID_2),
    {
      programId: PROGRAM_ID,
      name: 'HIIT Cardio',
      description: 'High intensity interval training',
      type: 'cardio',
      schedule: 'Wed',
      exercises: [
        { name: 'Burpees', sets: 4, reps: 15, order: 0, tags: ['cardio'] },
        { name: 'Mountain Climbers', sets: 4, reps: 20, order: 1, tags: ['cardio'] },
      ],
      createdAt: ts(daysAgo(10)),
      updatedAt: ts(daysAgo(4)),
    }
  );
  created.push(`users/${USER_UID}/workouts/${WORKOUT_ID_2}`);

  // ── Completed Session (yesterday) ──
  const yesterday = daysAgo(1);
  yesterday.setHours(10, 0, 0, 0);
  const yesterdayEnd = new Date(yesterday);
  yesterdayEnd.setMinutes(65);

  batch.set(
    db.collection('users').doc(USER_UID).collection('sessions').doc(SESSION_ID_1),
    {
      planId: PLAN_ID,
      planName: '4-Day Strength & Conditioning',
      dayName: 'Lower Body',
      startedAt: ts(yesterday),
      completedAt: ts(yesterdayEnd),
      notes: 'Felt strong today, upped squat weight',
      entries: [
        {
          exerciseName: 'Back Squat',
          order: 0,
          sets: [
            { reps: 6, weight: '225 lbs' },
            { reps: 6, weight: '225 lbs' },
            { reps: 5, weight: '225 lbs' },
            { reps: 5, weight: '225 lbs' },
          ],
        },
        {
          exerciseName: 'Romanian Deadlift',
          order: 1,
          sets: [
            { reps: 8, weight: '185 lbs' },
            { reps: 8, weight: '185 lbs' },
            { reps: 7, weight: '185 lbs' },
          ],
          notes: 'Focus on hip hinge',
        },
      ],
    }
  );
  created.push(`users/${USER_UID}/sessions/${SESSION_ID_1}`);

  // ── Scheduled Session (tomorrow) ──
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(9, 0, 0, 0);

  batch.set(
    db.collection('users').doc(USER_UID).collection('sessions').doc(SESSION_ID_2),
    {
      planId: PLAN_ID,
      planName: '4-Day Strength & Conditioning',
      dayName: 'Upper Body',
      scheduledAt: ts(tomorrow),
    }
  );
  created.push(`users/${USER_UID}/sessions/${SESSION_ID_2}`);

  // ── Coach Connection (active) ──
  const connectionId = `${USER_UID}_${COACH_UID}`;
  batch.set(
    db.collection('coachConnections').doc(connectionId),
    {
      ownerUid: USER_UID,
      ownerName: 'Test User',
      coachUid: COACH_UID,
      coachName: 'Coach User',
      type: 'connection',
      status: 'active',
      createdAt: ts(daysAgo(7)),
      connectedAt: ts(daysAgo(7)),
    }
  );
  created.push(`coachConnections/${connectionId}`);

  await batch.commit();

  console.log('\n✅ Seed complete! Created:\n');
  for (const path of created) console.log(`  /${path}`);
  console.log(`\nAthlete UID: ${USER_UID}`);
  console.log(`Coach UID:   ${COACH_UID}`);
  console.log(`Plan: "${plan.name}" with 4 days:`);
  plan.days.forEach((d, i) => console.log(`  Day ${i + 1}: ${d.name} (${d.exercises.length} exercises)`));
  console.log(`Workouts: Push Day (3 exercises), HIIT Cardio (2 exercises)`);
  console.log(`Sessions: 1 completed (yesterday), 1 scheduled (tomorrow)`);
  console.log(`Coach connection: ${USER_UID} ↔ ${COACH_UID} (active)`);
  console.log();
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
