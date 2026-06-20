import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubric_builder/rubric_builder.dart';

Widget _host(ValueChanged<List<RubricDraft>> onChanged,
        {List<RubricDraft> initial = const []}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RubricBuilder(initial: initial, onChanged: onChanged),
        ),
      ),
    );

void main() {
  testWidgets('renders initial rubrics and total', (tester) async {
    await tester.pumpWidget(_host((_) {}, initial: const [
      RubricDraft(description: 'Correct', requirement: 'x', points: 5),
      RubricDraft(description: 'Working', requirement: 'y', points: 3),
    ]));

    expect(find.text('Correct'), findsOneWidget);
    expect(find.byKey(const Key('rubric_total')), findsOneWidget);
    expect(find.text('Total: 8 pts'), findsOneWidget);
  });

  testWidgets('adding a criterion emits a longer list', (tester) async {
    List<RubricDraft>? latest;
    await tester.pumpWidget(_host((v) => latest = v));

    await tester.tap(find.byKey(const Key('add_rubric')));
    await tester.pump();

    expect(latest, isNotNull);
    expect(latest!.length, 1);
  });

  testWidgets('editing points updates the live total and emits', (tester) async {
    List<RubricDraft>? latest;
    await tester.pumpWidget(_host((v) => latest = v, initial: const [
      RubricDraft(description: 'A', requirement: 'x', points: 0),
    ]));

    await tester.enterText(find.byKey(const Key('points_0')), '7');
    await tester.pump();

    expect(find.text('Total: 7 pts'), findsOneWidget);
    expect(latest!.single.points, 7);
  });

  testWidgets('editing description emits new value', (tester) async {
    List<RubricDraft>? latest;
    await tester.pumpWidget(_host((v) => latest = v, initial: const [
      RubricDraft(points: 1),
    ]));

    await tester.enterText(find.byKey(const Key('description_0')), 'Clarity');
    await tester.pump();
    expect(latest!.single.description, 'Clarity');
  });

  testWidgets('removing a criterion shrinks the list', (tester) async {
    List<RubricDraft>? latest;
    await tester.pumpWidget(_host((v) => latest = v, initial: const [
      RubricDraft(description: 'A', points: 2),
      RubricDraft(description: 'B', points: 3),
    ]));

    await tester.tap(find.byKey(const Key('remove_0')));
    await tester.pump();

    expect(latest!.length, 1);
    expect(latest!.single.description, 'B');
    expect(find.text('Total: 3 pts'), findsOneWidget);
  });

  testWidgets('auto-graded toggle is reflected in emitted drafts',
      (tester) async {
    List<RubricDraft>? latest;
    await tester.pumpWidget(_host((v) => latest = v, initial: const [
      RubricDraft(description: 'A', points: 1, autoGraded: true),
    ]));

    await tester.tap(find.byKey(const Key('autograded_0')));
    await tester.pump();
    expect(latest!.single.autoGraded, isFalse);
  });

  group('RubricDraft model', () {
    test('total sums points', () {
      expect(
        RubricDraft.total(const [
          RubricDraft(points: 2),
          RubricDraft(points: 5),
        ]),
        7,
      );
    });

    test('json round-trip', () {
      const r = RubricDraft(
          id: 'r1', description: 'd', requirement: 'q', points: 4, autoGraded: false);
      expect(RubricDraft.fromJson(r.toJson()), r);
    });

    test('value equality', () {
      expect(const RubricDraft(description: 'a', points: 1),
          const RubricDraft(description: 'a', points: 1));
    });
  });
}
