/**
 * seed_exercise_library.js
 *
 * Seeds the global exercise library (/exerciseLibrary) with an initial set
 * of common exercises. Uses the Admin SDK, so it bypasses security rules —
 * the admin custom claim is only required for client writes.
 *
 * Run from the project root against the local emulator (default):
 *   node scripts/seed_exercise_library.js
 *
 * Against production (requires application-default credentials):
 *   node scripts/seed_exercise_library.js --prod
 *
 * Idempotent: entries are keyed by a slug of their name, so re-running
 * updates in place rather than duplicating.
 */

// firebase-admin lives in functions/node_modules
const admin = require('../functions/node_modules/firebase-admin');

const prod = process.argv.includes('--prod');
if (!prod) {
  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8081';
}

admin.initializeApp({ projectId: 'fitapp-ns' });

const db = admin.firestore();

const EXERCISES = [
  {
    name: 'Barbell Back Squat',
    description:
      'Barbell across the upper back; squat until thighs are at least parallel, then drive up through the heels. Keep the chest up and knees tracking over the toes.',
    tags: ['legs', 'quads', 'glutes', 'barbell', 'compound'],
    aliases: ['back squat', 'squat'],
  },
  {
    name: 'Barbell Deadlift',
    description:
      'Hinge at the hips with a flat back and pull the bar from the floor to lockout. Brace the core and keep the bar close to the body.',
    tags: ['posterior chain', 'hamstrings', 'glutes', 'back', 'barbell', 'compound'],
    aliases: ['deadlift', 'conventional deadlift'],
  },
  {
    name: 'Barbell Bench Press',
    description:
      'Lying on a flat bench, lower the bar to mid-chest and press to lockout. Keep shoulder blades retracted and feet planted.',
    tags: ['chest', 'triceps', 'shoulders', 'barbell', 'compound'],
    aliases: ['bench press', 'flat bench'],
  },
  {
    name: 'Overhead Press',
    description:
      'Standing, press the bar from the front rack position to overhead lockout. Squeeze the glutes to avoid arching the lower back.',
    tags: ['shoulders', 'triceps', 'barbell', 'compound'],
    aliases: ['ohp', 'military press', 'strict press'],
  },
  {
    name: 'Pull-Up',
    description:
      'From a dead hang with an overhand grip, pull until the chin clears the bar. Control the descent.',
    tags: ['back', 'lats', 'biceps', 'bodyweight', 'compound'],
    aliases: ['pullup', 'chin over bar'],
  },
  {
    name: 'Barbell Bent-Over Row',
    description:
      'Hinge to roughly 45 degrees and row the bar to the lower ribs. Keep the back flat and avoid using momentum.',
    tags: ['back', 'lats', 'biceps', 'barbell', 'compound'],
    aliases: ['bent over row', 'barbell row'],
  },
  {
    name: 'Romanian Deadlift',
    description:
      'With a slight knee bend, hinge at the hips lowering the bar down the thighs until a hamstring stretch, then return to standing.',
    tags: ['hamstrings', 'glutes', 'posterior chain', 'barbell'],
    aliases: ['rdl'],
  },
  {
    name: 'Dumbbell Lunge',
    description:
      'Holding dumbbells at the sides, step forward and lower until both knees are at 90 degrees, then push back to standing. Alternate legs.',
    tags: ['legs', 'quads', 'glutes', 'dumbbell', 'unilateral'],
    aliases: ['walking lunge', 'forward lunge'],
  },
  {
    name: 'Dumbbell Shoulder Press',
    description:
      'Seated or standing, press dumbbells from shoulder height to overhead. Keep the core braced and avoid flaring the ribs.',
    tags: ['shoulders', 'triceps', 'dumbbell'],
    aliases: ['db shoulder press', 'seated dumbbell press'],
  },
  {
    name: 'Dumbbell Biceps Curl',
    description:
      'Curl the dumbbells with elbows pinned to the sides; control the lowering phase. Avoid swinging.',
    tags: ['biceps', 'arms', 'dumbbell', 'isolation'],
    aliases: ['bicep curl', 'db curl'],
  },
  {
    name: 'Plank',
    description:
      'Forearms and toes on the floor, body in a straight line from head to heels. Brace the core and breathe.',
    tags: ['core', 'abs', 'bodyweight', 'isometric'],
    aliases: ['front plank', 'forearm plank'],
  },
  {
    name: 'Push-Up',
    description:
      'Hands under shoulders, body in a straight line; lower the chest to the floor and press back up.',
    tags: ['chest', 'triceps', 'core', 'bodyweight'],
    aliases: ['pushup', 'press-up'],
  },
  {
    name: 'Kettlebell Swing',
    description:
      'Hinge and swing the kettlebell to chest height using hip drive, not the arms. Snap the hips at the top.',
    tags: ['posterior chain', 'glutes', 'conditioning', 'kettlebell'],
    aliases: ['kb swing', 'russian swing'],
  },
  {
    name: 'Lat Pulldown',
    description:
      'Seated at the cable stack, pull the bar to the upper chest with a slight lean back. Control the return.',
    tags: ['back', 'lats', 'biceps', 'cable', 'machine'],
    aliases: ['pulldown'],
  },
  {
    name: 'Leg Press',
    description:
      'Press the sled away until the legs are extended without locking the knees; lower under control until knees reach ~90 degrees.',
    tags: ['legs', 'quads', 'glutes', 'machine'],
    aliases: [],
  },
  {
    name: 'Burpee',
    description:
      'From standing, drop to a push-up, return to the feet, and jump. A full-body conditioning movement.',
    tags: ['conditioning', 'full body', 'bodyweight', 'cardio'],
    aliases: [],
  },
];

const slug = (name) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');

async function seed() {
  console.log(
    `Seeding ${EXERCISES.length} exercises into /exerciseLibrary on ${
      prod ? 'PRODUCTION' : 'the Firestore emulator'
    }...`
  );

  const batch = db.batch();
  for (const exercise of EXERCISES) {
    const ref = db.collection('exerciseLibrary').doc(slug(exercise.name));
    batch.set(
      ref,
      {
        ...exercise,
        videoUrl: exercise.videoUrl || null,
        createdBy: 'seed-script',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
  await batch.commit();

  console.log('Done.');
  process.exit(0);
}

seed().catch((e) => {
  console.error('Seed failed:', e);
  process.exit(1);
});
