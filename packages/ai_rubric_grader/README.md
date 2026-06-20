# ai_rubric_grader

[![pub package](https://img.shields.io/pub/v/ai_rubric_grader.svg)](https://pub.dev/packages/ai_rubric_grader)
[![likes](https://img.shields.io/pub/likes/ai_rubric_grader.svg)](https://pub.dev/packages/ai_rubric_grader/score)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

**LLM-agnostic, rubric-based automatic grading for Dart.** Feed it questions,
rubrics and student answers; get back structured, **clamped** scores with
per-rubric rationale. Bring your own LLM.

It's a small, dependency-light, pure-Dart package — no Flutter, no HTTP client
baked in — so you can run it **server-side** (a Cloud Function, a backend, a
CLI), which is where your API key belongs.

## Why

Naively asking a model to "grade this and give me the marks" and then parsing
free text is fragile: a stray line or markdown fence silently turns into a 0,
and the model can hand out more points than a rubric allows. This package:

- asks the model for **strict JSON**, not free text;
- **recomputes every total** from your rubric definitions;
- **clamps** each awarded score to `[0, rubric.points]` — the model can't inflate a grade;
- treats a rubric the model forgot as **0**, never a crash;
- lets you mark rubrics `autoGraded: false` to **leave them for a human**.

## Install

```yaml
dependencies:
  ai_rubric_grader: ^0.1.0
```

## Usage

```dart
import 'package:ai_rubric_grader/ai_rubric_grader.dart';

final questions = [
  Question(
    id: 'q1',
    prompt: 'What is the derivative of x²?',
    answer: '2x',                       // plain text, LaTeX, transcribed handwriting…
    rubrics: const [
      Rubric(id: 'r1', description: 'Correct derivative', requirement: 'equals 2x', points: 5),
      Rubric(id: 'r2', description: 'Shows working',      requirement: 'steps shown', points: 3,
             autoGraded: false),         // left for a human
    ],
  ),
];

final grader = RubricGrader(myLlmClient);
final result = await grader.grade(questions);

print('${result.awarded}/${result.possible} (${result.percentage}%)');
for (final g in result.questionGrades) {
  for (final s in g.rubricScores) {
    print('${s.rubricId}: ${s.awarded}/${s.possible} — ${s.rationale}');
  }
}
```

## Bring your own LLM

Implement the one-method [`LlmClient`](lib/src/llm_client.dart) for any provider.
Request deterministic output (`temperature: 0`) and JSON mode where available.

```dart
import 'dart:convert';
import 'package:ai_rubric_grader/ai_rubric_grader.dart';
import 'package:http/http.dart' as http;

class OpenAiClient implements LlmClient {
  OpenAiClient(this.apiKey, {this.model = 'gpt-4o-mini'});
  final String apiKey;
  final String model;

  @override
  Future<String> complete({required String system, required String user}) async {
    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      }),
    );
    final body = jsonDecode(res.body);
    return body['choices'][0]['message']['content'] as String;
  }
}
```

> **Security:** never embed an LLM API key in a mobile/web client — it ships in
> the binary and can be extracted. Run the grader behind your backend and call
> that from the app.

## API

| Type | Purpose |
|---|---|
| `Rubric` | A criterion: `description`, `requirement`, `points`, `autoGraded`. |
| `Question` | `prompt`, `answer`, `rubrics`; exposes `totalPoints` / `autoGradablePoints`. |
| `RubricGrader` | `grade(List<Question>) → Future<GradingResult>`. |
| `GradingResult` | `awarded`, `possible`, `percentage`, `questionGrades`. |
| `RubricScore` | Per-rubric `awarded` (clamped), `possible`, `rationale`, `isFullyMet`. |
| `LlmClient` | The one method you implement to plug in a provider. |

All models are immutable and JSON-serializable (`toJson` / `fromJson`).

## License

[MIT](LICENSE)
