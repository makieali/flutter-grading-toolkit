import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:scribble/scribble.dart';

/// Programmatic control over a [HandwritingAnswerPad].
///
/// Wraps a [ScribbleNotifier] so callers get a small, intention-revealing API
/// (undo / redo / clear / render) without depending on scribble directly.
/// Remember to [dispose] it if you create it yourself.
class HandwritingPadController {
  HandwritingPadController({
    double strokeWidth = 3,
    Color color = const Color(0xFF1A1A2E),
  }) {
    notifier
      ..setStrokeWidth(strokeWidth)
      ..setColor(color);
  }

  /// The underlying scribble notifier (exposed for advanced use).
  final ScribbleNotifier notifier = ScribbleNotifier();

  void undo() => notifier.undo();
  void redo() => notifier.redo();
  void clear() => notifier.clear();

  bool get canUndo => notifier.canUndo;
  bool get canRedo => notifier.canRedo;

  /// Renders the current drawing to PNG bytes.
  ///
  /// Only valid while the pad is mounted (it captures the on-screen canvas).
  /// Throws [StateError] if called before the widget is laid out.
  Future<Uint8List> renderPng({double pixelRatio = 2.0}) async {
    final ByteData data =
        await notifier.renderImage(pixelRatio: pixelRatio, format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
  }

  void dispose() => notifier.dispose();
}
