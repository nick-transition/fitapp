import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _mcpUrl = 'https://mcp-owojisyiba-uc.a.run.app';

const _scopeDescriptions = {
  'profile:read': 'Read basic profile information',
  'workout:read': 'View workout plans, sessions, and history',
  'workout:write': 'Create workout plans and log sessions',
};

/// Lists the AI clients the user has authorized via OAuth, with the exact
/// permissions each one holds, and lets the user revoke access. There are no
/// credentials to copy anywhere: clients connect with just the MCP URL and
/// the user approves permissions on the consent page.
class ConnectedAppsScreen extends StatelessWidget {
  const ConnectedAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Connected Apps')),
      body: uid == null
          ? const Center(child: Text('Sign in to manage connected apps.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SetupCard(),
                const SizedBox(height: 24),
                Text('Authorized apps',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _GrantsList(uid: uid),
              ],
            ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard();

  void _copyUrl(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _mcpUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('MCP server URL copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy_outlined),
                const SizedBox(width: 8),
                Text('Connect an AI client', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'In Claude (or any MCP client), add a connector with this server '
              'URL. No client ID, secret, or token is needed — you\'ll sign in '
              'and choose exactly which permissions to grant.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      _mcpUrl,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy URL',
                    onPressed: () => _copyUrl(context),
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

class _GrantsList extends StatelessWidget {
  const _GrantsList({required this.uid});

  final String uid;

  Future<void> _revoke(BuildContext context, String grantId, String clientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke access for $clientName?'),
        content: const Text(
            'The app will immediately lose access to your account. You can '
            'reconnect it later by authorizing it again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) throw 'Not authenticated';

      final resp = await http.post(
        Uri.parse('$_mcpUrl/grants/revoke'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'grantId': grantId}),
      );
      if (resp.statusCode != 200) {
        throw 'Server responded ${resp.statusCode}';
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Access revoked for $clientName')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to revoke access: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('oauthGrants')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load connected apps: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No apps connected yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              _GrantCard(
                grantId: doc.id,
                data: doc.data(),
                onRevoke: (name) => _revoke(context, doc.id, name),
              ),
          ],
        );
      },
    );
  }
}

class _GrantCard extends StatelessWidget {
  const _GrantCard({
    required this.grantId,
    required this.data,
    required this.onRevoke,
  });

  final String grantId;
  final Map<String, dynamic> data;
  final Function(String) onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientName = (data['clientName'] as String?) ?? 'Unnamed application';
    final scopes = ((data['scope'] as String?) ?? '')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(clientName, style: theme.textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () => onRevoke(clientName),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Revoke'),
                ),
              ],
            ),
            if (updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Authorized ${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scope in scopes)
                  Tooltip(
                    message: _scopeDescriptions[scope] ?? scope,
                    child: Chip(
                      label: Text(scope, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
