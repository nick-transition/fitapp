import 'package:cloud_firestore/cloud_firestore.dart';

/// A canonical exercise definition in the global exercise library
/// (top-level `exerciseLibrary` collection).
///
/// Library entries hold the shared definition (name, description, video,
/// tags). Per-plan prescription (sets, reps, weight, rest) stays on the
/// embedded [Exercise], which can point back here via `libraryExerciseId`.
class LibraryExercise {
  final String id;
  final String name;
  final String? description;
  final String? videoUrl; // YouTube or reference link
  final List<String> tags; // muscle group, equipment, movement pattern
  final List<String> aliases; // alternative names, for search
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LibraryExercise({
    required this.id,
    required this.name,
    this.description,
    this.videoUrl,
    this.tags = const [],
    this.aliases = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'videoUrl': videoUrl,
      'tags': tags,
      'aliases': aliases,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory LibraryExercise.fromMap(String id, Map<String, dynamic> data) {
    return LibraryExercise(
      id: id,
      name: data['name'] ?? '',
      description: data['description'],
      videoUrl: data['videoUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      aliases: List<String>.from(data['aliases'] ?? []),
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
