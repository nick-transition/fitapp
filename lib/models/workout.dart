import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class Workout {
  final String id;
  final String? programId;
  final String name;
  final String? description;
  final String? videoUrl;
  final String type;
  final String? schedule;
  final List<Exercise> exercises;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Workout({
    required this.id,
    this.programId,
    required this.name,
    this.description,
    this.videoUrl,
    required this.type,
    this.schedule,
    required this.exercises,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'programId': programId,
      'name': name,
      'description': description,
      'videoUrl': videoUrl,
      'type': type,
      'schedule': schedule,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Workout.fromMap(String id, Map<String, dynamic> data) {
    final List<dynamic> exercisesData = data['exercises'] ?? [];
    return Workout(
      id: id,
      programId: data['programId'],
      name: data['name'] ?? '',
      description: data['description'],
      videoUrl: data['videoUrl'],
      type: data['type'] ?? '',
      schedule: data['schedule'],
      exercises: exercisesData
          .asMap()
          .entries
          .map((entry) => Exercise.fromMap(
                entry.key.toString(),
                entry.value as Map<String, dynamic>,
              ))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
