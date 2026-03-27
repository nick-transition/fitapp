import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
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
  bool _loading = false;
  final Map<String, GlobalKey<VideoLinkTileState>> _videoKeys = {};

  GlobalKey<VideoLinkTileState> _getVideoKey(String id) {
    return _videoKeys.putIfAbsent(id, () => GlobalKey<VideoLinkTileState>());
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.session?.notes ?? '');
    
    if (widget.session != null) {
      _entries = List.from(widget.session!.entries);
    } else if (widget.workout != null) {
      // Create new session from workout
      _entries = widget.workout!.exercises.map((ex) => SessionEntry(
        id: ex.id,
        exerciseName: ex.name,
        sets: List.generate(ex.sets, (_) => SetData(reps: ex.reps ?? 0, weight: ex.weight)),
        order: ex.order,
        videoUrl: ex.videoUrl,
      )).toList();
    } else {
      _entries = [];
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final sessionData = {
        'planId': widget.workout?.id ?? widget.session?.planId,
        'planName': widget.workout?.name ?? widget.session?.planName,
        'notes': _notesController.text,
        'entries': _entries.map((e) => e.toMap()).toList(),
        'completedAt': widget.session?.completedAt ?? FieldValue.serverTimestamp(),
        if (widget.session == null) 'startedAt': FieldValue.serverTimestamp(),
      };

      if (widget.session == null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .add(sessionData);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .doc(widget.session!.id)
            .update(sessionData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving session: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? 'Log Session' : 'Edit Session'),
        actions: [
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal),
              ),
            ),
          ..._entries.asMap().entries.map((entry) => _buildEntryEditor(entry.key, entry.value)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Session Notes', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEntryEditor(int index, SessionEntry entry) {
    final hasVideo = entry.videoUrl != null && entry.videoUrl!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(entry.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: hasVideo
                ? IconButton(
                    icon: const Icon(Icons.videocam_outlined, color: Colors.teal),
                    onPressed: () => _getVideoKey(entry.id).currentState?.toggleExpand(),
                  )
                : null,
            onTap: hasVideo
                ? () => _getVideoKey(entry.id).currentState?.toggleExpand()
                : null,
          ),
          if (hasVideo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: VideoLinkTile(
                key: _getVideoKey(entry.id),
                url: entry.videoUrl, 
                title: 'Reference Video'
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
                      CircleAvatar(radius: 12, child: Text('${setIndex + 1}', style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: setData.reps.toString(),
                          decoration: const InputDecoration(labelText: 'Reps', isDense: true),
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
                          decoration: const InputDecoration(labelText: 'Weight', isDense: true),
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
