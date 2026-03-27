// integration_test/app_test.dart
//
// End-to-end integration tests for FitApp.
// Requires Firebase emulators running on localhost:9099 (auth) and localhost:8081 (firestore).
//
// Run locally:
//   firebase emulators:start --only auth,firestore --project fitapp-ns &
//   flutter test integration_test/app_test.dart -d chrome
//
// Or against a connected device:
//   flutter test integration_test/app_test.dart -d <device-id>

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitapp/firebase_options.dart';
import 'package:fitapp/models/workout_plan.dart';
import 'package:fitapp/screens/home_screen.dart';
import 'package:fitapp/widgets/plan_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const _testEmail = 'integration-test@fitapp.test';
const _testPassword = 'IntegrationTest123!';
const _planDocId = 'test-plan-e2e-001';
const _sessionDocId = 'test-session-e2e-001';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Creates the test user on the Auth emulator (or signs in if it already exists).
/// Returns the user's UID so Firestore documents can be scoped to it.
Future<String> _getOrCreateTestUser() async {
  try {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _testEmail,
      password: _testPassword,
    );
    return cred.user!.uid;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _testEmail,
        password: _testPassword,
      );
      return cred.user!.uid;
    }
    rethrow;
  }
}

/// Seeds a 4-day workout plan into the Firestore emulator under the given UID.
Future<void> _seedPlan(String uid) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('plans')
      .doc(_planDocId)
      .set({
    'name': '4-Day Strength & Conditioning',
    'description':
        'Full-body strength block with conditioning and aerobic work.',
    'days': [
      {
        'name': 'Lower Body',
        'exercises': [
          {
            'name': 'Back Squat',
            'sets': 4,
            'reps': 6,
            'weight': '225 lbs',
            'notes': 'Belt up on sets 3–4',
          },
          {
            'name': 'Romanian Deadlift',
            'sets': 3,
            'reps': 8,
            'weight': '185 lbs',
          },
        ],
      },
      {
        'name': 'Upper Body',
        'exercises': [
          {
            'name': 'Barbell Bench Press',
            'sets': 4,
            'reps': 8,
            'weight': '185 lbs',
            'videoUrl': 'https://www.youtube.com/watch?v=vcBig73ojpE',
          },
          {
            'name': 'Barbell Row',
            'sets': 4,
            'reps': 8,
            'weight': '165 lbs',
          },
        ],
      },
      {
        'name': 'Conditioning',
        'exercises': [
          {
            'name': 'Kettlebell Swing',
            'sets': 4,
            'reps': 20,
            'weight': '53 lbs',
          },
          {
            'name': 'Box Jump',
            'sets': 4,
            'reps': 10,
            'weight': 'Bodyweight',
            'notes': '24" box',
          },
        ],
      },
      {
        'name': 'Zone 2',
        'exercises': [
          {
            'name': 'Treadmill Incline Walk',
            'sets': 1,
            'reps': null,
            'notes': '3.5 mph / 8% incline — 40 min',
          },
        ],
      },
    ],
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
  });
}

/// Seeds a completed workout session plus its entries subcollection.
Future<void> _seedSession(String uid) async {
  final sessionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('sessions')
      .doc(_sessionDocId);

  await sessionRef.set({
    'planName': '4-Day Strength & Conditioning',
    'dayName': 'Lower Body',
    'startedAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 25)),
    ),
    'completedAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    ),
    'notes': 'Felt strong today',
    'entries': [],
  });

  // Seed entries as a subcollection — SessionCard reads these for the
  // exercise-count chip.
  await sessionRef.collection('entries').doc('e1').set({
    'exerciseName': 'Back Squat',
    'sets': [
      {'reps': 6, 'weight': '225 lbs'}
    ],
    'order': 0,
  });
  await sessionRef.collection('entries').doc('e2').set({
    'exerciseName': 'Romanian Deadlift',
    'sets': [
      {'reps': 8, 'weight': '185 lbs'}
    ],
    'order': 1,
  });
}

/// Minimal MaterialApp wrapper that mirrors main.dart's theme.
MaterialApp _testApp(Widget home) => MaterialApp(
      title: 'FitApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
      ),
      home: home,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String testUid = '';

  setUpAll(() async {
    // Initialise Firebase once; guard against re-init if another test file ran
    // first in the same process.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Point both SDKs at the local emulators.  The try/catch guards against
    // "already configured" errors when tests are re-run in the same process.
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (_) {}
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
    } catch (_) {}

    // Create (or sign in as) the test user and seed data under their UID.
    testUid = await _getOrCreateTestUser();
    await _seedPlan(testUid);
    await _seedSession(testUid);
  });

  tearDownAll(() async {
    await FirebaseAuth.instance.signOut();
  });

  // ── Group 1: Plan card day headers (Issue #1) ─────────────────────────────

  group('Plan card — day headers (Issue #1)', () {
    testWidgets(
        'all four day names are hidden when collapsed and visible after expand',
        (tester) async {
      // Load the seeded plan directly from Firestore.
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(testUid)
          .collection('plans')
          .doc(_planDocId)
          .get();

      final plan = WorkoutPlan.fromMap(snap.id, snap.data()!);

      await tester.pumpWidget(
        _testApp(Scaffold(body: ListView(children: [PlanCard(plan: plan)]))),
      );
      await tester.pumpAndSettle();

      // Collapsed state: day headers must not be visible yet.
      expect(find.text('Lower Body'), findsNothing);
      expect(find.text('Upper Body'), findsNothing);
      expect(find.text('Conditioning'), findsNothing);
      expect(find.text('Zone 2'), findsNothing);

      // Expand the card by tapping the ExpansionTile header.
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // All four day-header labels must now be visible.
      expect(find.text('Lower Body'), findsOneWidget);
      expect(find.text('Upper Body'), findsOneWidget);
      expect(find.text('Conditioning'), findsOneWidget);
      expect(find.text('Zone 2'), findsOneWidget);
    });

    testWidgets('subtitle shows correct day count and total exercise count',
        (tester) async {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(testUid)
          .collection('plans')
          .doc(_planDocId)
          .get();

      final plan = WorkoutPlan.fromMap(snap.id, snap.data()!);

      await tester.pumpWidget(
        _testApp(Scaffold(body: ListView(children: [PlanCard(plan: plan)]))),
      );
      await tester.pumpAndSettle();

      // 4 days, 7 exercises total (2 + 2 + 2 + 1).
      expect(find.textContaining('4 days'), findsOneWidget);
      expect(find.textContaining('7 exercises'), findsOneWidget);
    });
  });

  // ── Group 2: Plan card exercise details ───────────────────────────────────

  group('Plan card — exercise details', () {
    testWidgets('exercise names, sets×reps, and coaching notes appear',
        (tester) async {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(testUid)
          .collection('plans')
          .doc(_planDocId)
          .get();

      final plan = WorkoutPlan.fromMap(snap.id, snap.data()!);

      await tester.pumpWidget(
        _testApp(Scaffold(body: ListView(children: [PlanCard(plan: plan)]))),
      );
      await tester.pumpAndSettle();

      // Expand.
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Exercise row: "• Back Squat  4×6 @ 225 lbs"
      expect(find.textContaining('Back Squat'), findsOneWidget);
      expect(find.textContaining('4×6'), findsOneWidget);

      // Coaching note rendered as separate italic Text widget.
      expect(find.text('Belt up on sets 3–4'), findsOneWidget);

      // Upper Body exercise.
      expect(find.textContaining('Barbell Bench Press'), findsOneWidget);
    });

    testWidgets('each day header is followed by its exercise rows',
        (tester) async {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(testUid)
          .collection('plans')
          .doc(_planDocId)
          .get();

      final plan = WorkoutPlan.fromMap(snap.id, snap.data()!);

      await tester.pumpWidget(
        _testApp(Scaffold(body: ListView(children: [PlanCard(plan: plan)]))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Exercises from every day must all be present.
      expect(find.textContaining('Romanian Deadlift'), findsOneWidget);
      expect(find.textContaining('Barbell Row'), findsOneWidget);
      expect(find.textContaining('Kettlebell Swing'), findsOneWidget);
      expect(find.textContaining('Treadmill Incline Walk'), findsOneWidget);
    });
  });

  // ── Group 3: Sessions tab ─────────────────────────────────────────────────

  group('Sessions tab', () {
    testWidgets('seeded session card shows plan name', (tester) async {
      await tester.pumpWidget(_testApp(const HomeScreen()));
      // Allow the initial Firestore streams (Programs, Workouts) to settle.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to the Sessions tab (index 3).
      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The session card title must match the seeded plan name.
      expect(find.textContaining('4-Day Strength'), findsOneWidget);
    });

    testWidgets('session card shows formatted date', (tester) async {
      await tester.pumpWidget(_testApp(const HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // SessionCard._formatDate produces e.g. "Mar 26, 2026 at 11:00 AM".
      // Check that at least a year string is present (stable across time zones).
      expect(find.textContaining('202'), findsWidgets);
    });
  });

  // ── Group 4: Coach sharing screen ────────────────────────────────────────

  group('Coach sharing screen', () {
    testWidgets('opens from app bar people icon', (tester) async {
      await tester.pumpWidget(_testApp(const HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap the Coach Sharing icon in the HomeScreen AppBar.
      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      // AppBar title confirms we navigated to CoachScreen.
      expect(find.text('Coach Sharing'), findsOneWidget);
    });

    testWidgets('Coach Sharing screen has Share My Data and My Athletes tabs',
        (tester) async {
      await tester.pumpWidget(_testApp(const HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      expect(find.text('Share My Data'), findsOneWidget);
      expect(find.text('My Athletes'), findsOneWidget);
    });
  });
}
