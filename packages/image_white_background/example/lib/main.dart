import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_white_background/image_white_background.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('image_white_background')),
        body: Center(
          child: FutureBuilder<Uint8List>(
            // In a real app, pass bytes from a picker, camera, or a canvas.
            future: _demoBytes(),
            builder: (context, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return Image.memory(snap.data!);
            },
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _demoBytes() async {
    // Pretend we captured a transparent PNG; here we just reuse an asset's
    // bytes. Replace with your own image bytes.
    final transparent = Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, // (placeholder — see test/ for real usage)
    ]);
    try {
      return await ImageWhiteBackground.apply(
        transparent,
        padding: const EdgeInsets.all(24),
      );
    } catch (_) {
      return transparent;
    }
  }
}
