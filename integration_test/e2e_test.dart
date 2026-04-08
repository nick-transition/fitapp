import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore;
import 'package:fitapp/firebase_options.dart';
import 'package:fitapp/main.dart';

/// E2E integration tests that run against Firebase emulators.
///
/// Prerequisites:
///   1. Start emulators:  firebase emulators:start
///   2. Seed data:        node scripts/seed_emulator.js
///   3. Run tests (flutter drive -d chrome manages its own chromedriver):
///      flutter drive --driver=test_driver/integration_test.dart \
///        --target=integration_test/e2e_test.dart \
///        --dart-define=USE_EMULATORS=true -d chrome
///
/// To record a video: ./scripts/run_e2e_video.sh
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Whether to add pauses between steps for video recording.
  /// Set via --dart-define=RECORD_VIDEO=true
  const recordVideo = bool.fromEnvironment('RECORD_VIDEO');

  /// Pause briefly so the screen recording can capture the current state.
  Future<void> hold(WidgetTester tester) async {
    if (!recordVideo) return;
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
    await FirebaseAuth.instance.signOut();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> signIn(
      WidgetTester tester, String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Athlete walkthrough — single test for continuous video
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Athlete e2e walkthrough', (tester) async {
    // 1. Marketing screen (unauthenticated)
    await FirebaseAuth.instance.signOut();
    await pumpApp(tester);
    expect(find.text('Get Started'), findsOneWidget);
    await hold(tester);

    // 2. Sign in → HomeScreen with Programs tab
    await signIn(tester, 'testuser@gmail.com', 'testpass123');
    expect(find.text('FitApp'), findsOneWidget);
    expect(find.text('Programs'), findsOneWidget);
    expect(find.text('4-Day Strength & Conditioning'), findsOneWidget);
    await hold(tester);

    // 3. Tap program → ProgramDetailScreen with workouts
    await tester.tap(find.text('4-Day Strength & Conditioning'));
    await tester.pumpAndSettle();
    expect(find.text('Workouts in this Program'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('HIIT Cardio'), findsOneWidget);
    await hold(tester);

    // 4. Back to home
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 5. Workouts tab
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('HIIT Cardio'), findsOneWidget);
    await hold(tester);

    // 6. Expand Push Day → exercises + video icon
    await tester.tap(find.text('Push Day'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bench Press'), findsWidgets);
    expect(find.textContaining('Overhead Press'), findsOneWidget);
    expect(find.textContaining('Tricep Pushdown'), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    await hold(tester);

    // 7. Calendar tab
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    await hold(tester);

    // 8. Sessions tab
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
    expect(find.text('4-Day Strength & Conditioning'), findsWidgets);
    await hold(tester);

    // Sign out
    await FirebaseAuth.instance.signOut();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Coach walkthrough
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Coach e2e walkthrough', (tester) async {
    await pumpApp(tester);
    await signIn(tester, 'coach@gmail.com', 'coachpass123');

    // 1. Coach home
    expect(find.text('FitApp'), findsOneWidget);
    await hold(tester);

    // 2. Coach Sharing screen
    await tester.tap(find.byTooltip('Coach Sharing'));
    await tester.pumpAndSettle();
    expect(find.text('Coach Sharing'), findsOneWidget);
    await hold(tester);

    // 3. My Athletes tab → see connected athlete
    await tester.tap(find.text('My Athletes'));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);
    await hold(tester);

    // 4. Tap athlete → AthleteDetailScreen with programs
    await tester.tap(find.text('Test User'));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('4-Day Strength & Conditioning'), findsOneWidget);
    await hold(tester);

    // 4b. Expand program → workouts load
    await tester.tap(find.text('4-Day Strength & Conditioning'));
    await tester.pumpAndSettle();
    expect(find.text('Push Day'), findsOneWidget);
    await hold(tester);

    // 4c. Expand Push Day → exercises with inline video tile
    await tester.tap(find.text('Push Day'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bench Press'), findsWidgets);
    expect(find.text('Watch reference video'), findsOneWidget);
    await hold(tester);

    // 4d. On web, video auto-expands — verify subtitle shows "Reference video"
    expect(find.text('Reference video'), findsOneWidget);
    await hold(tester);

    // 5. Athlete Workouts tab
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    await hold(tester);

    // 6. Athlete Sessions tab
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
    expect(find.text('4-Day Strength & Conditioning'), findsWidgets);
    await hold(tester);

    await FirebaseAuth.instance.signOut();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  // Sign out after all tests
  tearDown(() async {
    await FirebaseAuth.instance.signOut();
  });
}
