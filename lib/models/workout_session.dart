import 'package:cloud_firestore/cloud_firestore.dart';

class SetData {
  final int reps;
  final String? weight;

  SetData({required this.reps, this.weight});

  factory SetData.fromMap(Map<String, dynamic> data) {
    return SetData(
      reps: data['reps'] ?? 0,
      weight: data['weight']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
    };
  }
}

class SessionEntry {
  final String id;
  final String exerciseName;
  final List<SetData> sets;
  final String? notes;
  final int order;
  final String? videoUrl;

  SessionEntry({
    required this.id,
    required this.exerciseName,
    required this.sets,
    this.notes,
    required this.order,
    this.videoUrl,
  });

  factory SessionEntry.fromMap(String id, Map<String, dynamic> data) {
    return SessionEntry(
      id: id,
      exerciseName: data['exerciseName'] ?? '',
      sets: (data['sets'] as List<dynamic>?)
              ?.map((s) => SetData.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      notes: data['notes'],
      order: data['order'] ?? 0,
      videoUrl: data['videoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
      'order': order,
      'videoUrl': videoUrl,
    };
  }
}

class WorkoutSession {
  final String id;
  final String? planId;
  final String? planName;
  final String? dayId;
  final String? dayName;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? scheduledAt;
  final String? notes;
  final String? journalEntry;
  final List<SessionEntry> entries;

  WorkoutSession({
    required this.id,
    this.planId,
    this.planName,
    this.dayId,
    this.dayName,
    this.startedAt,
    this.completedAt,
    this.scheduledAt,
    this.notes,
    this.journalEntry,
    this.entries = const [],
  });

  bool get isScheduled => scheduledAt != null && completedAt == null;
  bool get isCompleted => completedAt != null;
  DateTime? get calendarDate => scheduledAt ?? startedAt;

  factory WorkoutSession.fromMap(String id, Map<String, dynamic> data) {
    final List<dynamic> entriesData = data['entries'] ?? [];
    return WorkoutSession(
      id: id,
      planId: data['planId'],
      planName: data['planName'],
      dayId: data['dayId'],
      dayName: data['dayName'],
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      journalEntry: data['journalEntry'],
      entries: entriesData
          .asMap()
          .entries
          .map((entry) => SessionEntry.fromMap(
                entry.key.toString(),
                entry.value as Map<String, dynamic>,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planName': planName,
      'dayId': dayId,
      'dayName': dayName,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'notes': notes,
      'journalEntry': journalEntry,
      'entries': entries.map((e) => e.toMap()).toList(),
    };
  }
}
