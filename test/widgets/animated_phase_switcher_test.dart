import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/widgets/animated_phase_switcher.dart';

Widget _harness(Widget phase) {
  return MaterialApp(
    home: Scaffold(
      body: AnimatedPhaseSwitcher(child: phase),
    ),
  );
}

void main() {
  testWidgets('cross-fades between two keyed phases', (tester) async {
    await tester.pumpWidget(_harness(const KeyedSubtree(
      key: ValueKey('loading'),
      child: CircularProgressIndicator(),
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(_harness(const KeyedSubtree(
      key: ValueKey('content'),
      child: Text('content'),
    )));

    // Mid-transition both phases coexist — cross-fade, not an abrupt swap.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('content'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('updates in place when the phase key is unchanged',
      (tester) async {
    Widget harness(String label) => _harness(KeyedSubtree(
          key: const ValueKey('content'),
          child: Text(label),
        ));

    await tester.pumpWidget(harness('first'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(harness('second'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
  });
}
