import 'package:flutter/material.dart';
import '../widgets/marketing_nav.dart';

/// Authenticated FAQ screen with standard back-navigation AppBar.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Setup')),
      body: const FaqBody(),
    );
  }
}

/// Public FAQ screen with marketing navigation bar.
class PublicFaqScreen extends StatelessWidget {
  const PublicFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MarketingNav(showFaq: false),
      body: FaqBody(),
    );
  }
}

/// Shared FAQ content used by both authenticated and public FAQ screens.
class FaqBody extends StatelessWidget {
  const FaqBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FaqSection(
          icon: Icons.play_arrow,
          title: 'Getting Started',
          children: const [
            _FaqItem(
              question: 'What is FitApp?',
              answer:
                  'FitApp lets you use AI assistants like Claude or ChatGPT to '
                  'create workout plans and log your training sessions. Your AI '
                  'writes the data, and this app shows it to you in real time.',
            ),
            _FaqItem(
              question: 'How do I start?',
              answer: '1. Sign in with your Google account\n'
                  '2. Tap the key icon in the top bar to generate a token\n'
                  '3. Add the token to your AI client\'s MCP configuration\n'
                  '4. Ask your AI to create a workout plan or log a session',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FaqSection(
          icon: Icons.key,
          title: 'Connecting Your AI Client',
          children: const [
            _FaqItem(
              question: 'How do I connect Claude Code?',
              answer:
                  'Open your Claude Code MCP settings and add a new server:\n\n'
                  '{\n'
                  '  "mcpServers": {\n'
                  '    "fitapp": {\n'
                  '      "url": "<your-function-url>/mcp",\n'
                  '      "headers": {\n'
                  '        "Authorization": "Bearer <your-token>"\n'
                  '      }\n'
                  '    }\n'
                  '  }\n'
                  '}\n\n'
                  'Replace <your-function-url> with your deployed Cloud Function '
                  'URL and <your-token> with the token from the key icon.',
            ),
            _FaqItem(
              question: 'Where do I find my token?',
              answer:
                  'Tap the key icon in the top-right corner of the home screen. '
                  'Press "Generate Token" and copy it. Tokens expire after 1 hour, '
                  'so you\'ll need to generate a new one periodically.',
            ),
            _FaqItem(
              question: 'My token expired. What do I do?',
              answer:
                  'Go back to the key icon screen and generate a new one. '
                  'Update your AI client\'s MCP configuration with the new token. '
                  'In the future, we plan to add longer-lived API keys.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FaqSection(
          icon: Icons.smart_toy,
          title: 'Using AI Tools',
          children: const [
            _FaqItem(
              question: 'What can the AI do?',
              answer: 'Your AI assistant has access to these tools:\n\n'
                  'Plans:\n'
                  '  \u2022 create_plan \u2014 Create a workout plan with exercises\n'
                  '  \u2022 list_plans \u2014 See all your plans\n'
                  '  \u2022 get_plan \u2014 View a plan\'s exercises\n'
                  '  \u2022 add_exercises_to_plan \u2014 Add exercises to a plan\n'
                  '  \u2022 delete_plan \u2014 Remove a plan\n\n'
                  'Sessions:\n'
                  '  \u2022 log_session \u2014 Log a full workout\n'
                  '  \u2022 log_quick_exercise \u2014 Quickly log a single exercise',
            ),
            _FaqItem(
              question: 'What should I say to the AI?',
              answer: 'Just talk naturally. Some examples:\n\n'
                  '  \u2022 "Create a 3-day push/pull/legs plan"\n'
                  '  \u2022 "Log that I did 4x8 bench press at 135 lbs"\n'
                  '  \u2022 "Add deadlifts to my strength plan"\n'
                  '  \u2022 "I just finished a workout: squats 5x5 at 225, '
                  'leg press 3x12 at 360, lunges 3x10"\n'
                  '  \u2022 "Show me my workout plans"\n'
                  '  \u2022 "Delete the cardio plan"',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FaqSection(
          icon: Icons.help_outline,
          title: 'Troubleshooting',
          children: const [
            _FaqItem(
              question: 'I don\'t see my workouts in the app',
              answer:
                  'Make sure you\'re signed in with the same Google account '
                  'that generated the token you gave to the AI client. '
                  'Data appears in real time, so if the AI confirmed it wrote '
                  'the data, try pulling down to refresh or restarting the app.',
            ),
            _FaqItem(
              question: 'The AI says "Invalid credentials"',
              answer:
                  'Your token has likely expired. Generate a new one from the '
                  'key icon screen and update your AI client\'s config.',
            ),
            _FaqItem(
              question: 'Can I edit or delete workouts from the app?',
              answer:
                  'Not yet. Currently all changes go through your AI assistant. '
                  'Ask it to modify or delete plans and sessions for you.',
            ),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'FitApp v1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FaqSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _FaqSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
