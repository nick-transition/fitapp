import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_session.dart';
import '../widgets/recorded_video_tile.dart';
import '../widgets/video_player.dart';

class SessionDetailScreen extends StatefulWidget {
  final WorkoutSession session;
  final bool readOnly;
  final String? athleteUid;

  const SessionDetailScreen({
    super.key,
    required this.session,
    this.readOnly = false,
    this.athleteUid,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final Map<String, GlobalKey<VideoLinkTileState>> _videoKeys = {};

  GlobalKey<VideoLinkTileState> _getVideoKey(String id) {
    return _videoKeys.putIfAbsent(id, () => GlobalKey<VideoLinkTileState>());
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $amPm';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = widget.athleteUid ?? FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.planName ?? 'Quick Workout'),
        actions: [
          if (widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Coach View', style: TextStyle(fontSize: 12)),
                backgroundColor: theme.colorScheme.secondaryContainer,
                side: BorderSide.none,
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(widget.session.startedAt),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (widget.session.startedAt != null &&
                    widget.session.completedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ${_formatDuration(widget.session.startedAt!, widget.session.completedAt!)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                if (widget.session.scheduledAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event,
                          size: 16, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        'Scheduled: ${_formatDate(widget.session.scheduledAt)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.session.isScheduled) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: const Text('Upcoming'),
                    backgroundColor: theme.colorScheme.tertiary.withAlpha(30),
                    side: BorderSide.none,
                  ),
                ],
                if (widget.session.notes != null && widget.session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.session.notes!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          // Exercises + Journal in a single scrollable area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('sessions')
                  .doc(widget.session.id)
                  .collection('entries')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child:
                        Text('Something went wrong: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final hasJournal = widget.session.journalEntry != null &&
                    widget.session.journalEntry!.isNotEmpty;

                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    // Exercises header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Exercises',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.list, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No exercises recorded',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...docs.map((doc) {
                        final data = doc.data()! as Map<String, dynamic>;
                        final exerciseName =
                            data['exerciseName'] as String? ?? 'Unknown';
                        final sets =
                            (data['sets'] as List<dynamic>?) ?? [];
                        final notes = data['notes'] as String?;
                        final videoUrl = data['videoUrl'] as String?;
                        final recordedVideoUrl =
                            data['recordedVideoUrl'] as String?;
                        final entryId = doc.id;
                        final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
                        final hasRecorded = recordedVideoUrl != null &&
                            recordedVideoUrl.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: hasVideo ? () => _getVideoKey(entryId).currentState?.toggleExpand() : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exerciseName,
                                          style:
                                              theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (hasVideo)
                                        IconButton(
                                          icon: const Icon(Icons.videocam_outlined, color: Colors.teal),
                                          onPressed: () => _getVideoKey(entryId).currentState?.toggleExpand(),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  if (hasVideo)
                                    VideoLinkTile(
                                      key: _getVideoKey(entryId),
                                      url: videoUrl,
                                      title: 'Reference Video',
                                    ),
                                  if (hasRecorded)
                                    RecordedVideoTile(
                                      url: recordedVideoUrl,
                                      title: 'Your Clip',
                                    ),
                                  const SizedBox(height: 8),
                                  ...sets.asMap().entries.map((entry) {
                                    final setIndex = entry.key + 1;
                                    final setData =
                                        entry.value as Map<String, dynamic>;
                                    final reps = setData['reps'] ?? 0;
                                    final weight = setData['weight']?.toString();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              'S$setIndex',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme
                                                    .colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$reps reps',
                                            style:
                                                theme.textTheme.bodySmall,
                                          ),
                                          if (weight != null && weight.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '@ $weight',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                  if (notes != null &&
                                      notes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      notes,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    // Journal entry section
                    if (hasJournal) ...[
                      const Divider(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.book,
                                size: 20,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Journal',
                              style:
                                  theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            widget.session.journalEntry!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
