import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/models/exercise.dart';

void main() {
  group('Exercise metadata preservation', () {
    test('toMap and fromMap round-trip preserves all fields', () {
      final original = Exercise(
        id: 'test-1',
        name: 'Front Squat',
        sets: 5,
        reps: 5,
        weight: '225 lbs',
        durationSeconds: 40,
        restSeconds: 90,
        notes: 'Focus on depth',
        order: 0,
        tags: ['legs', 'compound', 'strength'],
        videoUrl: 'https://youtube.com/watch?v=example',
        libraryExerciseId: 'library-squat-1',
      );

      final map = original.toMap();
      final restored = Exercise.fromMap('test-1', map);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.sets, equals(original.sets));
      expect(restored.reps, equals(original.reps));
      expect(restored.weight, equals(original.weight));
      expect(restored.durationSeconds, equals(original.durationSeconds));
      expect(restored.restSeconds, equals(original.restSeconds));
      expect(restored.notes, equals(original.notes));
      expect(restored.order, equals(original.order));
      expect(restored.tags, equals(original.tags));
      expect(restored.videoUrl, equals(original.videoUrl));
      expect(restored.libraryExerciseId, equals(original.libraryExerciseId));
    });

    test('Exercise with null metadata fields round-trips correctly', () {
      final original = Exercise(
        id: 'test-2',
        name: 'Custom Exercise',
        sets: 3,
        reps: 10,
        order: 1,
      );

      final map = original.toMap();
      final restored = Exercise.fromMap('test-2', map);

      expect(restored.durationSeconds, isNull);
      expect(restored.restSeconds, isNull);
      expect(restored.tags, isEmpty);
      expect(restored.libraryExerciseId, isNull);
    });

    test('Name edit preserves all metadata fields', () {
      final original = Exercise(
        id: 'test-3',
        name: 'Squat',
        sets: 3,
        reps: 10,
        weight: '135 lbs',
        durationSeconds: 40,
        restSeconds: 90,
        notes: 'Keep back straight',
        order: 0,
        tags: ['legs'],
        videoUrl: 'https://youtube.com/watch?v=old',
        libraryExerciseId: 'synthetic-library-1',
      );

      final edited = Exercise(
        id: original.id,
        name: 'Front Squat',
        sets: original.sets,
        reps: original.reps,
        weight: original.weight,
        durationSeconds: original.durationSeconds,
        restSeconds: original.restSeconds,
        notes: original.notes,
        order: original.order,
        tags: original.tags,
        videoUrl: original.videoUrl,
        libraryExerciseId: original.libraryExerciseId,
      );

      expect(edited.name, equals('Front Squat'));
      expect(edited.durationSeconds, equals(40));
      expect(edited.restSeconds, equals(90));
      expect(edited.tags, equals(['legs']));
      expect(edited.libraryExerciseId, equals('synthetic-library-1'));
      expect(edited.weight, equals('135 lbs'));
      expect(edited.notes, equals('Keep back straight'));
      expect(edited.videoUrl, equals('https://youtube.com/watch?v=old'));
    });

    test('Sets edit preserves all metadata fields', () {
      final original = Exercise(
        id: 'test-4',
        name: 'Bench Press',
        sets: 3,
        reps: 10,
        weight: '155 lbs',
        durationSeconds: 45,
        restSeconds: 120,
        notes: 'Control the descent',
        order: 1,
        tags: ['chest', 'push'],
        videoUrl: 'https://youtube.com/watch?v=bench',
        libraryExerciseId: 'library-bench-1',
      );

      final edited = Exercise(
        id: original.id,
        name: original.name,
        sets: 5,
        reps: original.reps,
        weight: original.weight,
        durationSeconds: original.durationSeconds,
        restSeconds: original.restSeconds,
        notes: original.notes,
        order: original.order,
        tags: original.tags,
        videoUrl: original.videoUrl,
        libraryExerciseId: original.libraryExerciseId,
      );

      expect(edited.sets, equals(5));
      expect(edited.durationSeconds, equals(45));
      expect(edited.restSeconds, equals(120));
      expect(edited.tags, equals(['chest', 'push']));
      expect(edited.libraryExerciseId, equals('library-bench-1'));
    });

    test('Video URL edit preserves all metadata fields', () {
      final original = Exercise(
        id: 'test-5',
        name: 'Deadlift',
        sets: 5,
        reps: 5,
        weight: '315 lbs',
        durationSeconds: 60,
        restSeconds: 180,
        notes: 'Brace hard',
        order: 2,
        tags: ['back', 'pull', 'compound'],
        videoUrl: 'https://youtube.com/watch?v=old_deadlift',
        libraryExerciseId: 'library-deadlift-1',
      );

      final edited = Exercise(
        id: original.id,
        name: original.name,
        sets: original.sets,
        reps: original.reps,
        weight: original.weight,
        durationSeconds: original.durationSeconds,
        restSeconds: original.restSeconds,
        notes: original.notes,
        order: original.order,
        tags: original.tags,
        videoUrl: 'https://youtube.com/watch?v=new_deadlift',
        libraryExerciseId: original.libraryExerciseId,
      );

      expect(edited.videoUrl, equals('https://youtube.com/watch?v=new_deadlift'));
      expect(edited.durationSeconds, equals(60));
      expect(edited.restSeconds, equals(180));
      expect(edited.tags, equals(['back', 'pull', 'compound']));
      expect(edited.libraryExerciseId, equals('library-deadlift-1'));
    });

    test('Custom exercise without library reference preserves metadata', () {
      final original = Exercise(
        id: 'custom-1',
        name: 'My Custom Exercise',
        sets: 4,
        reps: 12,
        durationSeconds: 30,
        restSeconds: 60,
        tags: ['custom'],
        libraryExerciseId: null,
        order: 3,
      );

      final edited = Exercise(
        id: original.id,
        name: 'My Custom Exercise Updated',
        sets: original.sets,
        reps: original.reps,
        durationSeconds: original.durationSeconds,
        restSeconds: original.restSeconds,
        tags: original.tags,
        libraryExerciseId: original.libraryExerciseId,
        order: original.order,
      );

      expect(edited.libraryExerciseId, isNull);
      expect(edited.durationSeconds, equals(30));
      expect(edited.restSeconds, equals(60));
      expect(edited.tags, equals(['custom']));
    });

    test('Serialization retains non-edited fields after name change', () {
      final original = Exercise(
        id: 'test-6',
        name: 'Original Name',
        sets: 3,
        reps: 10,
        durationSeconds: 40,
        restSeconds: 90,
        tags: ['tag1', 'tag2'],
        libraryExerciseId: 'lib-123',
        order: 0,
      );

      final edited = Exercise(
        id: original.id,
        name: 'New Name',
        sets: original.sets,
        reps: original.reps,
        durationSeconds: original.durationSeconds,
        restSeconds: original.restSeconds,
        tags: original.tags,
        libraryExerciseId: original.libraryExerciseId,
        order: original.order,
      );

      final map = edited.toMap();
      
      expect(map['name'], equals('New Name'));
      expect(map['durationSeconds'], equals(40));
      expect(map['restSeconds'], equals(90));
      expect(map['tags'], equals(['tag1', 'tag2']));
      expect(map['libraryExerciseId'], equals('lib-123'));
    });
  });
}
