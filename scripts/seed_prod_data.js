/**
 * seed_prod_data.js
 *
 * Seeds realistic test data into the fitapp-ns Firestore project for demoing
 * the coach sharing feature. Does NOT create Firebase Auth users — only
 * Firestore documents.
 *
 * Run from the project root:
 *   node scripts/seed_prod_data.js
 *
 * Requires firebase-admin (resolved from functions/node_modules).
 */

// firebase-admin lives in functions/node_modules
const admin = require('../functions/node_modules/firebase-admin');

// Point at local Firestore emulator — never touch production
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8081';

admin.initializeApp({ projectId: 'fitapp-ns' });

const db = admin.firestore();

// ─── IDs ──────────────────────────────────────────────────────────────────────

const ATHLETE_UID = 'test-athlete-001';
const COACH_UID = 'test-coach-001';
const INVITE_DOC_ID = `invite_${ATHLETE_UID}`;
const CONNECTION_DOC_ID = `${ATHLETE_UID}_${COACH_UID}`;

// ─── Helpers ─────────────────────────────────────────────────────────────────

const ts = (date) => admin.firestore.Timestamp.fromDate(date);

const daysAgo = (n) => {
  const d = new Date();
  d.setDate(d.getDate() - n);
  d.setHours(9, 0, 0, 0);
  return d;
};

let idCounter = 1;
const uid = () => `seed_${String(idCounter++).padStart(4, '0')}`;

// ─── Data definitions ────────────────────────────────────────────────────────

function makePPLProgram() {
  const programId = 'prog-ppl-001';

  const plans = [
    {
      id: 'plan-push-001',
      programId,
      name: 'Push Day',
      description: 'Chest, shoulders, and triceps',
      type: 'custom',
      schedule: 'Mon / Thu',
      days: [
        {
          id: 'day-push-001',
          name: 'Push A',
          description: 'Primary push session',
          order: 0,
          exercises: [
            { id: uid(), name: 'Barbell Bench Press', sets: 4, reps: 8, weight: '185 lbs', order: 0, tags: ['chest', 'compound'], restSeconds: 120 },
            { id: uid(), name: 'Overhead Press',      sets: 3, reps: 8, weight: '115 lbs', order: 1, tags: ['shoulders'], restSeconds: 90 },
            { id: uid(), name: 'Incline DB Press',    sets: 3, reps: 10, weight: '65 lbs', order: 2, tags: ['chest'], restSeconds: 90 },
            { id: uid(), name: 'Lateral Raises',      sets: 3, reps: 15, weight: '20 lbs', order: 3, tags: ['shoulders'], restSeconds: 60 },
            { id: uid(), name: 'Tricep Pushdown',     sets: 3, reps: 12, weight: '50 lbs', order: 4, tags: ['triceps'], restSeconds: 60 },
          ],
        },
      ],
      createdAt: ts(daysAgo(20)),
      updatedAt: ts(daysAgo(20)),
    },
    {
      id: 'plan-pull-001',
      programId,
      name: 'Pull Day',
      description: 'Back and biceps',
      type: 'custom',
      schedule: 'Tue / Fri',
      days: [
        {
          id: 'day-pull-001',
          name: 'Pull A',
          description: 'Primary pull session',
          order: 0,
          exercises: [
            { id: uid(), name: 'Barbell Row',      sets: 4, reps: 8,  weight: '165 lbs', order: 0, tags: ['back', 'compound'], restSeconds: 120 },
            { id: uid(), name: 'Pull-Ups',         sets: 3, reps: 8,  weight: 'Bodyweight', order: 1, tags: ['back'], restSeconds: 90 },
            { id: uid(), name: 'Cable Row',        sets: 3, reps: 10, weight: '120 lbs', order: 2, tags: ['back'], restSeconds: 90 },
            { id: uid(), name: 'Face Pulls',       sets: 3, reps: 15, weight: '40 lbs', order: 3, tags: ['rear delt'], restSeconds: 60 },
            { id: uid(), name: 'Barbell Curl',     sets: 3, reps: 10, weight: '75 lbs', order: 4, tags: ['biceps'], restSeconds: 60 },
          ],
        },
      ],
      createdAt: ts(daysAgo(20)),
      updatedAt: ts(daysAgo(20)),
    },
    {
      id: 'plan-legs-001',
      programId,
      name: 'Leg Day',
      description: 'Quads, hamstrings, and calves',
      type: 'custom',
      schedule: 'Wed / Sat',
      days: [
        {
          id: 'day-legs-001',
          name: 'Legs A',
          description: 'Primary leg session',
          order: 0,
          exercises: [
            { id: uid(), name: 'Back Squat',        sets: 4, reps: 6,  weight: '225 lbs', order: 0, tags: ['legs', 'compound'], restSeconds: 180 },
            { id: uid(), name: 'Romanian Deadlift', sets: 3, reps: 8,  weight: '185 lbs', order: 1, tags: ['hamstrings'], restSeconds: 120 },
            { id: uid(), name: 'Leg Press',         sets: 3, reps: 12, weight: '360 lbs', order: 2, tags: ['quads'], restSeconds: 90 },
            { id: uid(), name: 'Leg Curl',          sets: 3, reps: 12, weight: '110 lbs', order: 3, tags: ['hamstrings'], restSeconds: 60 },
            { id: uid(), name: 'Standing Calf Raise', sets: 4, reps: 15, weight: '135 lbs', order: 4, tags: ['calves'], restSeconds: 60 },
          ],
        },
      ],
      createdAt: ts(daysAgo(20)),
      updatedAt: ts(daysAgo(20)),
    },
  ];

  const program = {
    id: programId,
    name: 'Push/Pull/Legs 12-Week',
    description: 'Classic PPL hypertrophy block. 6 days/week, progressive overload each week.',
    createdAt: ts(daysAgo(20)),
    updatedAt: ts(daysAgo(5)),
  };

  return { program, plans };
}

function makeHIITProgram() {
  const programId = 'prog-hiit-001';

  const plans = [
    {
      id: 'plan-hiit-am-001',
      programId,
      name: 'Morning HIIT Circuit',
      description: '20-minute metabolic circuit',
      type: 'custom',
      schedule: 'Mon / Wed / Fri',
      days: [
        {
          id: 'day-hiit-001',
          name: 'HIIT Circuit A',
          description: '4 rounds, 40s on / 20s off',
          order: 0,
          exercises: [
            { id: uid(), name: 'Kettlebell Swing',  sets: 4, reps: 20, weight: '53 lbs',     order: 0, tags: ['cardio', 'posterior chain'], restSeconds: 20 },
            { id: uid(), name: 'Box Jump',          sets: 4, reps: 10, weight: 'Bodyweight', order: 1, tags: ['plyometric', 'legs'],         restSeconds: 20 },
            { id: uid(), name: 'Battle Ropes',      sets: 4, durationSeconds: 40, order: 2, tags: ['cardio', 'upper body'],                  restSeconds: 20 },
            { id: uid(), name: 'Burpees',           sets: 4, reps: 12, weight: 'Bodyweight', order: 3, tags: ['full body', 'cardio'],        restSeconds: 20 },
          ],
        },
      ],
      createdAt: ts(daysAgo(14)),
      updatedAt: ts(daysAgo(14)),
    },
    {
      id: 'plan-hiit-finisher-001',
      programId,
      name: 'Sprint Finisher',
      description: 'Treadmill sprint protocol — 8×30s all-out',
      type: 'custom',
      schedule: 'Tue / Thu',
      days: [
        {
          id: 'day-sprint-001',
          name: 'Sprint Protocol',
          description: '8 rounds of 30s sprint / 90s walk',
          order: 0,
          exercises: [
            { id: uid(), name: 'Treadmill Sprint', sets: 8, durationSeconds: 30, order: 0, tags: ['cardio', 'sprints'], restSeconds: 90, notes: '10mph / 8% incline' },
          ],
        },
      ],
      createdAt: ts(daysAgo(14)),
      updatedAt: ts(daysAgo(14)),
    },
  ];

  const program = {
    id: programId,
    name: 'Morning HIIT Protocol',
    description: '4-week conditioning block to build work capacity and burn fat.',
    createdAt: ts(daysAgo(14)),
    updatedAt: ts(daysAgo(3)),
  };

  return { program, plans };
}

function makeSessions() {
  // 4 completed sessions over the past 2 weeks showing weight progression

  const sessions = [
    {
      id: 'sess-001',
      planId: 'plan-push-001',
      planName: 'Push Day',
      dayId: 'day-push-001',
      dayName: 'Push A',
      startedAt: ts(daysAgo(13)),
      completedAt: ts(new Date(daysAgo(13).getTime() + 65 * 60000)),
      notes: 'Felt strong today. Bench felt smooth.',
      journalEntry: 'Slept 8hrs. Energy was great. Bench moving well — will bump 5lbs next week.',
      entries: [
        {
          id: uid(), exerciseName: 'Barbell Bench Press', order: 0,
          sets: [{ reps: 8, weight: '185 lbs' }, { reps: 8, weight: '185 lbs' }, { reps: 7, weight: '185 lbs' }, { reps: 6, weight: '185 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Overhead Press', order: 1,
          sets: [{ reps: 8, weight: '115 lbs' }, { reps: 8, weight: '115 lbs' }, { reps: 7, weight: '115 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Incline DB Press', order: 2,
          sets: [{ reps: 10, weight: '65 lbs' }, { reps: 10, weight: '65 lbs' }, { reps: 9, weight: '65 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Lateral Raises', order: 3,
          sets: [{ reps: 15, weight: '20 lbs' }, { reps: 15, weight: '20 lbs' }, { reps: 12, weight: '20 lbs' }],
        },
      ],
    },
    {
      id: 'sess-002',
      planId: 'plan-pull-001',
      planName: 'Pull Day',
      dayId: 'day-pull-001',
      dayName: 'Pull A',
      startedAt: ts(daysAgo(11)),
      completedAt: ts(new Date(daysAgo(11).getTime() + 70 * 60000)),
      notes: 'Pull-ups felt heavy. Back pumped up nicely.',
      journalEntry: null,
      entries: [
        {
          id: uid(), exerciseName: 'Barbell Row', order: 0,
          sets: [{ reps: 8, weight: '165 lbs' }, { reps: 8, weight: '165 lbs' }, { reps: 8, weight: '165 lbs' }, { reps: 7, weight: '165 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Pull-Ups', order: 1,
          sets: [{ reps: 7, weight: 'Bodyweight' }, { reps: 6, weight: 'Bodyweight' }, { reps: 5, weight: 'Bodyweight' }],
        },
        {
          id: uid(), exerciseName: 'Cable Row', order: 2,
          sets: [{ reps: 10, weight: '120 lbs' }, { reps: 10, weight: '120 lbs' }, { reps: 10, weight: '120 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Barbell Curl', order: 4,
          sets: [{ reps: 10, weight: '75 lbs' }, { reps: 10, weight: '75 lbs' }, { reps: 8, weight: '75 lbs' }],
        },
      ],
    },
    {
      id: 'sess-003',
      planId: 'plan-push-001',
      planName: 'Push Day',
      dayId: 'day-push-001',
      dayName: 'Push A',
      startedAt: ts(daysAgo(6)),
      completedAt: ts(new Date(daysAgo(6).getTime() + 68 * 60000)),
      notes: 'Hit 190 on bench for the first time. Good progress.',
      journalEntry: 'Bumped bench 5lbs as planned. Got all 4×8. Overhead felt easier too.',
      entries: [
        {
          id: uid(), exerciseName: 'Barbell Bench Press', order: 0,
          // Progress: +5lbs from sess-001
          sets: [{ reps: 8, weight: '190 lbs' }, { reps: 8, weight: '190 lbs' }, { reps: 8, weight: '190 lbs' }, { reps: 7, weight: '190 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Overhead Press', order: 1,
          sets: [{ reps: 8, weight: '120 lbs' }, { reps: 8, weight: '120 lbs' }, { reps: 8, weight: '120 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Incline DB Press', order: 2,
          sets: [{ reps: 10, weight: '70 lbs' }, { reps: 10, weight: '70 lbs' }, { reps: 9, weight: '70 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Lateral Raises', order: 3,
          sets: [{ reps: 15, weight: '20 lbs' }, { reps: 15, weight: '20 lbs' }, { reps: 15, weight: '20 lbs' }],
        },
      ],
    },
    {
      id: 'sess-004',
      planId: 'plan-hiit-am-001',
      planName: 'Morning HIIT Circuit',
      dayId: 'day-hiit-001',
      dayName: 'HIIT Circuit A',
      startedAt: ts(daysAgo(3)),
      completedAt: ts(new Date(daysAgo(3).getTime() + 25 * 60000)),
      notes: 'Cardio felt great. Burpees crushed me as usual.',
      journalEntry: null,
      entries: [
        {
          id: uid(), exerciseName: 'Kettlebell Swing', order: 0,
          sets: [{ reps: 20, weight: '53 lbs' }, { reps: 20, weight: '53 lbs' }, { reps: 20, weight: '53 lbs' }, { reps: 18, weight: '53 lbs' }],
        },
        {
          id: uid(), exerciseName: 'Box Jump', order: 1,
          sets: [{ reps: 10, weight: 'Bodyweight' }, { reps: 10, weight: 'Bodyweight' }, { reps: 10, weight: 'Bodyweight' }, { reps: 8, weight: 'Bodyweight' }],
        },
        {
          id: uid(), exerciseName: 'Burpees', order: 3,
          sets: [{ reps: 12, weight: 'Bodyweight' }, { reps: 10, weight: 'Bodyweight' }, { reps: 9, weight: 'Bodyweight' }, { reps: 8, weight: 'Bodyweight' }],
          notes: 'These are always the worst',
        },
      ],
    },
  ];

  return sessions;
}

// ─── Seed function ────────────────────────────────────────────────────────────

async function seed() {
  const { program: pplProgram, plans: pplPlans } = makePPLProgram();
  const { program: hiitProgram, plans: hiitPlans } = makeHIITProgram();
  const sessions = makeSessions();

  const batch = db.batch();
  const created = [];

  // ── Athlete user document ──
  const athleteRef = db.collection('users').doc(ATHLETE_UID);
  batch.set(athleteRef, {
    uid: ATHLETE_UID,
    displayName: 'Nick (Test)',
    email: 'nick.test@example.com',
    createdAt: ts(daysAgo(25)),
  });
  created.push(`users/${ATHLETE_UID}`);

  // ── Coach user document ──
  const coachRef = db.collection('users').doc(COACH_UID);
  batch.set(coachRef, {
    uid: COACH_UID,
    displayName: 'Coach Sarah (Test)',
    email: 'sarah.test@example.com',
    createdAt: ts(daysAgo(30)),
  });
  created.push(`users/${COACH_UID}`);

  // ── Programs ──
  for (const prog of [pplProgram, hiitProgram]) {
    const ref = db.collection('users').doc(ATHLETE_UID).collection('programs').doc(prog.id);
    const { id, ...data } = prog;
    batch.set(ref, data);
    created.push(`users/${ATHLETE_UID}/programs/${prog.id}`);
  }

  // ── Plans ──
  for (const plan of [...pplPlans, ...hiitPlans]) {
    const ref = db.collection('users').doc(ATHLETE_UID).collection('plans').doc(plan.id);
    const { id, ...data } = plan;
    batch.set(ref, data);
    created.push(`users/${ATHLETE_UID}/plans/${plan.id}`);
  }

  // ── Sessions ──
  for (const session of sessions) {
    const ref = db.collection('users').doc(ATHLETE_UID).collection('sessions').doc(session.id);
    const { id, ...data } = session;
    batch.set(ref, data);
    created.push(`users/${ATHLETE_UID}/sessions/${session.id}`);
  }

  // ── Coach invite (pending invite from athlete) ──
  const inviteRef = db.collection('coachConnections').doc(INVITE_DOC_ID);
  batch.set(inviteRef, {
    ownerUid: ATHLETE_UID,
    ownerName: 'Nick (Test)',
    inviteCode: 'DEMO42',
    type: 'invite',
    status: 'pending',
    createdAt: ts(daysAgo(2)),
  });
  created.push(`coachConnections/${INVITE_DOC_ID}`);

  // ── Active coach connection ──
  const connectionRef = db.collection('coachConnections').doc(CONNECTION_DOC_ID);
  batch.set(connectionRef, {
    ownerUid: ATHLETE_UID,
    ownerName: 'Nick (Test)',
    coachUid: COACH_UID,
    coachName: 'Coach Sarah (Test)',
    type: 'connection',
    status: 'active',
    createdAt: ts(daysAgo(7)),
    connectedAt: ts(daysAgo(7)),
  });
  created.push(`coachConnections/${CONNECTION_DOC_ID}`);

  await batch.commit();

  console.log('\n✅ Seed complete! Created the following documents:\n');
  for (const path of created) {
    console.log(`  /${path}`);
  }
  console.log(`\nTotal: ${created.length} documents\n`);
  console.log('Users:');
  console.log(`  Athlete  uid=${ATHLETE_UID}  "Nick (Test)"`);
  console.log(`  Coach    uid=${COACH_UID}  "Coach Sarah (Test)"`);
  console.log('\nCoach connection:');
  console.log(`  Invite  : /coachConnections/${INVITE_DOC_ID}  (code: DEMO42, status: pending)`);
  console.log(`  Active  : /coachConnections/${CONNECTION_DOC_ID}  (status: active)`);
  console.log('\nAthlete data:');
  console.log('  Programs : Push/Pull/Legs 12-Week, Morning HIIT Protocol');
  console.log('  Plans    : Push Day, Pull Day, Leg Day, Morning HIIT Circuit, Sprint Finisher');
  console.log('  Sessions : 4 completed sessions spanning the past 2 weeks');
  console.log('             (showing bench press progression: 185→190 lbs)\n');
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
