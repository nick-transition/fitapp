import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
import '../widgets/workout_card.dart';
import '../widgets/session_card.dart';
import 'api_token_screen.dart';
import 'calendar_screen.dart';
import 'coach_screen.dart';
import '../models/workout_program.dart';
import 'program_edit_screen.dart';
import 'faq_screen.dart';
import 'subscription_screen.dart';
import 'workout_edit_screen.dart';
import 'session_edit_screen.dart';

import 'program_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FitApp'),
          actions: [
            IconButton(
              icon: const Icon(Icons.card_membership),
              tooltip: 'Subscription',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Coach Sharing',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CoachScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.key),
              tooltip: 'AI Client Setup',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiTokenScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Help & Setup',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.folder_copy), text: 'Programs'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
              Tab(icon: Icon(Icons.history), text: 'Sessions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProgramsTab(),
            _WorkoutsTab(),
            CalendarScreen(),
            _SessionsTab(),
          ],
        ),
      ),
    );
  }
}

class _ProgramsTab extends StatelessWidget {
  const _ProgramsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not authenticated')));
    final uid = user.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgramEditScreen()),
        ),
        tooltip: 'New Program',
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('programs')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No programs yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final program = WorkoutProgram.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
              return _ProgramCard(program: program);
            },
          );
        },
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.folder, color: Colors.teal),
        title: Text(program.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(program.description ?? 'No description'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _deleteProgram(context),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramDetailScreen(program: program),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteProgram(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Query child plans so we can show the count in the dialog and delete them.
    final plansSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('plans')
        .where('programId', isEqualTo: program.id)
        .get();
    final planCount = plansSnapshot.docs.length;

    if (!context.mounted) return;

    final content = planCount > 0
        ? 'This will delete the program and all $planCount plan${planCount == 1 ? '' : 's'} underneath it. Linked workouts will become standalone.'
        : 'Delete this program? Linked workouts will NOT be deleted but will become standalone.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in plansSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(
        FirebaseFirestore.instance.collection('users').doc(uid).collection('programs').doc(program.id),
      );
      await batch.commit();
    }
  }
}

class _WorkoutsTab extends StatelessWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not authenticated')));
    final uid = user.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutEditScreen()),
        ),
        tooltip: 'Add Workout',
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No workouts yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap + to create your first workout', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final workout = Workout.fromMap(
                  docs[index].id, docs[index].data()! as Map<String, dynamic>);
              return WorkoutCard(workout: workout);
            },
          );
        },
      ),
    );
  }
}


class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not authenticated')));
    final uid = user.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SessionEditScreen()),
        ),
        tooltip: 'Log Session',
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .orderBy('startedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No workout sessions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sessions will appear here once recorded',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final session = WorkoutSession.fromMap(
                doc.id,
                doc.data()! as Map<String, dynamic>,
              );
              return SessionCard(session: session);
            },
          );
        },
      ),
    );
  }
}
