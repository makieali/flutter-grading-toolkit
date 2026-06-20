# handwriting_answer_pad

[![pub package](https://img.shields.io/pub/v/handwriting_answer_pad.svg)](https://pub.dev/packages/handwriting_answer_pad)
[![likes](https://img.shields.io/pub/likes/handwriting_answer_pad.svg)](https://pub.dev/packages/handwriting_answer_pad/score)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

A Flutter **handwriting capture pad** — a drawing canvas with undo / redo /
clear and a "recognize" action — backed by a **pluggable recognizer** so you
bring your own OCR or vision model. The pad never talks to a backend itself, so
it stays decoupled and testable.

Great for math answers, signatures, quick sketches, or anything you want to turn
into text.

## Install

```yaml
dependencies:
  handwriting_answer_pad: ^0.1.0
```

## Usage

```dart
import 'dart:typed_data';
import 'package:handwriting_answer_pad/handwriting_answer_pad.dart';

HandwritingAnswerPad(
  recognizer: (Uint8List pngBytes) async {
    // Send the rendered handwriting to your OCR / vision model and return text.
    return await myVisionApi.imageToText(pngBytes);
  },
  onResult: (text) => print('Recognized: $text'),
);
```

The widget renders the strokes to a PNG and hands the bytes to your
`recognizer`; the returned text is shown below the pad. Errors are caught and
shown as a friendly message (the raw exception is never leaked to the user).

### Programmatic control

```dart
final controller = HandwritingPadController(strokeWidth: 4);

HandwritingAnswerPad(controller: controller, recognizer: myRecognizer);

controller.undo();
controller.clear();
final png = await controller.renderPng(); // capture the drawing yourself
controller.dispose();                     // if you created it
```

## Tips

- Pair the output with [`image_white_background`](https://pub.dev/packages/image_white_background)
  to give vision models an opaque canvas, and with
  [`ai_rubric_grader`](https://pub.dev/packages/ai_rubric_grader) to grade the
  recognized answer.
- Run recognition (and any API key) **server-side**; pass only the image up and
  the text back.

## License

[MIT](LICENSE)
