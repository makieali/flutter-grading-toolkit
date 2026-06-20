# image_white_background

[![pub package](https://img.shields.io/pub/v/image_white_background.svg)](https://pub.dev/packages/image_white_background)
[![likes](https://img.shields.io/pub/likes/image_white_background.svg)](https://pub.dev/packages/image_white_background/score)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

Composite a transparent image onto a solid (white) background. Useful before
sending images to **OCR / vision models**, which often read more reliably
against an opaque background than a transparent one.

## Install

```yaml
dependencies:
  image_white_background: ^0.1.0
```

## Usage

```dart
import 'package:image_white_background/image_white_background.dart';

// Padding mode: image + a white border on every side.
final padded = await ImageWhiteBackground.apply(
  pngBytes,
  padding: const EdgeInsets.all(24),
);

// Fixed-canvas mode: center the image on a white canvas of an exact size.
final framed = await ImageWhiteBackground.apply(
  pngBytes,
  canvasSize: const Size(1024, 1024),
);

// Any background colour you like.
final onBlack = await ImageWhiteBackground.apply(
  pngBytes,
  background: const Color(0xFF000000),
);
```

`apply` returns PNG bytes (`Uint8List`) you can upload, display with
`Image.memory`, or hand to a vision API.

## License

[MIT](LICENSE)
