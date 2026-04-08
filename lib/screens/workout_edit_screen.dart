import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../utils/youtube_utils.dart';

class WorkoutEditScreen extends StatefulWidget {
  final Workout? workout;

  const WorkoutEditScreen({super.key, this.workout});

  @override
  State<WorkoutEditScreen> createState() => _WorkoutEditScreenState();
}

class _WorkoutEditScreenState extends State<WorkoutEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _videoUrlController;
  late List<Exercise> _exercises;
  String? _selectedProgramId;
  late String _workoutType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout?.name ?? '');
    _descriptionController = TextEditingController(text: widget.workout?.description ?? '');
    _videoUrlController = TextEditingController(text: widget.workout?.videoUrl ?? '');
    _exercises = widget.workout?.exercises != null ? List.from(widget.workout!.exercises) : [];
    _selectedProgramId = widget.workout?.programId;
    _workoutType = widget.workout?.type.isNotEmpty == true ? widget.workout!.type : 'custom';
  }

  void _addExercise() {
    setState(() {
      _exercises.add(Exercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        sets: 3,
        reps: 10,
        order: _exercises.length,
      ));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final workoutData = {
        'programId': _selectedProgramId,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'videoUrl': _videoUrlController.text.isNotEmpty 
            ? YouTubeUtils.normalizeUrl(_videoUrlController.text) 
            : null,
        'type': _workoutType,
        'exercises': _exercises.map((ex) {
          final exMap = ex.toMap();
          if (exMap['videoUrl'] != null && exMap['videoUrl'].toString().isNotEmpty) {
            exMap['videoUrl'] = YouTubeUtils.normalizeUrl(exMap['videoUrl'].toString());
          }
          return exMap;
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (widget.workout == null) 'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.workout == null) {
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .add(workoutData);
        
        if (_selectedProgramId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('programs')
              .doc(_selectedProgramId)
              .update({
            'workoutIds': FieldValue.arrayUnion([docRef.id]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .doc(widget.workout!.id)
            .update(workoutData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout == null ? 'New Workout' : 'Edit Workout'),
        actions: [
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('programs')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                final programs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedProgramId,
                  decoration: const InputDecoration(labelText: 'Program (Optional)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Program (Standalone)')),
                    ...programs.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.get('name')),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedProgramId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Workout Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Workout Video URL (YouTube, optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.play_circle_outline),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(onPressed: _addExercise, icon: const Icon(Icons.add), label: const Text('Add Exercise')),
              ],
            ),
            const Divider(),
            ..._exercises.asMap().entries.map((entry) => _buildExerciseEditor(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseEditor(int index, Exercise ex) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: ex.name,
                    decoration: const InputDecoration(hintText: 'Exercise Name', isDense: true),
                    onChanged: (v) {
                      _exercises[index] = Exercise(
                        id: ex.id,
                        name: v,
                        sets: ex.sets,
                        reps: ex.reps,
                        weight: ex.weight,
                        notes: ex.notes,
                        videoUrl: ex.videoUrl,
                        order: ex.order,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: ex.sets.toString(),
                    decoration: const InputDecoration(hintText: 'Sets', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      _exercises[index] = Exercise(
                        id: ex.id,
                        name: ex.name,
                        sets: int.tryParse(v) ?? 0,
                        reps: ex.reps,
                        weight: ex.weight,
                        notes: ex.notes,
                        videoUrl: ex.videoUrl,
                        order: ex.order,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.video_collection_outlined, size: 20),
                  onPressed: () => _showVideoUrlDialog(index, ex),
                  color: ex.videoUrl != null && ex.videoUrl!.isNotEmpty ? Colors.teal : Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _exercises.removeAt(index)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoUrlDialog(int index, Exercise ex) {
    final controller = TextEditingController(text: ex.videoUrl ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video URL: ${ex.name}'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'YouTube or Reference link'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _exercises[index] = Exercise(
                  id: ex.id,
                  name: ex.name,
                  sets: ex.sets,
                  reps: ex.reps,
                  weight: ex.weight,
                  notes: ex.notes,
                  videoUrl: controller.text,
                  order: ex.order,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
