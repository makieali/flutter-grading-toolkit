import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_white_background/image_white_background.dart';

/// Renders a solid square PNG of [size]px in [color] (fully transparent
/// elsewhere isn't needed; we just need a known image to composite).
Future<Uint8List> _square(int size, Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = color,
  );
  final ui.Image image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Returns the RGBA pixel at (x, y) as a 0xRRGGBBAA int.
int _pixel(ByteData rgba, int width, int x, int y) {
  final i = (y * width + x) * 4;
  final r = rgba.getUint8(i);
  final g = rgba.getUint8(i + 1);
  final b = rgba.getUint8(i + 2);
  final a = rgba.getUint8(i + 3);
  return (r << 24) | (g << 16) | (b << 8) | a;
}

// Expected pixels in the RGBA order that _pixel() packs.
const int white = 0xFFFFFFFF;
const int redRgba = 0xFF0000FF; // r,g,b,a
const int greenRgba = 0x00FF00FF;
const Color redColor = Color(0xFFFF0000); // ARGB, for drawing

void main() {
  testWidgets('padding mode enlarges the canvas and fills the border white',
      (tester) async {
    await tester.runAsync(() async {
      final input = await _square(10, redColor);
      final out = await ImageWhiteBackground.apply(
        input,
        padding: const EdgeInsets.all(5),
      );

      final decoded = await decodeImageFromList(out);
      expect(decoded.width, 20); // 10 + 5 + 5
      expect(decoded.height, 20);

      final rgba = (await decoded.toByteData())!;
      expect(_pixel(rgba, 20, 0, 0), white, reason: 'top-left corner is white');
      expect(_pixel(rgba, 20, 10, 10), redRgba, reason: 'center is the image');
    });
  });

  testWidgets('fixed canvasSize centers the image on a white background',
      (tester) async {
    await tester.runAsync(() async {
      final input = await _square(10, redColor);
      final out = await ImageWhiteBackground.apply(
        input,
        canvasSize: const Size(30, 30),
      );

      final decoded = await decodeImageFromList(out);
      expect(decoded.width, 30);
      expect(decoded.height, 30);

      final rgba = (await decoded.toByteData())!;
      // Corners white, center (15,15) inside the centered 10px image -> red.
      expect(_pixel(rgba, 30, 0, 0), white);
      expect(_pixel(rgba, 30, 15, 15), redRgba);
    });
  });

  testWidgets('custom background colour is honoured', (tester) async {
    await tester.runAsync(() async {
      final input = await _square(4, redColor);
      final out = await ImageWhiteBackground.apply(
        input,
        padding: const EdgeInsets.all(2),
        background: const Color(0xFF00FF00), // green
      );
      final decoded = await decodeImageFromList(out);
      final rgba = (await decoded.toByteData())!;
      expect(_pixel(rgba, decoded.width, 0, 0), greenRgba); // green corner
    });
  });

  testWidgets('invalid bytes throw StateError', (tester) async {
    await tester.runAsync(() async {
      expect(
        () => ImageWhiteBackground.apply(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<StateError>()),
      );
    });
  });
}
