import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../widgets/session_card.dart';
import 'api_token_screen.dart';
import 'calendar_screen.dart';
import 'coach_screen.dart';
import '../models/workout_program.dart';
import 'program_edit_screen.dart';
import 'faq_screen.dart';
import 'subscription_screen.dart';
import 'session_edit_screen.dart';

import 'program_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
              Tab(icon: Icon(Icons.history), text: 'Sessions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProgramsTab(),
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
        ? 'This will delete the program and all $planCount workout${planCount == 1 ? '' : 's'} underneath it.'
        : 'Delete this program?';

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

class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not authenticated')));
    final uid = user.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanPicker(context, uid),
        tooltip: 'Start Workout',
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

Future<void> _showPlanPicker(BuildContext context, String uid) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose a workout',
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('plans')
                      .orderBy('updatedAt', descending: true)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No workouts yet. Create one from the Programs tab.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final plan = WorkoutPlan.fromMap(
                          docs[i].id,
                          docs[i].data() as Map<String, dynamic>,
                        );
                        final totalExercises = plan.days
                            .fold<int>(0, (acc, d) => acc + d.exercises.length);
                        return ListTile(
                          leading: const Icon(Icons.event_note, color: Colors.teal),
                          title: Text(plan.name),
                          subtitle: Text(
                            '${plan.days.length} day${plan.days.length == 1 ? '' : 's'} · $totalExercises exercise${totalExercises == 1 ? '' : 's'}',
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SessionEditScreen(
                                  workout: _planToWorkout(plan),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Workout _planToWorkout(WorkoutPlan plan) {
  final exercises = <Exercise>[];
  var order = 0;
  for (final day in plan.days) {
    for (final ex in day.exercises) {
      exercises.add(Exercise(
        id: '${plan.id}_$order',
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        weight: ex.weight,
        notes: ex.notes,
        order: order,
        videoUrl: ex.videoUrl,
      ));
      order++;
    }
  }
  return Workout(
    id: plan.id,
    name: plan.name,
    description: plan.description,
    type: 'plan',
    exercises: exercises,
    createdAt: plan.createdAt,
    updatedAt: plan.updatedAt,
  );
}
