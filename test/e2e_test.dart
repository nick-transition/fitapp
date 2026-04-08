import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/models/workout.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/widgets/workout_card.dart';
import 'package:fitapp/widgets/session_card.dart';
import 'package:fitapp/widgets/exercise_card.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

final _workouts = [
  Workout(
    id: 'workout-1',
    name: 'Push Day',
    description: 'Focusing on compound movements',
    type: 'strength',
    schedule: 'Mon',
    exercises: [],
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 15),
  ),
  Workout(
    id: 'workout-2',
    name: 'HIIT Cardio',
    description: 'High intensity interval training for fat loss',
    type: 'cardio',
    schedule: 'Tue',
    exercises: [],
    createdAt: DateTime(2026, 3, 5),
    updatedAt: DateTime(2026, 3, 14),
  ),
  Workout(
    id: 'workout-3',
    name: '5x5 Stronglifts',
    type: 'strength',
    exercises: [],
    createdAt: DateTime(2026, 3, 10),
    updatedAt: DateTime(2026, 3, 10),
  ),
];

final _pushDayExercises = [
  Exercise(
    id: 'ex-1',
    name: 'Bench Press',
    sets: 4,
    reps: 8,
    weight: '80 lbs',
    order: 0,
  ),
  Exercise(
    id: 'ex-2',
    name: 'Shoulder Press',
    sets: 3,
    reps: 10,
    weight: '40 lbs',
    order: 1,
  ),
  Exercise(
    id: 'ex-3',
    name: 'Tricep Pushdown',
    sets: 3,
    reps: 12,
    weight: '25 lbs',
    order: 2,
  ),
];

final _sessions = [
  WorkoutSession(
    id: 'session-1',
    planId: 'workout-1',
    planName: 'Push Day',
    startedAt: DateTime(2026, 3, 16, 10, 0),
    completedAt: DateTime(2026, 3, 16, 11, 0),
    notes: 'Feeling strong today',
    journalEntry: 'Good session, upped weight on bench.',
  ),
  WorkoutSession(
    id: 'session-2',
    planId: 'workout-2',
    planName: 'HIIT Cardio',
    startedAt: DateTime(2026, 3, 17, 17, 30),
    completedAt: DateTime(2026, 3, 17, 18, 0),
  ),
];

void main() {
  group('Model Smoke Tests', () {
    test('Workout model toMap/fromMap', () {
      final workout = _workouts[0];
      final map = workout.toMap();
      expect(map['name'], workout.name);
      
      final fromMap = Workout.fromMap(workout.id, map);
      expect(fromMap.name, workout.name);
      expect(fromMap.id, workout.id);
    });

    test('WorkoutSession model toMap/fromMap', () {
      final session = _sessions[0];
      final map = session.toMap();
      expect(map['planName'], session.planName);
      
      final fromMap = WorkoutSession.fromMap(session.id, map);
      expect(fromMap.planName, session.planName);
      expect(fromMap.notes, session.notes);
    });
  });

  group('Widget Smoke Tests', () {
    testWidgets('WorkoutCard renders workout info', (WidgetTester tester) async {
      final workout = _workouts[0];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WorkoutCard(workout: workout),
        ),
      ));

      expect(find.text(workout.name), findsOneWidget);
      expect(find.textContaining(workout.type), findsOneWidget);
    });

    testWidgets('SessionCard renders session info', (WidgetTester tester) async {
      final session = _sessions[0];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SessionCard(session: session),
        ),
      ));

      expect(find.text(session.planName!), findsOneWidget);
      expect(find.textContaining('Completed'), findsOneWidget);
    });
   group('Interactivity Smoke Tests', () {
    testWidgets('WorkoutCard expansion works', (WidgetTester tester) async {
      final workout = Workout(
        id: 'w1',
        name: 'Test Workout',
        type: 'test',
        exercises: _pushDayExercises,
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: WorkoutCard(workout: workout)),
        ),
      ));

      expect(find.text('Bench Press'), findsNothing); // Collapsed
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bench Press'), findsOneWidget); // Expanded
    });
  });
  });
}
