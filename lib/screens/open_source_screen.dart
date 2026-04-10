import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/marketing_nav.dart';

class OpenSourceScreen extends StatelessWidget {
  const OpenSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const MarketingNav(),
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
                    Icons.code,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Built in the Open',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FitApp is open source under AGPL-3.0. Every line of code is public,\n'
                    'every contributor is compensated, and every dollar is on-chain.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('View on GitHub'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(180, 48),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(160, 48),
                        ),
                        child: const Text('Become a Coach'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Revenue Protocol section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  Text(
                    'Revenue Protocol',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every dollar of subscription and commercial license revenue is split on-chain. '
                    'Distributions are publicly auditable.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const _RevenueGrid(),
                ],
              ),
            ),

            const Divider(height: 1),

            // For Coaches section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  Text(
                    'For Coaches',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sell your workout programs directly to athletes. FitApp handles billing, '
                    'delivery, and payouts via Stripe Connect.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const _FeatureCard(
                    icon: Icons.storefront,
                    title: 'Marketplace Listing',
                    description:
                        'Publish programs at your own price. Athletes browse, subscribe, '
                        'and get instant access \u2014 no manual delivery needed.',
                  ),
                  const SizedBox(height: 16),
                  const _FeatureCard(
                    icon: Icons.payments,
                    title: '80 / 20 Revenue Split',
                    description:
                        'You keep 80% of every sale. FitApp takes 20% to cover platform '
                        'infrastructure and contributor pool. Paid monthly via Stripe Connect.',
                  ),
                  const SizedBox(height: 16),
                  const _FeatureCard(
                    icon: Icons.verified,
                    title: 'Verified Coach Badge',
                    description:
                        'Apply for certification to get a verified badge on your profile '
                        'and higher placement in marketplace search.',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // For Contributors section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  Text(
                    'For Contributors',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code merged = money earned. Contributions are scored weekly; '
                    'the pool distributes monthly.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const _ScoringTable(),
                  const SizedBox(height: 32),
                  const _FeatureCard(
                    icon: Icons.hub,
                    title: 'How It Works',
                    description:
                        'Pick up an issue labeled \u2018good first issue\u2019, open a PR, get it merged. '
                        'Add your Ethereum address to contributors/addresses.json. '
                        'Scores are computed from GitHub events and published weekly. '
                        'USDC streams to your wallet monthly via Drips Protocol.',
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Browse Open Issues on GitHub'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(260, 48),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Protocol Stack section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  Text(
                    'Protocol Stack',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Standing on the shoulders of the open source finance stack.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const _ProtocolCard(
                    icon: Icons.water_drop,
                    name: 'Drips Protocol',
                    role: 'Streaming payments',
                    description:
                        'Ethereum-native streaming payments. Subscription revenue '
                        'converts to USDC and streams continuously to contributor wallets '
                        'proportional to their score weight.',
                  ),
                  const SizedBox(height: 16),
                  const _ProtocolCard(
                    icon: Icons.emoji_nature,
                    name: 'tea.xyz',
                    role: 'Proof of Contribution (inspiration)',
                    description:
                        'tea.xyz pioneered on-chain contributor scoring based on '
                        'package dependency weight. FitApp adapts this to direct '
                        'GitHub contribution metrics for a single-repo project.',
                  ),
                  const SizedBox(height: 16),
                  const _ProtocolCard(
                    icon: Icons.account_balance,
                    name: 'Open Collective',
                    role: 'Phase 1 fiscal host',
                    description:
                        'Before the on-chain protocol is live, Open Collective hosts '
                        'the contributor fund with a fully public ledger. All income and '
                        'expenses are transparent from day one.',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Email capture section
            const _EmailCaptureSection(),

            const Divider(height: 1),

            // CTA section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
              child: Column(
                children: [
                  Text(
                    'Ready to Build?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Whether you write code or coach athletes, there\u2019s a place for you in FitApp.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Start Contributing'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(180, 48),
                        ),
                        child: const Text('Become a Coach'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Text(
                'FitApp v1.0.0 \u2014 AGPL-3.0',
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

class _RevenueGrid extends StatelessWidget {
  const _RevenueGrid();

  @override
  Widget build(BuildContext context) {
    const splits = [
      _RevenueSplit(
        icon: Icons.person,
        recipient: 'Founder',
        share: '40%',
        rationale: 'Sustained development, infrastructure costs, business operations',
        color: Color(0xFF6366F1),
      ),
      _RevenueSplit(
        icon: Icons.group,
        recipient: 'Contributor Pool',
        share: '25%',
        rationale: 'Distributed to OSS contributors via Drips Protocol on-chain',
        color: Color(0xFF10B981),
      ),
      _RevenueSplit(
        icon: Icons.cloud,
        recipient: 'Infrastructure',
        share: '15%',
        rationale: 'Hosting, Firebase, CDN, CI/CD',
        color: Color(0xFFF59E0B),
      ),
      _RevenueSplit(
        icon: Icons.fitness_center,
        recipient: 'Coach Revenue',
        share: '20%',
        rationale: 'Direct payments to certified coaches on the platform',
        color: Color(0xFFEF4444),
      ),
    ];

    return Column(
      children: splits
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RevenueSplitTile(split: s),
              ))
          .toList(),
    );
  }
}

class _RevenueSplit {
  final IconData icon;
  final String recipient;
  final String share;
  final String rationale;
  final Color color;

  const _RevenueSplit({
    required this.icon,
    required this.recipient,
    required this.share,
    required this.rationale,
    required this.color,
  });
}

class _RevenueSplitTile extends StatelessWidget {
  final _RevenueSplit split;

  const _RevenueSplitTile({required this.split});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: split.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(split.icon, color: split.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    split.recipient,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    split.rationale,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: split.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                split.share,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: split.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoringTable extends StatelessWidget {
  const _ScoringTable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const rows = [
      ('Merged PR (small)', '+1 point'),
      ('Merged PR (medium)', '+3 points'),
      ('Merged PR (large)', '+10 points'),
      ('Issue with reproduction steps', '+2 points'),
      ('PR review with substantive feedback', '+1 point'),
      ('Merged documentation page', '+1 point'),
      ('Dependency maintenance (automated)', '+0.5 points'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contributor Scoring',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.$1,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        row.$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Text(
              'Your share = (your score \u00f7 total score) \u00d7 monthly pool',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String role;
  final String description;

  const _ProtocolCard({
    required this.icon,
    required this.name,
    required this.role,
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
                  Row(
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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

class _EmailCaptureSection extends StatefulWidget {
  const _EmailCaptureSection();

  @override
  State<_EmailCaptureSection> createState() => _EmailCaptureSectionState();
}

class _EmailCaptureSectionState extends State<_EmailCaptureSection> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _controller.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('waitlist')
          .doc(email)
          .set({'email': email, 'source': 'open_source_page', 'createdAt': FieldValue.serverTimestamp()});
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Text(
            'Join the Community',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get notified about contributor opportunities, coach program launches, and protocol updates.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_submitted)
            Card(
              color: const Color(0xFF10B981).withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      "You're on the list!",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _subscribe(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _subscribe,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Subscribe'),
                  ),
                ],
              ),
            ),
        ],
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
