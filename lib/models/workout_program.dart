import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutProgram {
  final String id;
  final String name;
  final String? description;
  final List<String> workoutIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutProgram({
    required this.id,
    required this.name,
    this.description,
    this.workoutIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'workoutIds': workoutIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory WorkoutProgram.fromMap(String id, Map<String, dynamic> data) {
    return WorkoutProgram(
      id: id,
      name: data['name'] ?? '',
      description: data['description'],
      workoutIds: List<String>.from(data['workoutIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
