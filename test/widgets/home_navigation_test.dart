import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/screens/home_screen.dart';

void main() {
  group('HomeScreen NavigationBar', () {
    const testDestinations = [
      Center(child: Text('Programs Content')),
      Center(child: Text('Calendar Content')),
      Center(child: Text('Sessions Content')),
    ];

    Widget buildTestWidget({bool disableAnimations = false}) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const HomeScreen(
            testDestinations: testDestinations,
          ),
        ),
      );
    }

    testWidgets('renders NavigationBar with Programs, Calendar, and Sessions destinations', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Programs'), findsWidgets);
      expect(find.text('Calendar'), findsWidgets);
      expect(find.text('Sessions'), findsWidgets);

      // Default selected destination is Programs
      expect(find.text('Programs Content'), findsOneWidget);
      expect(find.text('Calendar Content'), findsNothing);
      expect(find.text('Sessions Content'), findsNothing);
    });

    testWidgets('switching destinations updates content and active selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap Calendar destination
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      expect(find.text('Calendar Content'), findsOneWidget);
      expect(find.text('Programs Content'), findsNothing);
      expect(find.text('Sessions Content'), findsNothing);

      // Tap Sessions destination
      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle();

      expect(find.text('Sessions Content'), findsOneWidget);
      expect(find.text('Calendar Content'), findsNothing);
      expect(find.text('Programs Content'), findsNothing);
    });

    testWidgets('uses AnimatedSwitcher for destination transitions', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      final animatedSwitcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
      expect(animatedSwitcher.duration, const Duration(milliseconds: 200));

      // With animations disabled (reduced motion), duration is zero
      await tester.pumpWidget(buildTestWidget(disableAnimations: true));
      final reducedMotionSwitcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
      expect(reducedMotionSwitcher.duration, Duration.zero);
    });
  });
}
