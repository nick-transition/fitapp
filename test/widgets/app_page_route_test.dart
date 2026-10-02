import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/widgets/app_page_route.dart';

void main() {
  group('AppPageRoute', () {
    test('uses the shared fade-through motion timings', () {
      final route = AppPageRoute<void>(builder: (_) => const SizedBox());

      expect(route, isA<PageRouteBuilder>());
      expect(route.transitionDuration, const Duration(milliseconds: 300));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 200));
      expect(route.opaque, isTrue);
    });

    testWidgets('push renders the destination and pop returns home',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('home'))),
      );

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(AppPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('detail')),
          ));
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('carries Hero flights between the two routes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              Hero(tag: 'hero-item-1', child: Text('Card title')),
            ],
          ),
        ),
      ));

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(AppPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Hero(tag: 'hero-item-1', child: const Text('Card title')),
              ),
            ),
          ));

      // One frame into the flight: the Hero must exist exactly once — a
      // duplicate tag on either route would throw here.
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Card title'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Card title'), findsOneWidget);
    });

    testWidgets('leaves the outgoing route mounted beneath during push',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('home'))),
      );

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(AppPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('detail')),
          ));
      // Mid-transition both views coexist (fade-through, not an abrupt swap).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('home'), findsOneWidget);
      expect(find.text('detail'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    });
  });
}
