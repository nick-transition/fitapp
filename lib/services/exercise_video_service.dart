import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ExerciseVideoUpload {
  final String downloadUrl;
  final String storagePath;

  const ExerciseVideoUpload({
    required this.downloadUrl,
    required this.storagePath,
  });
}

class ExerciseVideoService {
  static const _maxDuration = Duration(seconds: 60);
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromCamera() =>
      _picker.pickVideo(source: ImageSource.camera, maxDuration: _maxDuration);

  Future<XFile?> pickFromGallery() =>
      _picker.pickVideo(source: ImageSource.gallery, maxDuration: _maxDuration);

  Future<ExerciseVideoUpload> upload({
    required String sessionId,
    required String entryDocId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        'users/$uid/sessions/$sessionId/entries/$entryDocId/$timestamp.mp4';

    final ref = FirebaseStorage.instance.ref(path);
    final task = ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'video/mp4'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    await task;
    final url = await ref.getDownloadURL();
    return ExerciseVideoUpload(downloadUrl: url, storagePath: path);
  }
}
