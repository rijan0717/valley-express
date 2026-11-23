import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Re-encodes a picked image to a bounded JPEG data URL.
///
/// image_picker's `maxWidth`/`maxHeight`/`imageQuality` are advisory: several
/// sources and formats hand back the original file untouched, so a camera
/// shot can arrive as several megabytes. That is too large to store on the
/// user document and slow to decode on the other side, which is why a photo
/// could upload and then fail to render. Re-encoding here makes the bound
/// hold whatever the picker returned.
class ImageCompress {
  /// Longest edge of the result, in pixels.
  static const avatarEdge = 512;
  static const attachmentEdge = 1080;
  static const _quality = 80;

  /// Runs off the UI isolate; large decodes are slow enough to drop frames.
  static Future<String> toDataUrl(
    Uint8List bytes, {
    int maxEdge = avatarEdge,
    int quality = _quality,
  }) {
    return compute(
      _encode,
      _Request(bytes: bytes, maxEdge: maxEdge, quality: quality),
    );
  }
}

class _Request {
  final Uint8List bytes;
  final int maxEdge;
  final int quality;

  const _Request({
    required this.bytes,
    required this.maxEdge,
    required this.quality,
  });
}

String _encode(_Request req) {
  final decoded = img.decodeImage(req.bytes);
  if (decoded == null) {
    // Not something this package understands; hand back what we were given
    // rather than losing the picture entirely.
    return 'data:image/jpeg;base64,${base64Encode(req.bytes)}';
  }

  final longest =
      decoded.width >= decoded.height ? decoded.width : decoded.height;
  final resized = longest > req.maxEdge
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? req.maxEdge : null,
          height: decoded.width >= decoded.height ? null : req.maxEdge,
          interpolation: img.Interpolation.average,
        )
      : decoded;

  final jpeg = img.encodeJpg(resized, quality: req.quality);
  return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
}
