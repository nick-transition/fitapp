import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/screens/login_screen.dart';

void main() {
  Widget buildTestableLogin({TextScaler textScaler = TextScaler.noScaling}) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: const Scaffold(
          body: LoginScreen(),
        ),
      ),
    );
  }

  group('LoginScreen visual and responsive layout', () {
    testWidgets('renders title, subtitle, icon, and Google sign-in button', (tester) async {
      await tester.pumpWidget(buildTestableLogin());

      expect(find.text('FitApp'), findsOneWidget);
      expect(find.text('AI-powered workout tracking'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders cleanly on narrow mobile dimensions without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableLogin());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('renders cleanly on wide desktop dimensions within constrained width', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableLogin());
      await tester.pump();

      expect(tester.takeException(), isNull);
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.width, lessThanOrEqualTo(440));
    });

    testWidgets('handles elevated text scaling without layout exception', (tester) async {
      await tester.pumpWidget(
        buildTestableLogin(textScaler: const TextScaler.linear(2.0)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('FitApp'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('public login screen wraps with marketing navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const PublicLoginScreen(),
        ),
      );

      expect(find.byType(PublicLoginScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('FitApp'), findsAtLeast(1));
    });
  });
}
