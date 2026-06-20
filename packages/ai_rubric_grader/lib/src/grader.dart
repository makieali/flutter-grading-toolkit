import 'llm_client.dart';
import 'models.dart';
import 'prompt.dart';

/// Thrown when the model response cannot be parsed into a [GradingResult].
class GradingException implements Exception {
  const GradingException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() => 'GradingException: $message';
}

/// Grades student answers against rubrics using an injected [LlmClient].
///
/// ```dart
/// final grader = RubricGrader(myLlmClient);
/// final result = await grader.grade(questions);
/// print('${result.awarded}/${result.possible} (${result.percentage}%)');
/// ```
class RubricGrader {
  RubricGrader(this.client, {GradingPrompt? prompt})
      : prompt = prompt ?? const GradingPrompt();

  final LlmClient client;
  final GradingPrompt prompt;

  /// Grades [questions] and returns structured, clamped scores.
  ///
  /// Questions with no auto-gradable rubrics are skipped in the request but
  /// still appear in the result (with zero possible points). Throws
  /// [GradingException] if the model returns unparseable output.
  Future<GradingResult> grade(List<Question> questions) async {
    if (questions.isEmpty) {
      return const GradingResult(questionGrades: [], awarded: 0, possible: 0);
    }

    final gradable =
        questions.where((q) => q.autoGradablePoints > 0).toList();
    if (gradable.isEmpty) {
      // Nothing for the model to do; return an all-zero result.
      return prompt.parse('{"questions":[]}', questions);
    }

    final String raw;
    try {
      raw = await client.complete(
        system: prompt.system,
        user: prompt.buildUser(gradable),
      );
    } catch (e) {
      throw GradingException('LLM request failed', e);
    }

    try {
      return prompt.parse(raw, questions);
    } on FormatException catch (e) {
      throw GradingException('Model did not return valid grading JSON', e);
    }
  }
}
