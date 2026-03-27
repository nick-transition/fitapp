/**
 * migrate_data.js
 *
 * Migrates "Plans" (plans collection) to "Workouts" (workouts collection).
 * Flattens the "days" structure into a single "exercises" list for each workout.
 * Updates programs to include workoutIds.
 *
 * Run from the project root:
 *   node scripts/migrate_data.js
 */

const admin = require('../functions/node_modules/firebase-admin');

// IMPORTANT: Set this to false or empty string to run against production!
const USE_EMULATOR = process.env.FIRESTORE_EMULATOR_HOST || '';
if (USE_EMULATOR) {
  process.env.FIRESTORE_EMULATOR_HOST = USE_EMULATOR;
  console.log('Using emulator:', USE_EMULATOR);
  admin.initializeApp({ projectId: 'fitapp-ns' });
} else {
  console.log('--- RUNNING ON PRODUCTION FIRESTORE ---');
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'fitapp-ns'
  });
}
const db = admin.firestore();

async function migrate() {
  console.log('Starting migration...');

  // Try finding plans via collectionGroup to ensure we catch everything
  console.log('Searching for plans via collectionGroup...');
  const allPlansSnap = await db.collectionGroup('plans').get();
  console.log(`Found ${allPlansSnap.size} total plans across all users.`);

  if (allPlansSnap.size === 0) {
    console.log('No plans found. Check if the project ID or database is correct.');
    return;
  }

  const plansByUser = {};
  for (const planDoc of allPlansSnap.docs) {
    const userRef = planDoc.ref.parent.parent;
    if (userRef && userRef.parent.id === 'users') {
      const uid = userRef.id;
      if (!plansByUser[uid]) plansByUser[uid] = [];
      plansByUser[uid].push(planDoc);
    } else {
      console.warn(`Skipping plan ${planDoc.id} as it's not under a user.`);
    }
  }

  for (const [uid, planDocs] of Object.entries(plansByUser)) {
    console.log(`Migrating data for user: ${uid} (${planDocs.length} plans)`);
    const programWorkoutsMap = {};

    for (const planDoc of planDocs) {
      const planData = planDoc.data();
      const planId = planDoc.id;

      // Flatten days into exercises
      let exercises = [];
      if (planData.days && Array.isArray(planData.days)) {
        // Sort days by order if available
        const sortedDays = planData.days.sort((a, b) => (a.order || 0) - (b.order || 0));
        for (const day of sortedDays) {
          if (day.exercises && Array.isArray(day.exercises)) {
            for (const ex of day.exercises) {
              exercises.push({
                id: ex.id || `ex_${exercises.length}_${Date.now()}`,
                name: ex.name || 'Untitled Exercise',
                sets: ex.sets || 0,
                reps: ex.reps || null,
                weight: ex.weight || null,
                notes: ex.notes || null,
                videoUrl: ex.videoUrl || null,
                order: exercises.length,
              });
            }
          }
        }
      }

      const workoutData = {
        name: planData.name || 'Untitled Workout',
        description: planData.description || '',
        videoUrl: planData.videoUrl || null,
        type: planData.type || 'custom',
        programId: planData.programId || null,
        schedule: planData.schedule || null,
        exercises: exercises,
        createdAt: planData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: planData.updatedAt || admin.firestore.FieldValue.serverTimestamp(),
      };

      // Create new workout doc
      await db.collection('users').doc(uid).collection('workouts').doc(planId).set(workoutData);
      console.log(`    Migrated plan ${planId} ("${workoutData.name}") to workout with ${exercises.length} exercises.`);

      if (planData.programId) {
        if (!programWorkoutsMap[planData.programId]) {
          programWorkoutsMap[planData.programId] = [];
        }
        programWorkoutsMap[planData.programId].push(planId);
      }
    }

    // 2. Update programs with workoutIds
    for (const [programId, workoutIds] of Object.entries(programWorkoutsMap)) {
      try {
        await db.collection('users').doc(uid).collection('programs').doc(programId).update({
          workoutIds: admin.firestore.FieldValue.arrayUnion(...workoutIds),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`    Updated program ${programId} with ${workoutIds.length} workouts.`);
      } catch (e) {
        console.error(`    Failed to update program ${programId}: ${e.message}`);
      }
    }
  }

  console.log('\n✅ Migration complete!');
}

migrate().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
