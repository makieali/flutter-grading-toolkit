import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_answer_pad/handwriting_answer_pad.dart';

Widget _host({
  required HandwritingRecognizer recognizer,
  Future<Uint8List> Function()? capture,
  ValueChanged<String>? onResult,
}) =>
    MaterialApp(
      home: Scaffold(
        body: HandwritingAnswerPad(
          recognizer: recognizer,
          capture: capture ?? () async => Uint8List(0),
          onResult: onResult,
        ),
      ),
    );

void main() {
  testWidgets('renders canvas toolbar with all controls', (tester) async {
    await tester.pumpWidget(_host(recognizer: (_) async => ''));

    expect(find.byKey(const Key('undo')), findsOneWidget);
    expect(find.byKey(const Key('redo')), findsOneWidget);
    expect(find.byKey(const Key('clear')), findsOneWidget);
    expect(find.byKey(const Key('recognize')), findsOneWidget);
  });

  testWidgets('undo and redo start disabled on an empty pad', (tester) async {
    await tester.pumpWidget(_host(recognizer: (_) async => ''));

    final undo = tester.widget<IconButton>(find.byKey(const Key('undo')));
    final redo = tester.widget<IconButton>(find.byKey(const Key('redo')));
    expect(undo.onPressed, isNull);
    expect(redo.onPressed, isNull);
  });

  testWidgets('recognize renders, calls recognizer, and shows the result',
      (tester) async {
    Uint8List? captured;
    String? result;
    await tester.pumpWidget(_host(
      capture: () async => Uint8List.fromList([1, 2, 3]),
      recognizer: (bytes) async {
        captured = bytes;
        return r'x = 5';
      },
      onResult: (r) => result = r,
    ));

    await tester.tap(find.byKey(const Key('recognize')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(find.byKey(const Key('result')), findsOneWidget);
    expect(find.text(r'x = 5'), findsOneWidget);
    expect(result, r'x = 5');
  });

  testWidgets('a failing recognizer shows a friendly error', (tester) async {
    await tester.pumpWidget(_host(
      recognizer: (_) async => throw Exception('network down'),
    ));

    await tester.tap(find.byKey(const Key('recognize')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error')), findsOneWidget);
    // The raw exception text is not leaked to the user.
    expect(find.textContaining('network down'), findsNothing);
  });

  testWidgets('uses an external controller when provided', (tester) async {
    final controller = HandwritingPadController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HandwritingAnswerPad(
          controller: controller,
          recognizer: (_) async => 'ok',
          capture: () async => Uint8List(0),
        ),
      ),
    ));

    expect(controller.canUndo, isFalse);
    expect(find.byType(HandwritingAnswerPad), findsOneWidget);
  });
}
