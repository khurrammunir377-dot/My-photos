import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum PhotoFilter {
  normal,
  blackAndWhite,
  sepia,
  vivid,
  cool,
  warm,
  noir,
  fade,
  vintage,
  chrome,
  mono,
  dramatic,
}

class FilterOption {
  final PhotoFilter type;
  final String label;
  final List<double> matrix; // 4x5 ColorFilter matrix for live preview

  const FilterOption(this.type, this.label, this.matrix);
}

/// Standard 4x5 RGBA color matrices - the same math used by most photo apps
/// for quick filters. Used both for the live camera preview (via ColorFiltered)
/// and baked permanently into the saved file (via the `image` package) so the
/// filter isn't just a visual overlay that disappears once you leave the camera.
class CameraFilters {
  static const identity = <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const grayscale = <double>[
    0.33, 0.59, 0.11, 0, 0,
    0.33, 0.59, 0.11, 0, 0,
    0.33, 0.59, 0.11, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const sepia = <double>[
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const vivid = <double>[
    1.3, 0, 0, 0, -20,
    0, 1.3, 0, 0, -20,
    0, 0, 1.3, 0, -20,
    0, 0, 0, 1, 0,
  ];

  static const cool = <double>[
    1.0, 0, 0, 0, 0,
    0, 1.0, 0, 0, 10,
    0, 0, 1.15, 0, 20,
    0, 0, 0, 1, 0,
  ];

  static const warm = <double>[
    1.15, 0, 0, 0, 15,
    0, 1.05, 0, 0, 5,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const noir = <double>[
    0.462, 0.826, 0.154, 0, -51,
    0.462, 0.826, 0.154, 0, -51,
    0.462, 0.826, 0.154, 0, -51,
    0, 0, 0, 1, 0,
  ];

  static const fade = <double>[
    0.85, 0, 0, 0, 30,
    0, 0.85, 0, 0, 30,
    0, 0, 0.85, 0, 30,
    0, 0, 0, 1, 0,
  ];

  static const vintage = <double>[
    0.6, 0.5, 0.2, 0, 12,
    0.5, 0.5, 0.2, 0, 8,
    0.4, 0.4, 0.3, 0, 8,
    0, 0, 0, 1, 0,
  ];

  static const chrome = <double>[
    1.5, -0.2, -0.1, 0, -12,
    -0.1, 1.5, -0.2, 0, -12,
    -0.1, -0.2, 1.5, 0, -12,
    0, 0, 0, 1, 0,
  ];

  static const mono = <double>[
    0.33, 0.59, 0.11, 0, 0,
    0.33, 0.59, 0.11, 0, 8,
    0.33, 0.59, 0.11, 0, 35,
    0, 0, 0, 1, 0,
  ];

  static const dramatic = <double>[
    1.5, 0, 0, 0, -60,
    0, 1.5, 0, 0, -60,
    0, 0, 1.5, 0, -60,
    0, 0, 0, 1, 0,
  ];

  static const List<FilterOption> options = [
    FilterOption(PhotoFilter.normal, 'Normal', identity),
    FilterOption(PhotoFilter.blackAndWhite, 'B&W', grayscale),
    FilterOption(PhotoFilter.sepia, 'Sepia', sepia),
    FilterOption(PhotoFilter.vivid, 'Vivid', vivid),
    FilterOption(PhotoFilter.cool, 'Cool', cool),
    FilterOption(PhotoFilter.warm, 'Warm', warm),
    FilterOption(PhotoFilter.noir, 'Noir', noir),
    FilterOption(PhotoFilter.fade, 'Fade', fade),
    FilterOption(PhotoFilter.vintage, 'Vintage', vintage),
    FilterOption(PhotoFilter.chrome, 'Chrome', chrome),
    FilterOption(PhotoFilter.mono, 'Mono', mono),
    FilterOption(PhotoFilter.dramatic, 'Dramatic', dramatic),
  ];

  static FilterOption forType(PhotoFilter type) {
    return options.firstWhere((o) => o.type == type, orElse: () => options.first);
  }

  /// Applies the chosen filter permanently to a captured photo file (overwrites it in place).
  static Future<void> bakeIntoFile(String filePath, PhotoFilter filter) async {
    if (filter == PhotoFilter.normal) return; // nothing to do
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;

    img.Image processed;
    switch (filter) {
      case PhotoFilter.blackAndWhite:
        processed = img.grayscale(decoded);
        break;
      case PhotoFilter.sepia:
        processed = img.sepia(decoded);
        break;
      case PhotoFilter.vivid:
        processed = img.adjustColor(decoded, saturation: 1.4, contrast: 1.1);
        break;
      case PhotoFilter.cool:
        processed = img.colorOffset(decoded, blue: 20, green: 5);
        break;
      case PhotoFilter.warm:
        processed = img.colorOffset(decoded, red: 20, green: 8);
        break;
      case PhotoFilter.noir:
        processed = img.adjustColor(img.grayscale(decoded), contrast: 1.4);
        break;
      case PhotoFilter.fade:
        processed = img.adjustColor(decoded, contrast: 0.8, saturation: 0.85, brightness: 1.08);
        break;
      case PhotoFilter.vintage:
        processed = img.adjustColor(img.sepia(decoded, amount: 0.6), contrast: 0.9, saturation: 0.9);
        break;
      case PhotoFilter.chrome:
        processed = img.adjustColor(decoded, saturation: 1.6, contrast: 1.3);
        break;
      case PhotoFilter.mono:
        processed = img.colorOffset(img.grayscale(decoded), blue: 30);
        break;
      case PhotoFilter.dramatic:
        processed = img.adjustColor(decoded, contrast: 1.5, brightness: 0.9);
        break;
      case PhotoFilter.normal:
        processed = decoded;
        break;
    }

    await file.writeAsBytes(img.encodeJpg(processed, quality: 92));
  }
}

/// Wraps a child (typically the camera preview) with a live filter preview.
class FilteredPreview extends StatelessWidget {
  final Widget child;
  final PhotoFilter filter;
  const FilteredPreview({super.key, required this.child, required this.filter});

  @override
  Widget build(BuildContext context) {
    final matrix = CameraFilters.forType(filter).matrix;
    if (filter == PhotoFilter.normal) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: child,
    );
  }
}
