// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:ai_rubric_grader/ai_rubric_grader.dart';

/// A tiny example that grades one question using a *fake* LLM so it runs
/// offline. Swap [DemoLlm] for a real adapter (see the README) in production.
Future<void> main() async {
  final questions = const [
    Question(
      id: 'q1',
      prompt: 'What is the derivative of x^2?',
      answer: '2x',
      rubrics: [
        Rubric(id: 'r1', description: 'Correct derivative', requirement: 'equals 2x', points: 5),
        Rubric(id: 'r2', description: 'Uses correct notation', requirement: 'dy/dx form', points: 2),
      ],
    ),
  ];

  final grader = RubricGrader(DemoLlm());
  final result = await grader.grade(questions);

  print('Score: ${result.awarded}/${result.possible} (${result.percentage}%)');
  for (final grade in result.questionGrades) {
    for (final score in grade.rubricScores) {
      print('  ${score.rubricId}: ${score.awarded}/${score.possible} '
          '— ${score.rationale ?? ""}');
    }
  }
}

/// Stand-in LLM that returns a canned JSON grade. In a real app this calls
/// OpenAI / Gemini / Anthropic etc. (server-side, with your API key).
class DemoLlm implements LlmClient {
  @override
  Future<String> complete({required String system, required String user}) async {
    return jsonEncode({
      'questions': [
        {
          'questionId': 'q1',
          'rubrics': [
            {'rubricId': 'r1', 'awarded': 5, 'rationale': 'Answer 2x is correct.'},
            {'rubricId': 'r2', 'awarded': 2, 'rationale': 'Notation acceptable.'},
          ],
        }
      ],
    });
  }
}
