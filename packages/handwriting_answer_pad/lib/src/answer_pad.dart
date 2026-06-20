import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import 'controller.dart';

/// Turns handwriting (PNG bytes) into text. Bring your own implementation —
/// an OCR service, a vision LLM, an on-device model. The pad never talks to a
/// backend itself, so it stays decoupled and testable.
typedef HandwritingRecognizer = Future<String> Function(Uint8List pngBytes);

/// A handwriting capture pad: a drawing canvas plus undo / redo / clear and a
/// "recognize" action that renders the strokes to an image and runs your
/// [recognizer], showing the recognized text.
class HandwritingAnswerPad extends StatefulWidget {
  const HandwritingAnswerPad({
    super.key,
    required this.recognizer,
    this.controller,
    this.height = 220,
    this.recognizeLabel = 'Recognize',
    this.onResult,
    this.pixelRatio = 2.0,
    this.backgroundColor = const Color(0xFFFFFFFF),
    @visibleForTesting this.capture,
  });

  /// Converts the rendered handwriting into text.
  final HandwritingRecognizer recognizer;

  /// Optional external controller. If omitted, the pad creates and owns one.
  final HandwritingPadController? controller;

  /// Height of the drawing surface.
  final double height;

  final String recognizeLabel;

  /// Called with the recognized text after a successful recognize.
  final ValueChanged<String>? onResult;

  /// Resolution multiplier for the rendered image.
  final double pixelRatio;

  final Color backgroundColor;

  /// Test seam: overrides image capture so recognition can be exercised
  /// without a laid-out canvas. Not for production use.
  @visibleForTesting
  final Future<Uint8List> Function()? capture;

  @override
  State<HandwritingAnswerPad> createState() => _HandwritingAnswerPadState();
}

class _HandwritingAnswerPadState extends State<HandwritingAnswerPad> {
  late final HandwritingPadController _controller =
      widget.controller ?? HandwritingPadController();
  bool get _ownsController => widget.controller == null;

  bool _busy = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _recognize() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes =
          widget.capture != null ? await widget.capture!() : await _controller.renderPng(pixelRatio: widget.pixelRatio);
      final text = await widget.recognizer(bytes);
      if (!mounted) return;
      setState(() {
        _result = text;
        _busy = false;
      });
      widget.onResult?.call(text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not recognize handwriting. Please try again.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scribble(notifier: _controller.notifier),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller.notifier,
          builder: (context, _) => Row(
            children: [
              IconButton(
                key: const Key('undo'),
                tooltip: 'Undo',
                icon: const Icon(Icons.undo),
                onPressed: _controller.canUndo ? _controller.undo : null,
              ),
              IconButton(
                key: const Key('redo'),
                tooltip: 'Redo',
                icon: const Icon(Icons.redo),
                onPressed: _controller.canRedo ? _controller.redo : null,
              ),
              IconButton(
                key: const Key('clear'),
                tooltip: 'Clear',
                icon: const Icon(Icons.delete_outline),
                onPressed: _controller.clear,
              ),
              const Spacer(),
              FilledButton.icon(
                key: const Key('recognize'),
                onPressed: _busy ? null : _recognize,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(widget.recognizeLabel),
              ),
            ],
          ),
        ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _result!,
                key: const Key('result'),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const Key('error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
