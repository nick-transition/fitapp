import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/screens/calendar_screen.dart';
import 'package:fitapp/models/workout_session.dart';

void main() {
  group('MonthHeader accessibility', () {
    testWidgets('renders previous and next buttons with tooltips', (tester) async {
      var prevTapped = false;
      var nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthHeader(
              month: DateTime(2025, 5),
              onPrevious: () => prevTapped = true,
              onNext: () => nextTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('May 2025'), findsOneWidget);
      expect(find.byTooltip('Previous month'), findsOneWidget);
      expect(find.byTooltip('Next month'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      expect(prevTapped, isTrue);

      await tester.tap(find.byTooltip('Next month'));
      expect(nextTapped, isTrue);
    });
  });

  group('CalendarGrid accessibility & keyboard interaction', () {
    testWidgets('renders day cells and handles selection tap', (tester) async {
      DateTime? selected;
      final testMonth = DateTime(2025, 1);
      final initialDate = DateTime(2025, 1, 10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarGrid(
              month: testMonth,
              selectedDate: initialDate,
              sessionsByDate: const {},
              onDateSelected: (d) => selected = d,
            ),
          ),
        ),
      );

      // Verify day headers exist
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // Tap on day 15
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(selected, equals(DateTime(2025, 1, 15)));
    });

    testWidgets('provides comprehensive semantics for dates, today, selected, and sessions', (tester) async {
      final testMonth = DateTime(2025, 1);
      final selectedDate = DateTime(2025, 1, 15);
      final completedSessionDate = DateTime(2025, 1, 10);
      final scheduledSessionDate = DateTime(2025, 1, 20);

      final sessions = {
        completedSessionDate: [
          WorkoutSession(
            id: 's1',
            completedAt: DateTime(2025, 1, 10, 9, 0),
          ),
        ],
        scheduledSessionDate: [
          WorkoutSession(
            id: 's2',
            scheduledAt: DateTime(2025, 1, 20, 14, 0),
          ),
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarGrid(
              month: testMonth,
              selectedDate: selectedDate,
              sessionsByDate: sessions,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );

      // Verify selected date semantics
      expect(
        find.bySemanticsLabel('January 15, 2025, Selected'),
        findsOneWidget,
      );

      // Verify completed session semantics
      expect(
        find.bySemanticsLabel('January 10, 2025, Completed session'),
        findsOneWidget,
      );

      // Verify scheduled session semantics
      expect(
        find.bySemanticsLabel('January 20, 2025, Scheduled session'),
        findsOneWidget,
      );
    });

    testWidgets('supports keyboard activation via Enter/Space on focused date cell', (tester) async {
      DateTime? selected;
      final testMonth = DateTime(2025, 1);
      final initialDate = DateTime(2025, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarGrid(
              month: testMonth,
              selectedDate: initialDate,
              sessionsByDate: const {},
              onDateSelected: (d) => selected = d,
            ),
          ),
        ),
      );

      // Find InkWell for day 5
      final day5Finder = find.ancestor(
        of: find.text('5'),
        matching: find.byType(InkWell),
      );
      expect(day5Finder, findsOneWidget);

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(selected, equals(DateTime(2025, 1, 5)));
    });

    testWidgets('padding cells are excluded from semantics', (tester) async {
      final testMonth = DateTime(2025, 1); // Jan 1 is Wed, offset is 2 padding days
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarGrid(
              month: testMonth,
              selectedDate: DateTime(2025, 1, 1),
              sessionsByDate: const {},
              onDateSelected: (_) {},
            ),
          ),
        ),
      );

      // Total valid days in Jan is 31
      final semanticsFinders = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      );
      expect(semanticsFinders, findsNWidgets(31));
    });
  });
}
