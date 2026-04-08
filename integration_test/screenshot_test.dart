import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitapp/screens/marketing_screen.dart';
import 'package:fitapp/screens/login_screen.dart';
import 'package:fitapp/screens/faq_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  group('Marketing Pages', () {
    testWidgets('marketing landing page', (tester) async {
      await tester.pumpWidget(wrapInApp(const MarketingScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('01_marketing_landing');
    });

    testWidgets('login page', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const Scaffold(
          body: LoginScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02_login');
    });

    testWidgets('faq page', (tester) async {
      await tester.pumpWidget(wrapInApp(const FaqScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('03_faq');
    });
  });
}
