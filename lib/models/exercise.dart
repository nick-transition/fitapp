class Exercise {
  final String id;
  final String name;
  final int sets;
  final int? reps;
  final String? weight; // Changed to String to support "135 lbs" or "Bodyweight"
  final int? durationSeconds;
  final int? restSeconds;
  final String? notes;
  final int order;
  final List<String> tags;
  final String? videoUrl; // YouTube or reference link

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
    required this.order,
    this.tags = const [],
    this.videoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'durationSeconds': durationSeconds,
      'restSeconds': restSeconds,
      'notes': notes,
      'order': order,
      'tags': tags,
      'videoUrl': videoUrl,
    };
  }

  factory Exercise.fromMap(String id, Map<String, dynamic> data) {
    return Exercise(
      id: id,
      name: data['name'] ?? '',
      sets: data['sets'] ?? 0,
      reps: data['reps'],
      weight: data['weight']?.toString(),
      durationSeconds: data['durationSeconds'],
      restSeconds: data['restSeconds'],
      notes: data['notes'],
      order: data['order'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      videoUrl: data['videoUrl'],
    );
  }
}
