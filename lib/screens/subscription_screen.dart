import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _functionsBase = 'https://FUNCTION-owojisyiba-uc.a.run.app';

String _functionUrl(String name) =>
    _functionsBase.replaceFirst('FUNCTION', name.toLowerCase());

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.doc('users/$uid').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final tier = data['subscriptionTier'] as String? ?? 'free';
          final status = data['subscriptionStatus'] as String? ?? 'none';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusCard(tier: tier, status: status),
                const SizedBox(height: 24),
                if (tier == 'free' || status == 'canceled')
                  _UpgradeSection(currentTier: tier)
                else
                  _ManageSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String tier;
  final String status;
  const _StatusCard({required this.tier, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color, icon) = switch (tier) {
      'pro' => ('Pro', Colors.teal, Icons.star),
      'coach' => ('Coach', Colors.deepPurple, Icons.sports),
      _ => ('Free', Colors.grey, Icons.person),
    };

    final statusLabel = switch (status) {
      'active' => 'Active',
      'trialing' => 'Trial',
      'past_due' => 'Past Due',
      'canceled' => 'Canceled',
      _ => 'No subscription',
    };

    final statusColor = switch (status) {
      'active' || 'trialing' => Colors.green,
      'past_due' => Colors.orange,
      'canceled' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              '$label Plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (status == 'trialing') ...[
              const SizedBox(height: 8),
              Text(
                '7-day free trial',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpgradeSection extends StatefulWidget {
  final String currentTier;
  const _UpgradeSection({required this.currentTier});

  @override
  State<_UpgradeSection> createState() => _UpgradeSectionState();
}

class _UpgradeSectionState extends State<_UpgradeSection> {
  bool _loading = false;

  Future<void> _subscribe(String tier) async {
    setState(() => _loading = true);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw 'Not authenticated';

      final response = await http.post(
        Uri.parse(_functionUrl('createCheckoutSession')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tier': tier,
          'successUrl': 'https://fitapp-ns.web.app/',
          'cancelUrl': 'https://fitapp-ns.web.app/',
        }),
      );

      if (response.statusCode != 200) {
        throw 'Failed to create checkout session: ${response.body}';
      }

      final url = jsonDecode(response.body)['url'] as String;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upgrade Your Plan', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Start with a 7-day free trial',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _PlanCard(
          title: 'Pro',
          price: '\$9.99/mo',
          color: Colors.teal,
          icon: Icons.star,
          features: const [
            'Unlimited AI coaching interactions',
            'Full session logging & history',
            'Exercise history queries',
            'Calendar features',
          ],
          onTap: () => _subscribe('pro'),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Coach',
          price: '\$29.99/mo',
          color: Colors.deepPurple,
          icon: Icons.sports,
          features: const [
            'Everything in Pro',
            'Publish programs to marketplace',
            'Revenue share on program sales',
            'Athlete management dashboard',
          ],
          onTap: () => _subscribe('coach'),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final Color color;
  final IconData icon;
  final List<String> features;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.color,
    required this.icon,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(backgroundColor: color),
                child: const Text('Start Free Trial'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageSection extends StatefulWidget {
  @override
  State<_ManageSection> createState() => _ManageSectionState();
}

class _ManageSectionState extends State<_ManageSection> {
  bool _loading = false;

  Future<void> _openPortal() async {
    setState(() => _loading = true);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw 'Not authenticated';

      final response = await http.post(
        Uri.parse(_functionUrl('createPortalSession')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'returnUrl': 'https://fitapp-ns.web.app/',
        }),
      );

      if (response.statusCode != 200) {
        throw 'Failed to open billing portal: ${response.body}';
      }

      final url = jsonDecode(response.body)['url'] as String;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Manage Subscription',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Update payment method, change plan, or cancel your subscription through the Stripe billing portal.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : OutlinedButton.icon(
                onPressed: _openPortal,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Billing Portal'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
      ],
    );
  }
}
