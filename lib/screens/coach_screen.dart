import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coach_connection.dart';
import 'athlete_detail_screen.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Coach Sharing'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.share), text: 'Share My Data'),
              Tab(icon: Icon(Icons.people), text: 'My Athletes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ShareTab(),
            _AthletesTab(),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Share Tab — athlete generates & manages their invite code
// ──────────────────────────────────────────────────────────────────────────────

class _ShareTab extends StatefulWidget {
  const _ShareTab();

  @override
  State<_ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends State<_ShareTab> {
  bool _loading = false;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;
  String get _myName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Athlete';

  String get _inviteDocId => 'invite_$_myUid';

  Future<void> _generateInvite() async {
    setState(() => _loading = true);
    try {
      final code = _generateCode();
      await FirebaseFirestore.instance
          .collection('coachConnections')
          .doc(_inviteDocId)
          .set({
        'ownerUid': _myUid,
        'ownerName': _myName,
        'inviteCode': code,
        'type': 'invite',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revokeAccess(String connectionId, String coachName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text('Remove coach access for $coachName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Revoke', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('coachConnections')
          .doc(connectionId)
          .delete();
    }
  }

  Future<void> _deleteInvite() async {
    await FirebaseFirestore.instance
        .collection('coachConnections')
        .doc(_inviteDocId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Invite Code Card ──────────────────────────────────────────────
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('coachConnections')
              .doc(_inviteDocId)
              .snapshots(),
          builder: (context, snapshot) {
            final hasInvite =
                snapshot.hasData && snapshot.data!.exists;
            final inviteData = hasInvite
                ? snapshot.data!.data() as Map<String, dynamic>
                : null;
            final code = inviteData?['inviteCode'] as String?;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.qr_code_2,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Your Invite Code',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share this code with your coach so they can view your programs and progress.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    if (code != null) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            code,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Code copied to clipboard')),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _loading ? null : _deleteInvite,
                            child: const Text('Delete Code',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _generateInvite,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Generate Invite Code'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // ── Connected Coaches ─────────────────────────────────────────────
        Text('Connected Coaches',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('coachConnections')
              .where('ownerUid', isEqualTo: _myUid)
              .where('type', isEqualTo: 'connection')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No coaches connected yet.\nShare your invite code to get started.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final conn = CoachConnection.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>);
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(conn.coachName ?? 'Coach'),
                    subtitle:
                        conn.connectedAt != null ? Text('Connected ${_formatDate(conn.connectedAt!)}') : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      tooltip: 'Revoke access',
                      onPressed: () => _revokeAccess(
                          doc.id, conn.coachName ?? 'Coach'),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Athletes Tab — coach enters invite codes and views athletes
// ──────────────────────────────────────────────────────────────────────────────

class _AthletesTab extends StatefulWidget {
  const _AthletesTab();

  @override
  State<_AthletesTab> createState() => _AthletesTabState();
}

class _AthletesTabState extends State<_AthletesTab> {
  final _codeController = TextEditingController();
  bool _connecting = false;
  String? _error;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;
  String get _myName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Coach';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      // Find the invite with this code
      final query = await FirebaseFirestore.instance
          .collection('coachConnections')
          .where('inviteCode', isEqualTo: code)
          .where('type', isEqualTo: 'invite')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _error = 'Invalid code. Please check and try again.');
        return;
      }

      final inviteData = query.docs.first.data();
      final ownerUid = inviteData['ownerUid'] as String;
      final ownerName = inviteData['ownerName'] as String? ?? 'Athlete';

      if (ownerUid == _myUid) {
        setState(() => _error = 'You cannot connect to yourself.');
        return;
      }

      // Check if already connected
      final connectionId = '${ownerUid}_$_myUid';
      final existing = await FirebaseFirestore.instance
          .collection('coachConnections')
          .doc(connectionId)
          .get();

      if (existing.exists) {
        setState(() => _error = 'Already connected to $ownerName.');
        return;
      }

      // Create the active connection document
      await FirebaseFirestore.instance
          .collection('coachConnections')
          .doc(connectionId)
          .set({
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'coachUid': _myUid,
        'coachName': _myName,
        'type': 'connection',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'connectedAt': FieldValue.serverTimestamp(),
      });

      _codeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to $ownerName!')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect(String connectionId, String athleteName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disconnect'),
        content: Text('Stop viewing $athleteName\'s data?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disconnect',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('coachConnections')
          .doc(connectionId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Connect via Code ──────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Connect to Athlete',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask your athlete for their invite code and enter it below.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Enter 6-character code',
                          border: const OutlineInputBorder(),
                          errorText: _error,
                          isDense: true,
                        ),
                        maxLength: 6,
                        onSubmitted: (_) => _connect(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _connecting ? null : _connect,
                      child: _connecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Athlete List ──────────────────────────────────────────────────
        Text('Your Athletes',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('coachConnections')
              .where('coachUid', isEqualTo: _myUid)
              .where('type', isEqualTo: 'connection')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No athletes connected yet.\nEnter an invite code above to get started.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final conn = CoachConnection.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>);
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(conn.ownerName ?? 'Athlete'),
                    subtitle: const Text('Tap to view programs & progress'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AthleteDetailScreen(
                          athleteUid: conn.ownerUid,
                          athleteName: conn.ownerName ?? 'Athlete',
                        ),
                      ),
                    ),
                    onLongPress: () =>
                        _disconnect(doc.id, conn.ownerName ?? 'Athlete'),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 8),
        Text(
          'Long-press an athlete to disconnect.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
