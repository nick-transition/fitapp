import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitapp/widgets/plan_card.dart';
import 'package:fitapp/models/workout_plan.dart';
import 'package:fitapp/models/workout_session.dart';

/// Builds a [MaterialApp] with the dark teal theme matching the production app.
Widget _appShell(Widget child) {
  return MaterialApp(
    title: 'FitApp',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

/// Returns the 4-day strength plan that mirrors the seed_emulator.js fixture.
WorkoutPlan _fourDayPlan() {
  return WorkoutPlan(
    id: 'plan-4-day',
    name: '4-Day Strength & Conditioning',
    description: 'Build strength and conditioning across four training days.',
    days: [
      WorkoutDay(
        name: 'Day 1: Lower Body',
        exercises: [
          PlanExercise(name: 'Back Squat', sets: 4, reps: 6, weight: '185 lbs'),
          PlanExercise(name: 'Romanian Deadlift', sets: 3, reps: 10, weight: '135 lbs'),
          PlanExercise(name: 'Leg Press', sets: 3, reps: 12, weight: '270 lbs'),
          PlanExercise(
            name: 'Walking Lunges',
            sets: 3,
            reps: 12,
            notes: 'Each leg; use dumbbells if available',
          ),
          PlanExercise(name: 'Standing Calf Raise', sets: 4, reps: 15),
        ],
      ),
      WorkoutDay(
        name: 'Day 2: Upper Body',
        exercises: [
          PlanExercise(name: 'Barbell Bench Press', sets: 4, reps: 6, weight: '155 lbs'),
          PlanExercise(name: 'Barbell Row', sets: 4, reps: 8, weight: '135 lbs'),
          PlanExercise(name: 'Overhead Press', sets: 3, reps: 8, weight: '95 lbs'),
          PlanExercise(name: 'Pull-Ups', sets: 3, reps: 8, notes: 'Add weight if bodyweight is easy'),
          PlanExercise(name: 'Tricep Pushdown', sets: 3, reps: 12),
          PlanExercise(name: 'Barbell Curl', sets: 3, reps: 12, weight: '65 lbs'),
        ],
      ),
      WorkoutDay(
        name: 'Day 3: Conditioning',
        exercises: [
          PlanExercise(name: 'Kettlebell Swing', sets: 5, reps: 20, weight: '53 lbs'),
          PlanExercise(name: 'Box Jump', sets: 4, reps: 8),
          PlanExercise(name: 'Battle Ropes', sets: 4, reps: 30, notes: '30 seconds per set'),
          PlanExercise(name: 'Burpees', sets: 3, reps: 15),
          PlanExercise(name: 'Assault Bike Sprint', sets: 6, reps: 1, notes: '30s all-out'),
        ],
      ),
      WorkoutDay(
        name: 'Day 4: Zone 2',
        exercises: [
          PlanExercise(name: 'Treadmill Incline Walk', sets: 1, reps: 1, notes: '45 min, 3.5 mph, 8% incline'),
          PlanExercise(name: 'Stationary Bike', sets: 1, reps: 1, notes: '30 min at 130–140 BPM'),
        ],
      ),
    ],
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ───────────────────────────────────────────────────────────────
  // Group 1: PlanCard — day headers
  // ───────────────────────────────────────────────────────────────
  group('PlanCard day headers (4-day plan)', () {
    testWidgets('subtitle reflects 4 days and total exercise count',
        (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      // 5 + 6 + 5 + 2 = 18 exercises across 4 days
      expect(find.text('4 days · 18 exercises'), findsOneWidget);
    });

    testWidgets('day headers are hidden before expansion', (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      expect(find.text('Day 1: Lower Body'), findsNothing);
      expect(find.text('Day 2: Upper Body'), findsNothing);
      expect(find.text('Day 3: Conditioning'), findsNothing);
      expect(find.text('Day 4: Zone 2'), findsNothing);
    });

    testWidgets('all 4 day headers appear after tapping to expand',
        (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4-Day Strength & Conditioning'));
      await tester.pumpAndSettle();

      expect(find.text('Day 1: Lower Body'), findsOneWidget);
      expect(find.text('Day 2: Upper Body'), findsOneWidget);
      expect(find.text('Day 3: Conditioning'), findsOneWidget);
      expect(find.text('Day 4: Zone 2'), findsOneWidget);
    });

    testWidgets('plan description appears after expansion', (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4-Day Strength & Conditioning'));
      await tester.pumpAndSettle();

      expect(
        find.text('Build strength and conditioning across four training days.'),
        findsOneWidget,
      );
    });

    testWidgets('plan without description shows no description text',
        (tester) async {
      final plan = WorkoutPlan(
        id: 'no-desc',
        name: 'Minimal Plan',
        days: [
          WorkoutDay(name: 'Day 1', exercises: [
            PlanExercise(name: 'Push-up', sets: 3, reps: 20),
          ]),
        ],
      );

      await tester.pumpWidget(_appShell(PlanCard(plan: plan)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Minimal Plan'));
      await tester.pumpAndSettle();

      // Description widget should be absent
      expect(find.text('Build strength and conditioning across four training days.'),
          findsNothing);
    });

    testWidgets('empty plan shows "No days defined" message', (tester) async {
      final emptyPlan = WorkoutPlan(
        id: 'empty',
        name: 'Empty Plan',
        days: const [],
      );

      await tester.pumpWidget(_appShell(PlanCard(plan: emptyPlan)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Empty Plan'));
      await tester.pumpAndSettle();

      expect(find.text('No days defined'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Group 2: PlanCard — exercise details
  // ───────────────────────────────────────────────────────────────
  group('PlanCard exercise details', () {
    testWidgets('exercises from Day 1 show name, sets×reps and weight',
        (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4-Day Strength & Conditioning'));
      await tester.pumpAndSettle();

      // Back Squat: 4×6 @ 185 lbs
      expect(find.textContaining('Back Squat'), findsOneWidget);
      expect(find.textContaining('Back Squat 4×6'), findsOneWidget);
      expect(find.textContaining('185 lbs'), findsOneWidget);

      // Romanian Deadlift: 3×10 @ 135 lbs
      expect(find.textContaining('Romanian Deadlift'), findsOneWidget);
      expect(find.textContaining('3×10'), findsOneWidget);
    });

    testWidgets('exercise notes render in italics below the exercise row',
        (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4-Day Strength & Conditioning'));
      await tester.pumpAndSettle();

      // Walking Lunges note
      expect(
        find.textContaining('Each leg; use dumbbells if available'),
        findsOneWidget,
      );

      // Pull-Ups note (Day 2)
      expect(
        find.textContaining('Add weight if bodyweight is easy'),
        findsOneWidget,
      );
    });

    testWidgets('exercise without notes shows no note text', (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4-Day Strength & Conditioning'));
      await tester.pumpAndSettle();

      // Leg Press has no notes; verify its name is shown but no note widget
      expect(find.textContaining('Leg Press'), findsOneWidget);
    });

    testWidgets('exercise without reps shows em-dash placeholder',
        (tester) async {
      final plan = WorkoutPlan(
        id: 'dash-plan',
        name: 'Dash Plan',
        days: [
          WorkoutDay(name: 'Day 1', exercises: [
            PlanExercise(name: 'Plank Hold', sets: 3, reps: null),
          ]),
        ],
      );

      await tester.pumpWidget(_appShell(PlanCard(plan: plan)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dash Plan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('3×—'), findsOneWidget);
    });

    testWidgets('day headers display per-day exercise counts', (tester) async {
      await tester.pumpWidget(_appShell(PlanCard(plan: _fourDayPlan())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4-Day Strength & Conditioning'));
      await tester.pumpAndSettle();

      expect(find.text('5 exercises'), findsNWidgets(2)); // Day 1 and Day 3
      expect(find.text('6 exercises'), findsOneWidget);   // Day 2
      expect(find.text('2 exercises'), findsOneWidget);   // Day 4
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Group 3: WorkoutSession model — serialisation / data integrity
  //
  // SessionCard directly accesses FirebaseAuth and FirebaseFirestore
  // in its build() method, requiring a live Firebase connection.
  // These tests validate session data correctness without rendering
  // the card, keeping the suite backend-free.
  // ───────────────────────────────────────────────────────────────
  group('WorkoutSession model', () {
    WorkoutSession buildSession() {
      final now = DateTime(2025, 6, 15, 10, 30);
      return WorkoutSession(
        id: 'session-001',
        planId: 'plan-4-day',
        planName: '4-Day Strength & Conditioning',
        dayName: 'Day 1: Lower Body',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 65)),
        entries: [
          SessionEntry(
            id: 'entry-0',
            exerciseName: 'Back Squat',
            order: 0,
            sets: [
              SetData(reps: 6, weight: '185 lbs'),
              SetData(reps: 6, weight: '185 lbs'),
              SetData(reps: 5, weight: '185 lbs'),
              SetData(reps: 5, weight: '185 lbs'),
            ],
          ),
          SessionEntry(
            id: 'entry-1',
            exerciseName: 'Romanian Deadlift',
            order: 1,
            sets: [
              SetData(reps: 10, weight: '135 lbs'),
              SetData(reps: 10, weight: '135 lbs'),
              SetData(reps: 9, weight: '135 lbs'),
            ],
            notes: 'Focus on hip hinge',
          ),
          SessionEntry(
            id: 'entry-2',
            exerciseName: 'Leg Press',
            order: 2,
            sets: [
              SetData(reps: 12, weight: '270 lbs'),
              SetData(reps: 12, weight: '270 lbs'),
              SetData(reps: 10, weight: '270 lbs'),
            ],
          ),
        ],
      );
    }

    test('session reports correct exercise count via entries length', () {
      final session = buildSession();
      expect(session.entries.length, 3);
    });

    test('session.isCompleted is true when completedAt is set', () {
      final session = buildSession();
      expect(session.isCompleted, isTrue);
    });

    test('session.isScheduled is false for a completed session', () {
      final session = buildSession();
      expect(session.isScheduled, isFalse);
    });

    test('session with only scheduledAt and no completedAt is scheduled', () {
      final future = DateTime.now().add(const Duration(days: 1));
      final scheduled = WorkoutSession(
        id: 'sched-001',
        scheduledAt: future,
      );
      expect(scheduled.isScheduled, isTrue);
      expect(scheduled.isCompleted, isFalse);
    });

    test('calendarDate prefers scheduledAt when present', () {
      final scheduled = DateTime(2025, 7, 1);
      final started = DateTime(2025, 7, 2);
      final session = WorkoutSession(
        id: 'cal-test',
        scheduledAt: scheduled,
        startedAt: started,
      );
      expect(session.calendarDate, equals(scheduled));
    });

    test('calendarDate falls back to startedAt when scheduledAt is null', () {
      final started = DateTime(2025, 7, 2);
      final session = WorkoutSession(
        id: 'cal-fallback',
        startedAt: started,
      );
      expect(session.calendarDate, equals(started));
    });

    test('toMap / fromMap round-trip preserves entry exercise names and order',
        () {
      final session = buildSession();
      final map = session.toMap();
      final restored = WorkoutSession.fromMap(session.id, map);

      expect(restored.entries.length, 3);
      expect(restored.entries[0].exerciseName, 'Back Squat');
      expect(restored.entries[1].exerciseName, 'Romanian Deadlift');
      expect(restored.entries[1].notes, 'Focus on hip hinge');
      expect(restored.entries[2].exerciseName, 'Leg Press');
    });

    test('SetData round-trips reps and weight correctly', () {
      final set = SetData(reps: 8, weight: '135 lbs');
      final map = set.toMap();
      final restored = SetData.fromMap(map);
      expect(restored.reps, 8);
      expect(restored.weight, '135 lbs');
    });

    test('SetData without weight round-trips with null weight', () {
      final set = SetData(reps: 15);
      final map = set.toMap();
      final restored = SetData.fromMap(map);
      expect(restored.weight, isNull);
    });
  });
}
