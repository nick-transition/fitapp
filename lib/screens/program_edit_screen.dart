import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_program.dart';

class ProgramEditScreen extends StatefulWidget {
  final WorkoutProgram? program;

  const ProgramEditScreen({super.key, this.program});

  @override
  State<ProgramEditScreen> createState() => _ProgramEditScreenState();
}

class _ProgramEditScreenState extends State<ProgramEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program?.name ?? '');
    _descriptionController = TextEditingController(text: widget.program?.description ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        if (widget.program == null) 'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.program == null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('programs')
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('programs')
            .doc(widget.program!.id)
            .update(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving program: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program == null ? 'New Program' : 'Edit Program'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                hintText: 'e.g., 12-Week Transformation',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
