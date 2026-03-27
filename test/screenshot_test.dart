import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/screens/marketing_screen.dart';
import 'package:fitapp/screens/login_screen.dart';
import 'package:fitapp/screens/faq_screen.dart';

void main() {
  Widget wrapInApp(Widget child) {
    return MaterialApp(
      title: 'FitApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: child,
    );
  }

  testWidgets('marketing landing page screenshot', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapInApp(const MarketingScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/01_marketing_landing.png'),
    );
  });

  testWidgets('login page screenshot', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapInApp(
      const Scaffold(
        body: LoginScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/02_login.png'),
    );
  });

  testWidgets('faq page screenshot', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapInApp(const FaqScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/03_faq.png'),
    );
  });
}
