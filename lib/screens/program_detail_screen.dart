import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_program.dart';
import '../models/workout.dart';
import '../widgets/workout_card.dart';
import 'workout_edit_screen.dart';

class ProgramDetailScreen extends StatelessWidget {
  final WorkoutProgram program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not authenticated')));
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Workout to Program',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutEditScreen(
                  workout: Workout(
                    id: '',
                    name: '',
                    type: 'strength',
                    exercises: [],
                    programId: program.id,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (program.description != null && program.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                program.description!,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Workouts in this Program', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('workouts')
                  .where('programId', isEqualTo: program.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No workouts in this program yet.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final workout = Workout.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
                    return WorkoutCard(workout: workout);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
