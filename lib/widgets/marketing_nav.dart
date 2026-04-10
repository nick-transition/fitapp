import 'package:flutter/material.dart';
import '../screens/faq_screen.dart';
import '../screens/login_screen.dart';
import '../screens/marketing_screen.dart';
import '../screens/open_source_screen.dart';

class MarketingNav extends StatelessWidget implements PreferredSizeWidget {
  final bool showHome;
  final bool showFaq;
  final bool showLogin;
  final VoidCallback? onSignIn;

  const MarketingNav({
    super.key,
    this.showHome = true,
    this.showFaq = true,
    this.showLogin = true,
    this.onSignIn,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => screen,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: showHome
            ? () => _navigate(context, const MarketingScreen())
            : null,
        child: MouseRegion(
          cursor: showHome
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'FitApp',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              _navigate(context, const OpenSourceScreen()),
          child: const Text('Open Source'),
        ),
        if (showFaq)
          TextButton(
            onPressed: () =>
                _navigate(context, const PublicFaqScreen()),
            child: const Text('FAQ'),
          ),
        if (showLogin)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: onSignIn ?? () => _navigate(context, const PublicLoginScreen()),
              child: const Text('Sign In'),
            ),
          ),
      ],
    );
  }
}
