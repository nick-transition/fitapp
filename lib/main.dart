import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/marketing_screen.dart';

const _useEmulators = bool.fromEnvironment('USE_EMULATORS');

Future<void> _connectEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
  if (kDebugMode) print('EMULATORS: Connected to Auth(:9099) and Firestore(:8081)');
}

void main() {
  if (kDebugMode) {
    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        
        // Initialize MCP toolkit for debugging and screenshots
        MCPToolkitBinding.instance
          ..initialize()
          ..initializeFlutterToolkit();
          
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (_useEmulators) await _connectEmulators();
        runApp(const MyApp());
      },
      (error, stack) {
        MCPToolkitBinding.instance.handleZoneError(error, stack);
      },
    );
  } else {
    _startApp();
  }
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (_useEmulators) await _connectEmulators();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitApp',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  // Mobile Chrome sometimes reports pointer events as non-touch kinds on
  // certain builds. Enabling every drag device guarantees scrolling works
  // across touch, mouse, stylus, and trackpad — including when nested
  // tappable widgets (e.g. ExpansionTile) are present.
  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showLogin = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (kDebugMode) {
          print('AUTH_STATE: connection=${snapshot.connectionState}, hasData=${snapshot.hasData}, uid=${user?.uid}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Show login or marketing directly — no Navigator.push needed.
        // When auth succeeds, the stream fires and this builder returns HomeScreen.
        if (_showLogin) {
          return const PublicLoginScreen();
        }

        return MarketingScreen(
          onGetStarted: () => setState(() => _showLogin = true),
        );
      },
    );
  }
}
