import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  String _formatDuration(int seconds) {
    if (seconds >= 60) {
      final min = seconds ~/ 60;
      final sec = seconds % 60;
      return sec > 0 ? '${min}m ${sec}s' : '${min}m';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildDetail(
                  context,
                  Icons.fitness_center,
                  exercise.reps != null
                      ? '${exercise.sets} x ${exercise.reps} reps'
                      : '${exercise.sets} sets',
                ),
                if (exercise.weight != null)
                  _buildDetail(
                    context,
                    Icons.scale,
                    exercise.weight!,
                  ),
                if (exercise.durationSeconds != null)
                  _buildDetail(
                    context,
                    Icons.timer,
                    _formatDuration(exercise.durationSeconds!),
                  ),
                if (exercise.restSeconds != null)
                  _buildDetail(
                    context,
                    Icons.pause_circle_outline,
                    '${_formatDuration(exercise.restSeconds!)} rest',
                  ),
              ],
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                exercise.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (exercise.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: exercise.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag, style: theme.textTheme.labelSmall),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
