import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

const _mcpUrl = 'https://mcp-owojisyiba-uc.a.run.app';

class ApiTokenScreen extends StatefulWidget {
  const ApiTokenScreen({super.key});

  @override
  State<ApiTokenScreen> createState() => _ApiTokenScreenState();
}

class _ApiTokenScreenState extends State<ApiTokenScreen> {
  String? _desktopToken;
  
  String? _clientId;
  String? _oauthSecret;
  bool _loadingDesktop = false;
  bool _loadingOAuth = false;
  bool _provisioning = false;

  @override
  void initState() {
    super.initState();
    _loadUserClient();
  }

  Future<void> _loadUserClient() async {
    setState(() => _loadingOAuth = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('oauthClients')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          _clientId = doc.id;
          _oauthSecret = doc.data()['secret'] as String?;
        });
      }
    } catch (e) {
      print('Error loading client: $e');
    } finally {
      if (mounted) setState(() => _loadingOAuth = false);
    }
  }

  Future<void> _provisionClient() async {
    setState(() => _provisioning = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'Not authenticated';

      // Generate random client ID and Secret
      final clientId = 'cl-${_randomString(12)}';
      final secret = 'sk-${_randomString(32)}';

      await FirebaseFirestore.instance.collection('oauthClients').doc(clientId).set({
        'userId': uid,
        'secret': secret,
        'name': 'Claude Connector',
        'redirectUris': [
          'https://claude.ai/api/mcp/auth_callback',
          'https://claude.ai/oauth/callback'
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _clientId = clientId;
        _oauthSecret = secret;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provisioning failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _provisioning = false);
    }
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _generateDesktopToken() async {
    setState(() => _loadingDesktop = true);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      setState(() => _desktopToken = token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get token: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDesktop = false);
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Claude Integration'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Claude.ai (Web)'),
              Tab(text: 'Claude Desktop'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ClaudeWebTab(
              mcpUrl: _mcpUrl,
              clientId: _clientId,
              oauthSecret: _oauthSecret,
              loading: _loadingOAuth,
              provisioning: _provisioning,
              onProvision: _provisionClient,
              onCopy: _copy,
            ),
            _ClaudeDesktopTab(
              mcpUrl: _mcpUrl,
              token: _desktopToken,
              loading: _loadingDesktop,
              onGenerate: _generateDesktopToken,
              onCopy: _copy,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaudeWebTab extends StatelessWidget {
  const _ClaudeWebTab({
    required this.mcpUrl,
    required this.clientId,
    required this.oauthSecret,
    required this.loading,
    required this.provisioning,
    required this.onProvision,
    required this.onCopy,
  });

  final String mcpUrl;
  final String? clientId;
  final String? oauthSecret;
  final bool loading;
  final bool provisioning;
  final VoidCallback onProvision;
  final Function(String, String) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clientId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 64, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                'Provision Your Connector',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'To use the Claude.ai web connector, you need to generate '
                'your own unique OAuth credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              provisioning 
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: onProvision,
                    icon: const Icon(Icons.add),
                    label: const Text('Generate OAuth Credentials'),
                  ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Claude.ai Custom Connector', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Use these values in the "Add custom connector" dialog on Claude.ai '
            'to grant Claude access to your workout data via OAuth.',
          ),
          const SizedBox(height: 24),
          
          _InfoField(
            label: 'Remote MCP server URL',
            value: mcpUrl,
            onCopy: () => onCopy(mcpUrl, 'URL'),
          ),
          const SizedBox(height: 16),
          
          _InfoField(
            label: 'OAuth Client ID',
            value: clientId!,
            onCopy: () => onCopy(clientId!, 'Client ID'),
          ),
          const SizedBox(height: 16),
          
          _InfoField(
            label: 'OAuth Client Secret',
            value: oauthSecret ?? 'Not set',
            onCopy: () => onCopy(oauthSecret ?? '', 'Secret'),
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text('Setup Instructions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const _StepItem(number: '1', text: 'Open Claude.ai and click "Add custom connector".'),
          const _StepItem(number: '2', text: 'Enter "FitApp" as the Name.'),
          const _StepItem(number: '3', text: 'Paste the Remote MCP server URL above.'),
          const _StepItem(number: '4', text: 'Expand "Advanced settings" and paste the Client ID and Secret.'),
          const _StepItem(number: '5', text: 'Click "Add" and complete the Google Sign-In prompt.'),
        ],
      ),
    );
  }
}

class _ClaudeDesktopTab extends StatelessWidget {
  const _ClaudeDesktopTab({
    required this.mcpUrl,
    required this.token,
    required this.loading,
    required this.onGenerate,
    required this.onCopy,
  });

  final String mcpUrl;
  final String? token;
  final bool loading;
  final VoidCallback onGenerate;
  final Function(String, String) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeBg = theme.colorScheme.surfaceContainerHighest;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Claude Desktop (Static Token)', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('For use with the Claude Desktop app via local config file.'),
          const SizedBox(height: 24),
          
          if (loading)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.key),
              label: Text(token == null ? 'Generate Token' : 'Regenerate Token'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),

          if (token != null) ...[
            const SizedBox(height: 24),
            Text('Config Payload', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: codeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  SelectableText(
                    '{\n'
                    '  "mcpServers": {\n'
                    '    "fitapp": {\n'
                    '      "url": "$mcpUrl",\n'
                    '      "headers": {\n'
                    '        "Authorization": "Bearer $token"\n'
                    '      }\n'
                    '    }\n'
                    '  }\n'
                    '}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () => onCopy(
                        '{\n'
                        '  "mcpServers": {\n'
                        '    "fitapp": {\n'
                        '      "url": "$mcpUrl",\n'
                        '      "headers": {\n'
                        '        "Authorization": "Bearer $token"\n'
                        '      }\n'
                        '    }\n'
                        '  }\n'
                        '}',
                        'Config',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value, required this.onCopy});
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade800),
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: onCopy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(number, style: const TextStyle(fontSize: 11, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
