import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../widgets/video_player.dart';
import 'workout_edit_screen.dart';
import 'session_edit_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final Map<String, GlobalKey<VideoLinkTileState>> _videoKeys = {};

  GlobalKey<VideoLinkTileState> _getVideoKey(String id) {
    return _videoKeys.putIfAbsent(id, () => GlobalKey<VideoLinkTileState>());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkoutEditScreen(workout: widget.workout)),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(widget.workout.type),
                      avatar: const Icon(Icons.fitness_center, size: 16),
                    ),
                    if (widget.workout.schedule != null) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(widget.workout.schedule!),
                        avatar: const Icon(Icons.calendar_today, size: 16),
                      ),
                    ],
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionEditScreen(workout: widget.workout),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start'),
                    ),
                  ],
                ),
                if (widget.workout.description != null && widget.workout.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.workout.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (widget.workout.videoUrl != null && widget.workout.videoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  VideoLinkTile(
                    key: _getVideoKey('workout_${widget.workout.id}'),
                    url: widget.workout.videoUrl, 
                    title: 'Workout Video'
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Exercises', style: theme.textTheme.titleLarge),
          ),
          ...widget.workout.exercises.map((ex) => Column(
            children: [
              ListTile(
                title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${ex.sets} sets ${ex.reps != null ? "x ${ex.reps} reps" : ""} ${ex.weight != null ? "@ ${ex.weight}" : ""}'),
                    if (ex.notes != null && ex.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          ex.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: ex.videoUrl != null 
                    ? IconButton(
                        icon: const Icon(Icons.videocam_outlined, color: Colors.teal),
                        onPressed: () => _getVideoKey(ex.id).currentState?.toggleExpand(),
                      )
                    : null,
                onTap: ex.videoUrl != null ? () => _getVideoKey(ex.id).currentState?.toggleExpand() : null,
                isThreeLine: ex.notes != null && ex.notes!.isNotEmpty,
              ),
              if (ex.videoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: VideoLinkTile(
                    key: _getVideoKey(ex.id),
                    url: ex.videoUrl, 
                    title: 'Reference: ${ex.name}'
                  ),
                ),
              const Divider(indent: 16, endIndent: 16),
            ],
          )),
        ],
      ),
    );
  }
}
