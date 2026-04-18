import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
import '../services/exercise_video_service.dart';
import '../widgets/recorded_video_tile.dart';
import '../widgets/video_player.dart';

class SessionEditScreen extends StatefulWidget {
  final Workout? workout;
  final WorkoutSession? session;

  const SessionEditScreen({super.key, this.workout, this.session});

  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  late List<SessionEntry> _entries;
  late TextEditingController _notesController;
  late String _sessionDocId;
  bool _loading = false;
  final Map<String, GlobalKey<VideoLinkTileState>> _videoKeys = {};
  final Map<String, double> _uploading = {};
  final ExerciseVideoService _videoService = ExerciseVideoService();

  CollectionReference<Map<String, dynamic>> get _sessionsRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions');
  }

  GlobalKey<VideoLinkTileState> _getVideoKey(String id) {
    return _videoKeys.putIfAbsent(id, () => GlobalKey<VideoLinkTileState>());
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.session?.notes ?? '');

    if (widget.session != null) {
      _sessionDocId = widget.session!.id;
      _entries = List.from(widget.session!.entries);
      if (_entries.isEmpty) {
        _loadEntriesFromSubcollection(_sessionDocId);
      }
    } else {
      _sessionDocId = _sessionsRef.doc().id;
      if (widget.workout != null) {
        _entries = widget.workout!.exercises
            .map((ex) => SessionEntry(
                  id: _sessionsRef.doc().collection('entries').doc().id,
                  exerciseName: ex.name,
                  sets: List.generate(
                    ex.sets,
                    (_) => SetData(reps: ex.reps ?? 0, weight: ex.weight),
                  ),
                  order: ex.order,
                  videoUrl: ex.videoUrl,
                ))
            .toList();
      } else {
        _entries = [];
      }
    }
  }

  Future<void> _loadEntriesFromSubcollection(String sessionId) async {
    final snap = await _sessionsRef
        .doc(sessionId)
        .collection('entries')
        .orderBy('order')
        .get();
    if (!mounted) return;
    setState(() {
      _entries = snap.docs
          .map((d) => SessionEntry.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final sessionRef = _sessionsRef.doc(_sessionDocId);
      final sessionData = <String, dynamic>{
        'planId': widget.workout?.id ?? widget.session?.planId,
        'planName': widget.workout?.name ?? widget.session?.planName,
        'notes': _notesController.text,
        'completedAt':
            widget.session?.completedAt ?? FieldValue.serverTimestamp(),
        if (widget.session == null) 'startedAt': FieldValue.serverTimestamp(),
        // Clean up stale inline entries field from older clients.
        'entries': FieldValue.delete(),
      };

      await sessionRef.set(sessionData, SetOptions(merge: true));

      // Replace entries subcollection (simplest correct behavior for v1).
      final existing = await sessionRef.collection('entries').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (var i = 0; i < _entries.length; i++) {
        final e = _entries[i];
        batch.set(
          sessionRef.collection('entries').doc(e.id),
          {
            'exerciseName': e.exerciseName,
            'sets': e.sets.map((s) => s.toMap()).toList(),
            'notes': e.notes,
            'order': i,
            'videoUrl': e.videoUrl,
            'recordedVideoUrl': e.recordedVideoUrl,
            'recordedAt': e.recordedAt != null
                ? Timestamp.fromDate(e.recordedAt!)
                : null,
            'recordedDurationMs': e.recordedDurationMs,
          },
        );
      }
      await batch.commit();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attachVideo(int entryIndex, ImageSource source) async {
    final entry = _entries[entryIndex];
    try {
      final XFile? file = source == ImageSource.camera
          ? await _videoService.pickFromCamera()
          : await _videoService.pickFromGallery();
      if (file == null) return;

      setState(() => _uploading[entry.id] = 0);
      final result = await _videoService.upload(
        sessionId: _sessionDocId,
        entryDocId: entry.id,
        file: file,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _uploading[entry.id] = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _uploading.remove(entry.id);
        _entries[entryIndex] = entry.copyWith(
          recordedVideoUrl: result.downloadUrl,
          recordedAt: DateTime.now(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clip uploaded. Saving will share it with your coach.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading.remove(entry.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  void _showVideoActions(int entryIndex) {
    final entry = _entries[entryIndex];
    final hasRecorded =
        entry.recordedVideoUrl != null && entry.recordedVideoUrl!.isNotEmpty;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(hasRecorded ? 'Replace with new recording' : 'Record video'),
                onTap: () {
                  Navigator.pop(ctx);
                  _attachVideo(entryIndex, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(hasRecorded ? 'Replace from gallery' : 'Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _attachVideo(entryIndex, ImageSource.gallery);
                },
              ),
              if (hasRecorded)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove clip',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _entries[entryIndex] = SessionEntry(
                        id: entry.id,
                        exerciseName: entry.exerciseName,
                        sets: entry.sets,
                        notes: entry.notes,
                        order: entry.order,
                        videoUrl: entry.videoUrl,
                        // recordedVideoUrl, recordedAt, recordedDurationMs omitted = cleared
                      );
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? 'Log Session' : 'Edit Session'),
        actions: [
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.workout != null || widget.session?.planName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.workout?.name ?? widget.session?.planName ?? '',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.teal),
              ),
            ),
          ..._entries
              .asMap()
              .entries
              .map((entry) => _buildEntryEditor(entry.key, entry.value)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
                labelText: 'Session Notes', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEntryEditor(int index, SessionEntry entry) {
    final hasReferenceVideo =
        entry.videoUrl != null && entry.videoUrl!.isNotEmpty;
    final hasRecorded =
        entry.recordedVideoUrl != null && entry.recordedVideoUrl!.isNotEmpty;
    final uploadProgress = _uploading[entry.id];
    final isUploading = uploadProgress != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(entry.exerciseName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasReferenceVideo)
                  IconButton(
                    tooltip: 'Reference video',
                    icon: const Icon(Icons.ondemand_video_outlined,
                        color: Colors.teal),
                    onPressed: () =>
                        _getVideoKey(entry.id).currentState?.toggleExpand(),
                  ),
                IconButton(
                  tooltip: hasRecorded ? 'Manage clip' : 'Record clip for coach',
                  icon: Icon(
                    hasRecorded
                        ? Icons.movie_creation
                        : Icons.fiber_manual_record,
                    color: hasRecorded ? Colors.teal : Colors.redAccent,
                  ),
                  onPressed: isUploading ? null : () => _showVideoActions(index),
                ),
              ],
            ),
          ),
          if (hasReferenceVideo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: VideoLinkTile(
                key: _getVideoKey(entry.id),
                url: entry.videoUrl,
                title: 'Reference Video',
              ),
            ),
          if (isUploading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Uploading clip… ${(uploadProgress * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: uploadProgress),
                ],
              ),
            )
          else if (hasRecorded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RecordedVideoTile(
                url: entry.recordedVideoUrl!,
                title: 'Your Clip',
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Column(
              children: entry.sets.asMap().entries.map((setEntry) {
                final setIndex = setEntry.key;
                final setData = setEntry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                          radius: 12,
                          child: Text('${setIndex + 1}',
                              style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: setData.reps.toString(),
                          decoration: const InputDecoration(
                              labelText: 'Reps', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            _entries[index].sets[setIndex] = SetData(
                              reps: int.tryParse(v) ?? 0,
                              weight: setData.weight,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: setData.weight ?? '',
                          decoration: const InputDecoration(
                              labelText: 'Weight', isDense: true),
                          onChanged: (v) {
                            _entries[index].sets[setIndex] = SetData(
                              reps: setData.reps,
                              weight: v,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
