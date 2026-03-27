import 'package:cloud_firestore/cloud_firestore.dart';

class PlanExercise {
  final String name;
  final int sets;
  final int? reps;
  final String? weight;
  final String? notes;

  PlanExercise({
    required this.name,
    required this.sets,
    this.reps,
    this.weight,
    this.notes,
  });

  factory PlanExercise.fromMap(Map<String, dynamic> data) {
    return PlanExercise(
      name: data['name'] ?? '',
      sets: data['sets'] ?? 0,
      reps: data['reps'],
      weight: data['weight']?.toString(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'notes': notes,
      };
}

class WorkoutDay {
  final String name;
  final List<PlanExercise> exercises;

  WorkoutDay({required this.name, required this.exercises});

  factory WorkoutDay.fromMap(Map<String, dynamic> data) {
    final List<dynamic> exData = data['exercises'] ?? [];
    return WorkoutDay(
      name: data['name'] ?? '',
      exercises: exData.map((e) => PlanExercise.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };
}

class WorkoutPlan {
  final String id;
  final String name;
  final String? description;
  final List<WorkoutDay> days;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutPlan({
    required this.id,
    required this.name,
    this.description,
    this.days = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory WorkoutPlan.fromMap(String id, Map<String, dynamic> data) {
    final List<dynamic> daysData = data['days'] ?? [];
    return WorkoutPlan(
      id: id,
      name: data['name'] ?? '',
      description: data['description'],
      days: daysData.map((d) => WorkoutDay.fromMap(d as Map<String, dynamic>)).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'days': days.map((d) => d.toMap()).toList(),
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
