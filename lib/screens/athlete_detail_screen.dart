import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_program.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
import '../widgets/workout_card.dart';
import '../widgets/video_player.dart';
import '../widgets/recorded_video_tile.dart';

class AthleteDetailScreen extends StatelessWidget {
  final String athleteUid;
  final String athleteName;

  const AthleteDetailScreen({
    super.key,
    required this.athleteUid,
    required this.athleteName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(athleteName),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder_copy), text: 'Programs'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
              Tab(icon: Icon(Icons.history), text: 'Sessions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AthleteProgramsTab(athleteUid: athleteUid),
            _AthleteWorkoutsTab(athleteUid: athleteUid),
            _AthleteSessionsTab(athleteUid: athleteUid),
          ],
        ),
      ),
    );
  }
}

class _AthleteProgramsTab extends StatelessWidget {
  final String athleteUid;
  const _AthleteProgramsTab({required this.athleteUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(athleteUid)
          .collection('programs')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No programs', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final program = WorkoutProgram.fromMap(
                docs[index].id, docs[index].data() as Map<String, dynamic>);
            return _ProgramTile(program: program, athleteUid: athleteUid);
          },
        );
      },
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final WorkoutProgram program;
  final String athleteUid;
  const _ProgramTile({required this.program, required this.athleteUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.folder, color: Colors.teal),
        title: Text(program.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: program.description != null
            ? Text(program.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(athleteUid)
                .collection('workouts')
                .where('programId', isEqualTo: program.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No workouts in this program',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final workout = Workout.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>);
                  return _WorkoutExpansionTile(workout: workout);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkoutExpansionTile extends StatelessWidget {
  final Workout workout;
  const _WorkoutExpansionTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.fitness_center, size: 18, color: Colors.teal),
      title: Text(workout.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        '${workout.exercises.length} exercise(s) · ${workout.type}${workout.schedule != null ? ' · ${workout.schedule}' : ''}',
        style: theme.textTheme.bodySmall,
      ),
      children: workout.exercises.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 4, 16, 12),
                child: Text('No exercises defined',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ),
            ]
          : workout.exercises.map((ex) => _AthleteExerciseRow(ex: ex)).toList(),
    );
  }
}

class _AthleteExerciseRow extends StatelessWidget {
  final dynamic ex;
  const _AthleteExerciseRow({required this.ex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVideo = ex.videoUrl != null && (ex.videoUrl as String).isNotEmpty;
    final hasNotes = ex.notes != null && (ex.notes as String).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ${ex.name}  ${ex.sets}×${ex.reps ?? '—'}${ex.weight != null ? ' @ ${ex.weight}' : ''}',
            style: theme.textTheme.bodySmall,
          ),
          if (hasVideo)
            VideoLinkTile(
              url: ex.videoUrl as String,
              title: 'Reference: ${ex.name}',
            ),
          if (hasNotes)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text(
                ex.notes as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AthleteWorkoutsTab extends StatelessWidget {
  final String athleteUid;
  const _AthleteWorkoutsTab({required this.athleteUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(athleteUid)
          .collection('workouts')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No workouts', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final workout = Workout.fromMap(
                docs[index].id, docs[index].data() as Map<String, dynamic>);
            return WorkoutCard(workout: workout, readOnly: true);
          },
        );
      },
    );
  }
}

class _AthleteSessionsTab extends StatelessWidget {
  final String athleteUid;
  const _AthleteSessionsTab({required this.athleteUid});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(athleteUid)
          .collection('sessions')
          .orderBy('startedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No sessions yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final session = WorkoutSession.fromMap(
                docs[index].id, docs[index].data() as Map<String, dynamic>);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: session.isCompleted
                      ? Colors.teal.withAlpha(30)
                      : Colors.orange.withAlpha(30),
                  child: Icon(
                    session.isCompleted ? Icons.check : Icons.schedule,
                    color: session.isCompleted ? Colors.teal : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  session.planName ?? 'Quick Workout',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  session.dayName != null
                      ? '${session.dayName} · ${_formatDate(session.startedAt)}'
                      : _formatDate(session.startedAt),
                ),
                trailing: session.isCompleted
                    ? const Chip(
                        label: Text('Done',
                            style: TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(athleteUid)
                        .collection('sessions')
                        .doc(session.id)
                        .collection('entries')
                        .orderBy('order')
                        .snapshots(),
                    builder: (context, entrySnapshot) {
                      if (entrySnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )),
                        );
                      }
                      if (entrySnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Text('Error loading entries: ${entrySnapshot.error}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.red)),
                        );
                      }
                      final entryDocs = entrySnapshot.data?.docs ?? [];
                      if (entryDocs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Text('No exercises recorded',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey)),
                        );
                      }
                      return Column(
                        children: entryDocs.map((doc) {
                          final entry = SessionEntry.fromMap(
                              doc.id, doc.data() as Map<String, dynamic>);
                          return _SessionEntryTile(entry: entry);
                        }).toList(),
                      );
                    },
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(session.notes!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SessionEntryTile extends StatelessWidget {
  final SessionEntry entry;
  const _SessionEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRecorded =
        entry.recordedVideoUrl != null && entry.recordedVideoUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.exerciseName,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          ...entry.sets.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(
                  'Set ${e.key + 1}: ${e.value.reps} reps'
                  '${e.value.weight != null ? ' @ ${e.value.weight}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              )),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: Text(entry.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            ),
          if (hasRecorded)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: RecordedVideoTile(
                url: entry.recordedVideoUrl!,
                title: 'Athlete Clip',
              ),
            ),
        ],
      ),
    );
  }
}
