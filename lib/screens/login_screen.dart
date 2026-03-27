import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/web_utils.dart';
import '../widgets/marketing_nav.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    print('SIGN_IN: Initiating Google Sign-In...');
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        print('SIGN_IN: Web - Calling signInWithPopup...');
        try {
          final result = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
          print('SIGN_IN: signInWithPopup COMPLETED. User UID: ${result.user?.uid}');
          if (result.user != null) {
            // Force a full page reload so Firebase restores auth state cleanly.
            reloadPage();
            return;
          }
        } catch (e) {
          print('SIGN_IN: signInWithPopup error: $e');
          // If the popup threw but we somehow have a current user, still reload.
          if (FirebaseAuth.instance.currentUser != null) {
            reloadPage();
            return;
          }
          rethrow;
        }
      } else {
        print('SIGN_IN: Mobile - Using google_sign_in package...');
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          print('SIGN_IN: User cancelled mobile sign-in.');
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await FirebaseAuth.instance.signInWithCredential(credential);
        print('SIGN_IN: signInWithCredential COMPLETED. User UID: ${result.user?.uid}');
        // No Navigator.pop needed — AuthWrapper owns the screen stack now.
      }
    } catch (e) {
      print('SIGN_IN: FINAL CATCH - Sign in failed with exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    } finally {
      print('SIGN_IN: Finally resetting loading state.');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'FitApp',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'AI-powered workout tracking',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 48),
            if (_loading)
              const CircularProgressIndicator()
            else
              FilledButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Login screen wrapped with public marketing navigation.
class PublicLoginScreen extends StatelessWidget {
  const PublicLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MarketingNav(showLogin: false),
      body: LoginScreen(),
    );
  }
}
