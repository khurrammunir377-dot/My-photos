import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Groups photos by visual similarity using a difference-hash (dHash).
/// This runs fully on-device, offline, with no ML model download required -
/// a practical, lightweight stand-in for "AI-based" duplicate/similar detection.
class DuplicateDetector {
  /// Computes a 64-bit perceptual hash for an image file.
  /// Two images with a small Hamming distance between hashes are visually similar.
  Future<int?> computeHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Resize to 9x8 grayscale - standard dHash approach
      final resized = img.copyResize(decoded, width: 9, height: 8);
      final gray = img.grayscale(resized);

      int hash = 0;
      int bitIndex = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final left = gray.getPixel(x, y).luminance;
          final right = gray.getPixel(x + 1, y).luminance;
          if (left > right) {
            hash |= (1 << bitIndex);
          }
          bitIndex++;
        }
      }
      return hash;
    } catch (_) {
      return null;
    }
  }

  int hammingDistance(int hashA, int hashB) {
    int x = hashA ^ hashB;
    int distance = 0;
    while (x != 0) {
      distance += x & 1;
      x >>= 1;
    }
    return distance;
  }

  /// Groups a list of (id, hash) pairs into clusters of similar/duplicate photos.
  /// threshold: max Hamming distance to consider two photos "similar" (0 = identical, ~5 = near-duplicate).
  List<List<int>> groupSimilar(Map<int, int> idToHash, {int threshold = 5}) {
    final ids = idToHash.keys.toList();
    final visited = <int>{};
    final groups = <List<int>>[];

    for (final id in ids) {
      if (visited.contains(id)) continue;
      final group = [id];
      visited.add(id);
      for (final otherId in ids) {
        if (visited.contains(otherId)) continue;
        final dist = hammingDistance(idToHash[id]!, idToHash[otherId]!);
        if (dist <= threshold) {
          group.add(otherId);
          visited.add(otherId);
        }
      }
      if (group.length > 1) groups.add(group);
    }
    return groups;
  }
}
