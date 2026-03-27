import 'package:flutter/material.dart';
import '../widgets/marketing_nav.dart';

class MarketingScreen extends StatelessWidget {
  final VoidCallback? onGetStarted;

  const MarketingScreen({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MarketingNav(showHome: false, onSignIn: onGetStarted),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your AI-Powered\nWorkout Companion',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create workout plans and log sessions using natural language.\n'
                    'Just tell your AI assistant what you did \u2014 FitApp handles the rest.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: onGetStarted,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Get Started'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            ),

            // Features section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'How It Works',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _FeatureCard(
                    icon: Icons.smart_toy,
                    title: 'Talk to Your AI',
                    description:
                        'Use Claude, ChatGPT, or any MCP-compatible AI to '
                        'create plans and log workouts in natural language.',
                  ),
                  const SizedBox(height: 16),
                  const _FeatureCard(
                    icon: Icons.list_alt,
                    title: 'Structured Plans',
                    description:
                        'Your AI builds organized workout plans with exercises, '
                        'sets, reps, and weights \u2014 all stored securely.',
                  ),
                  const SizedBox(height: 16),
                  const _FeatureCard(
                    icon: Icons.history,
                    title: 'Session Tracking',
                    description:
                        'Log what you actually did. Review past sessions '
                        'and track your progress over time.',
                  ),
                  const SizedBox(height: 16),
                  const _FeatureCard(
                    icon: Icons.sync,
                    title: 'Real-Time Sync',
                    description:
                        'Data appears instantly in the app as your AI writes it. '
                        'No refresh needed.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Steps section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Get Started in 3 Steps',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _StepTile(
                    number: '1',
                    title: 'Sign in with Google',
                    description: 'Create your account in one tap.',
                  ),
                  const SizedBox(height: 12),
                  const _StepTile(
                    number: '2',
                    title: 'Generate a token',
                    description:
                        'Get a token to connect your AI assistant.',
                  ),
                  const SizedBox(height: 12),
                  const _StepTile(
                    number: '3',
                    title: 'Start training',
                    description:
                        'Tell your AI to create plans and log workouts.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Text(
                'FitApp v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          number,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        description,
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }
}
