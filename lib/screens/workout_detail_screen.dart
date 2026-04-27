import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../widgets/video_player.dart';
import 'workout_edit_screen.dart';
import 'session_edit_screen.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  final bool readOnly;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        actions: [
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit workout',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WorkoutEditScreen(workout: workout)),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (workout.description != null && workout.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                workout.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (workout.videoUrl != null && workout.videoUrl!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VideoLinkTile(
                url: workout.videoUrl,
                title: 'Workout Reference Video',
              ),
            ),
          ],
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionEditScreen(workout: workout),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Session'),
              ),
            ),
          ...workout.exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final ex = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ex.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${ex.sets} sets × ${ex.reps ?? '—'} reps',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (ex.weight != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '@ ${ex.weight}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (ex.notes != null && ex.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ex.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      VideoLinkTile(
                        url: ex.videoUrl,
                        title: ex.name,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
