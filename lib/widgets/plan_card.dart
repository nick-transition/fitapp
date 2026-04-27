import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_plan.dart';
import 'video_player.dart';

class PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final bool readOnly;

  const PlanCard({super.key, required this.plan, this.readOnly = false});

  Future<void> _deletePlan(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Delete "${plan.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plans')
          .doc(plan.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalExercises = plan.days.fold<int>(0, (sum, d) => sum + d.exercises.length);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.event_note, color: Colors.teal),
        title: Row(
          children: [
            Expanded(
              child: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (!readOnly)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deletePlan(context),
                tooltip: 'Delete Plan',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        subtitle: Text(
          '${plan.days.length} day${plan.days.length == 1 ? '' : 's'} · $totalExercises exercise${totalExercises == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          if (plan.description != null && plan.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  plan.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (plan.days.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('No days defined', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            )
          else
            ...plan.days.asMap().entries.expand((entry) {
              final i = entry.key;
              final day = entry.value;
              return [
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _DayHeader(day: day),
                ...day.exercises.map((ex) => _ExerciseRow(ex: ex)),
              ];
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final WorkoutDay day;
  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              day.name,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${day.exercises.length} exercise${day.exercises.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final PlanExercise ex;
  const _ExerciseRow({required this.ex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ${ex.name}  ${ex.sets}×${ex.reps ?? '—'}${ex.weight != null ? ' @ ${ex.weight}' : ''}',
            style: theme.textTheme.bodySmall,
          ),
          if (ex.notes != null && ex.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
              child: Text(
                ex.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: VideoLinkTile(
                url: ex.videoUrl,
                title: ex.name,
              ),
            ),
        ],
      ),
    );
  }
}
