import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photo_service.dart';

/// Detects two common "clutter" categories in a camera roll:
///
/// - Screenshots: identified by filename (Android names them
///   "Screenshot_..." by default) - fast, no image processing needed.
/// - Receipts: identified with on-device OCR (ML Kit Text Recognition) -
///   looks for common receipt vocabulary (total, subtotal, tax, etc.) in a
///   portrait-oriented image. Not perfect (no ML classifier is, without a
///   custom-trained model), but a solid practical heuristic.
class ScreenshotReceiptService {
  final _photoService = PhotoService();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static const _receiptKeywords = [
    'total', 'subtotal', 'tax', 'receipt', 'invoice', 'qty', 'change due',
    'cash', 'visa', 'mastercard', 'amount', 'balance due', 'thank you for',
  ];

  bool _looksLikeScreenshot(AssetEntity asset) {
    final title = (asset.title ?? '').toLowerCase();
    return title.contains('screenshot') || title.startsWith('screen_shot') || title.startsWith('screencap');
  }

  Future<List<AssetEntity>> scanForScreenshots() async {
    final photos = await _photoService.getAllDevicePhotos();
    return photos.where(_looksLikeScreenshot).toList();
  }

  /// Scans a capped batch of non-screenshot photos for receipt-like text.
  /// OCR is far more expensive than a filename check, so this intentionally
  /// looks at a smaller batch than the screenshot scan.
  Future<List<AssetEntity>> scanForReceipts({int maxToScan = 150}) async {
    final photos = await _photoService.getAllDevicePhotos();
    final candidates = photos.where((a) => !_looksLikeScreenshot(a)).take(maxToScan).toList();

    final results = <AssetEntity>[];
    for (final asset in candidates) {
      try {
        final file = await asset.file;
        if (file == null) continue;
        final inputImage = InputImage.fromFile(file);
        final recognized = await _textRecognizer.processImage(inputImage);
        final text = recognized.text.toLowerCase();
        if (text.isEmpty) continue;

        final matchCount = _receiptKeywords.where((k) => text.contains(k)).length;
        // Require at least 2 receipt-vocabulary matches to avoid false
        // positives on ordinary photos that happen to contain a stray word.
        if (matchCount >= 2) {
          results.add(asset);
        }
      } catch (_) {
        continue; // skip unreadable photos rather than aborting the whole scan
      }
    }
    return results;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
