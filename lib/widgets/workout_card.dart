import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../screens/workout_detail_screen.dart';
import 'video_player.dart';

class WorkoutCard extends StatefulWidget {
  final Workout workout;
  final bool readOnly;

  const WorkoutCard({super.key, required this.workout, this.readOnly = false});

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  final Map<String, GlobalKey<VideoLinkTileState>> _videoKeys = {};

  GlobalKey<VideoLinkTileState> _getVideoKey(String id) {
    return _videoKeys.putIfAbsent(id, () => GlobalKey<VideoLinkTileState>());
  }

  Future<void> _deleteWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text('Are you sure you want to delete "${widget.workout.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .doc(widget.workout.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = [
      '${widget.workout.exercises.length} exercise${widget.workout.exercises.length == 1 ? '' : 's'}',
      if (widget.workout.type.isNotEmpty) widget.workout.type,
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.fitness_center, color: Colors.teal),
        title: Text(widget.workout.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitleParts.join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        children: [
          if (widget.workout.description != null && widget.workout.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.workout.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (widget.workout.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'No exercises defined',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            )
          else
            ...widget.workout.exercises.map((ex) => _ExerciseRow(
              ex: ex, 
              videoKey: _getVideoKey(ex.id)
            )),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Details'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: widget.workout, readOnly: widget.readOnly)),
                  ),
                ),
                if (!widget.readOnly) ...[
                  const SizedBox(width: 4),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: () => _deleteWorkout(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final dynamic ex;
  final GlobalKey<VideoLinkTileState> videoKey;
  const _ExerciseRow({required this.ex, required this.videoKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVideo = ex.videoUrl != null && (ex.videoUrl as String).isNotEmpty;
    final hasNotes = ex.notes != null && (ex.notes as String).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasVideo ? () => videoKey.currentState?.toggleExpand() : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '• ${ex.name}  ${ex.sets}×${ex.reps ?? '—'}${ex.weight != null ? ' @ ${ex.weight}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (hasVideo)
                    Icon(Icons.videocam_outlined, size: 18, color: Colors.teal[700]),
                ],
              ),
            ),
          ),
          if (hasNotes)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2, bottom: 4),
              child: Text(
                ex.notes as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (hasVideo)
            VideoLinkTile(
              key: videoKey,
              url: ex.videoUrl as String,
              title: 'Reference: ${ex.name}',
            ),
        ],
      ),
    );
  }
}
