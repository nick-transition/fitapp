import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_program.dart';
import '../models/workout_plan.dart';
import '../widgets/plan_card.dart';

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
      appBar: AppBar(title: Text(program.name)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('plans')
            .where('programId', isEqualTo: program.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          final hasDescription =
              program.description != null && program.description!.isNotEmpty;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: 2 + (docs.isEmpty ? 1 : docs.length),
            itemBuilder: (context, index) {
              if (index == 0) {
                if (!hasDescription) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    program.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                );
              }
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Workouts', style: theme.textTheme.titleMedium),
                );
              }
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'No workouts yet — ask your AI coach to create one.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                );
              }
              final doc = docs[index - 2];
              final plan = WorkoutPlan.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              return PlanCard(plan: plan);
            },
          );
        },
      ),
    );
  }
}
