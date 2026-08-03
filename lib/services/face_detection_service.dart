import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/person_model.dart';

/// Detects faces in photos using Google ML Kit's on-device face detector.
/// This finds WHERE faces are (bounding boxes) - it does not identify WHO
/// they are. Matching "this is the same person across photos" is done by
/// the user manually grouping detected faces in the People screen, since
/// real face-recognition (identity matching) needs a trained embedding
/// model beyond what runs reliably fully offline in a hand-built project.
class FaceDetectionService {
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  /// Scans a batch of photos and returns one DetectedFace per face found.
  /// Call with a reasonably small batch (e.g. 100-200) at a time from a
  /// background scan loop, since ML Kit inference takes real time per image.
  Future<List<DetectedFace>> scanForFaces(List<AssetEntity> assets) async {
    final results = <DetectedFace>[];

    for (final asset in assets) {
      try {
        final file = await asset.file;
        if (file == null) continue;
        final faces = await _detectInFile(file);
        for (final face in faces) {
          results.add(DetectedFace(
            assetId: asset.id,
            boundingLeft: face.boundingBox.left,
            boundingTop: face.boundingBox.top,
            boundingWidth: face.boundingBox.width,
            boundingHeight: face.boundingBox.height,
          ));
        }
      } catch (_) {
        continue; // skip unreadable/corrupt images rather than aborting the whole scan
      }
    }

    return results;
  }

  Future<List<Face>> _detectInFile(File file) async {
    final inputImage = InputImage.fromFile(file);
    return _detector.processImage(inputImage);
  }

  void dispose() {
    _detector.close();
  }
}
