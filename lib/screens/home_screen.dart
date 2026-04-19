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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'newProgramFab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgramEditScreen()),
            ),
            tooltip: 'New Program',
            child: const Icon(Icons.create_new_folder_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'startWorkoutFabPrograms',
            onPressed: () => showStartWorkoutSheet(context),
            tooltip: 'Start Workout',
            child: const Icon(Icons.play_arrow),
          ),
        ],
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
        heroTag: 'startWorkoutFabSessions',
        onPressed: () => showStartWorkoutSheet(context),
        tooltip: 'Start Workout',
        child: const Icon(Icons.play_arrow),
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

Future<void> showStartWorkoutSheet(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => _StartWorkoutPicker(
        uid: uid,
        scrollController: scrollController,
      ),
    ),
  );
}

class _StartWorkoutPicker extends StatelessWidget {
  final String uid;
  final ScrollController scrollController;

  const _StartWorkoutPicker({
    required this.uid,
    required this.scrollController,
  });

  Future<_PickerData> _loadData() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('users').doc(uid).collection('programs').get(),
      firestore.collection('users').doc(uid).collection('plans').get(),
    ]);
    final programs = <String, WorkoutProgram>{
      for (final doc in results[0].docs)
        doc.id: WorkoutProgram.fromMap(doc.id, doc.data()),
    };
    final entries = results[1].docs.map((d) {
      final data = d.data();
      return _PlanEntry(
        programId: data['programId'] as String?,
        plan: WorkoutPlan.fromMap(d.id, data),
      );
    }).toList();
    return _PickerData(programs: programs, plans: entries);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_PickerData>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        if (data.plans.isEmpty) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Text('Start a workout', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              Text(
                'You have no workouts yet. Create a program and add a workout to log a session against it.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          );
        }

        final grouped = <String, List<WorkoutPlan>>{};
        for (final entry in data.plans) {
          final key = entry.programId ?? '';
          (grouped[key] ??= []).add(entry.plan);
        }
        final groupKeys = grouped.keys.toList()
          ..sort((a, b) {
            final aName = data.programs[a]?.name ?? '~';
            final bName = data.programs[b]?.name ?? '~';
            return aName.toLowerCase().compareTo(bName.toLowerCase());
          });

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Start a workout',
                  style: theme.textTheme.titleLarge),
            ),
            for (final key in groupKeys) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  data.programs[key]?.name ?? 'Unassigned',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final plan in grouped[key]!)
                ListTile(
                  leading:
                      const Icon(Icons.fitness_center, color: Colors.teal),
                  title: Text(plan.name),
                  subtitle: Text(_planSubtitle(plan)),
                  onTap: () => _onPlanSelected(
                    context,
                    plan,
                    data.programs[key],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  String _planSubtitle(WorkoutPlan plan) {
    final dayCount = plan.days.length;
    final exCount =
        plan.days.fold<int>(0, (sum, d) => sum + d.exercises.length);
    if (dayCount == 0) return 'No days defined';
    return '$dayCount day${dayCount == 1 ? '' : 's'} · '
        '$exCount exercise${exCount == 1 ? '' : 's'}';
  }

  Future<void> _onPlanSelected(
    BuildContext context,
    WorkoutPlan plan,
    WorkoutProgram? program,
  ) async {
    if (plan.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This workout has no days yet.')),
      );
      return;
    }
    WorkoutDay? day;
    if (plan.days.length == 1) {
      day = plan.days.first;
    } else {
      day = await showModalBottomSheet<WorkoutDay>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pick a day for ${plan.name}',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final d in plan.days)
                ListTile(
                  leading: const Icon(Icons.today_outlined),
                  title: Text(d.name.isEmpty ? 'Day' : d.name),
                  subtitle: Text(
                    '${d.exercises.length} '
                    'exercise${d.exercises.length == 1 ? '' : 's'}',
                  ),
                  onTap: () => Navigator.pop(ctx, d),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
    if (day == null || !context.mounted) return;

    final workout = _workoutFromPlanDay(
      plan: plan,
      day: day,
      programId: program?.id,
    );
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionEditScreen(workout: workout),
      ),
    );
  }

  Workout _workoutFromPlanDay({
    required WorkoutPlan plan,
    required WorkoutDay day,
    String? programId,
  }) {
    final exercises = day.exercises.asMap().entries.map((entry) {
      final i = entry.key;
      final ex = entry.value;
      return Exercise(
        id: '${plan.id}_$i',
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        weight: ex.weight,
        notes: ex.notes,
        videoUrl: ex.videoUrl,
        order: i,
      );
    }).toList();
    final name =
        plan.days.length > 1 ? '${plan.name} — ${day.name}' : plan.name;
    return Workout(
      id: plan.id,
      programId: programId,
      name: name,
      description: plan.description,
      type: 'plan',
      exercises: exercises,
    );
  }
}

class _PickerData {
  final Map<String, WorkoutProgram> programs;
  final List<_PlanEntry> plans;
  _PickerData({required this.programs, required this.plans});
}

class _PlanEntry {
  final String? programId;
  final WorkoutPlan plan;
  _PlanEntry({required this.programId, required this.plan});
}
