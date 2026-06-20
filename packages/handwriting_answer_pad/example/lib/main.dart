import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:handwriting_answer_pad/handwriting_answer_pad.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('handwriting_answer_pad')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: HandwritingAnswerPad(
            // Plug in any OCR / vision model here. This demo just echoes.
            recognizer: _fakeRecognizer,
            onResult: (text) => debugPrint('Recognized: $text'),
          ),
        ),
      ),
    );
  }

  Future<String> _fakeRecognizer(Uint8List pngBytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'x^2 + 2x + 1'; // pretend the model read the handwriting
  }
}
