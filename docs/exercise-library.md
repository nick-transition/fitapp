# Global Exercise Library

The global exercise library is a shared, curated catalog of exercises stored
in the top-level `exerciseLibrary` Firestore collection. Any signed-in user
can read it; only admins can write to it. It is the canonical source for
exercise definitions (name, description, video, tags) that workout plans can
reference — per-plan prescription (sets, reps, weight, rest) stays on the
exercise embedded in the plan.

## Data model

`exerciseLibrary/{exerciseId}` (document ID is a slug of the name, e.g.
`barbell-back-squat`):

| Field         | Type              | Notes                                        |
| ------------- | ----------------- | -------------------------------------------- |
| `name`        | string (required) | Display name                                 |
| `description` | string            | Form cues / how to perform                   |
| `videoUrl`    | string            | YouTube or reference link                    |
| `tags`        | array of strings  | Muscle group, equipment, movement pattern    |
| `aliases`     | array of strings  | Alternative names, for search                |
| `createdBy`   | string            | UID (or `seed-script`)                       |
| `createdAt`   | timestamp         |                                              |
| `updatedAt`   | timestamp         |                                              |

Dart model: `lib/models/library_exercise.dart` (`LibraryExercise`).

An embedded plan exercise (`lib/models/exercise.dart`) may carry an optional
`libraryExerciseId` pointing back to its library entry.

## Access control

Rules live in `firestore.rules`:

- **Read**: any authenticated user.
- **Create / update / delete**: only users whose Firebase Auth ID token
  carries the custom claim `admin: true`.

### Granting / revoking the admin claim

```bash
# Against the local Auth emulator (default):
node scripts/set_admin_claim.js grant <uid-or-email>
node scripts/set_admin_claim.js revoke <uid-or-email>

# Against production (needs application-default credentials, e.g.
# `gcloud auth application-default login`):
node scripts/set_admin_claim.js grant <uid-or-email> --prod
```

Custom claims only take effect when the client refreshes its ID token — a
signed-in user may need to sign out and back in (or wait up to an hour) before
the rules see the new claim.

## Seeding

Seed an initial set of common exercises (idempotent — documents are keyed by
name slug and merged on re-run):

```bash
# Local emulator (default):
node scripts/seed_exercise_library.js

# Production:
node scripts/seed_exercise_library.js --prod
```

## Rules tests

Security-rules tests for the collection run against the Firestore emulator:

```bash
npm run test:rules
```

This uses `firebase emulators:exec` to start the emulator, run the node:test
suite in `test/rules/`, and shut everything down.
