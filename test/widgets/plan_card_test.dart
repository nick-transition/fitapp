import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/widgets/plan_card.dart';
import 'package:fitapp/models/workout_plan.dart';

void main() {
  group('PlanCard day headers', () {
    WorkoutPlan _buildPlan() {
      return WorkoutPlan(
        id: 'test-plan',
        name: 'Strength Program',
        description: 'A two-day split',
        days: [
          WorkoutDay(
            name: 'Day 1: Lower Body',
            exercises: [
              PlanExercise(name: 'Squat', sets: 3, reps: 10),
              PlanExercise(name: 'Deadlift', sets: 3, reps: 8),
            ],
          ),
          WorkoutDay(
            name: 'Day 2: Upper Body',
            exercises: [
              PlanExercise(name: 'Bench Press', sets: 4, reps: 10),
            ],
          ),
        ],
      );
    }

    testWidgets('day headers are hidden before expansion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlanCard(plan: _buildPlan())),
        ),
      );

      expect(find.text('Day 1: Lower Body'), findsNothing);
      expect(find.text('Day 2: Upper Body'), findsNothing);
    });

    testWidgets('day headers appear after tapping to expand', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlanCard(plan: _buildPlan())),
        ),
      );

      await tester.tap(find.text('Strength Program'));
      await tester.pumpAndSettle();

      expect(find.text('Day 1: Lower Body'), findsOneWidget);
      expect(find.text('Day 2: Upper Body'), findsOneWidget);
    });

    testWidgets('exercises appear under their respective day headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlanCard(plan: _buildPlan())),
        ),
      );

      await tester.tap(find.text('Strength Program'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Squat'), findsOneWidget);
      expect(find.textContaining('Deadlift'), findsOneWidget);
      expect(find.textContaining('Bench Press'), findsOneWidget);
    });

    testWidgets('subtitle shows correct day and exercise counts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlanCard(plan: _buildPlan())),
        ),
      );

      expect(find.text('2 days · 3 exercises'), findsOneWidget);
    });
  });
}
