# rubric_builder

[![pub package](https://img.shields.io/badge/pub-0.1.0-blue.svg)](https://pub.dev/packages/rubric_builder)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

A Flutter widget for authoring **weighted grading rubrics** — add, edit and
remove criteria with a **live points total** — backed by a clean, immutable,
**controller-free** data model.

The widget owns its `TextEditingController`s internally and only ever hands you
immutable `RubricDraft` values, so there are no leaked controllers and your
state stays serializable.

## Install

```yaml
dependencies:
  rubric_builder: ^0.1.0
```

## Usage

```dart
import 'package:rubric_builder/rubric_builder.dart';

List<RubricDraft> rubrics = const [
  RubricDraft(description: 'Correct answer', requirement: 'Final value is right', points: 5),
  RubricDraft(description: 'Shows working',  requirement: 'Steps are shown',       points: 3),
];

RubricBuilder(
  initial: rubrics,
  onChanged: (updated) => setState(() => rubrics = updated),
);
```

`RubricDraft` is JSON-serializable and has value equality:

```dart
final json = rubric.toJson();
final back = RubricDraft.fromJson(json);
final total = RubricDraft.total(rubrics); // sum of points
```

Pairs naturally with [`ai_rubric_grader`](https://pub.dev/packages/ai_rubric_grader):
author rubrics here, grade answers there.

## License

[MIT](LICENSE)
