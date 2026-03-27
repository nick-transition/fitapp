import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/marketing_screen.dart';

void main() {
  enableFlutterDriverExtension();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      MCPToolkitBinding.instance
        ..initialize()
        ..initializeFlutterToolkit();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(const MyApp());
    },
    (error, stack) {
      MCPToolkitBinding.instance.handleZoneError(error, stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const MarketingScreen();
        },
      ),
    );
  }
}
