import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Composites a (possibly transparent) image onto a solid background.
///
/// Replaces the common "draw the PNG on a white rectangle" snippet. Two modes:
///
/// * **Padding mode** (default): the output is the image plus [padding] on each
///   side, filled with [background].
/// * **Fixed-canvas mode**: pass [canvasSize] to center the image inside a
///   background of exactly that size (image is not scaled).
abstract final class ImageWhiteBackground {
  /// Returns PNG bytes of [imageBytes] composited onto a [background] fill.
  ///
  /// Throws [StateError] if the image cannot be decoded or encoded.
  static Future<Uint8List> apply(
    Uint8List imageBytes, {
    EdgeInsets padding = EdgeInsets.zero,
    Color background = const Color(0xFFFFFFFF),
    Size? canvasSize,
  }) async {
    final ui.Image image = await _decode(imageBytes);
    try {
      final double imgW = image.width.toDouble();
      final double imgH = image.height.toDouble();

      final double width = canvasSize?.width ?? imgW + padding.horizontal;
      final double height = canvasSize?.height ?? imgH + padding.vertical;
      if (width <= 0 || height <= 0) {
        throw StateError('Output size must be positive (got ${width}x$height)');
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = background,
      );

      final double dx = canvasSize != null ? (width - imgW) / 2 : padding.left;
      final double dy = canvasSize != null ? (height - imgH) / 2 : padding.top;
      canvas.drawImage(image, Offset(dx, dy), Paint());

      final ui.Picture picture = recorder.endRecording();
      final ui.Image composited =
          await picture.toImage(width.round(), height.round());
      try {
        final ByteData? data =
            await composited.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) {
          throw StateError('Failed to encode composited image to PNG');
        }
        return data.buffer.asUint8List();
      } finally {
        picture.dispose();
        composited.dispose();
      }
    } finally {
      image.dispose();
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    try {
      return await decodeImageFromList(bytes);
    } catch (e) {
      throw StateError('Could not decode image bytes: $e');
    }
  }
}
