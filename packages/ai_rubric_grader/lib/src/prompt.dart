import 'dart:convert';

import 'models.dart';

/// Builds the system + user prompts and parses the model's JSON response.
///
/// Unlike naive line-by-line parsing of free text, the model is asked for a
/// strict JSON object. Totals are recomputed from the rubric definitions and
/// every awarded value is clamped to `[0, points]`, so the model can never
/// inflate a score beyond what a rubric allows.
class GradingPrompt {
  const GradingPrompt({this.includeRationale = true});

  /// Ask the model to justify each rubric score.
  final bool includeRationale;

  String get system =>
      'You are a precise, consistent grading assistant. You evaluate student '
      'answers against rubrics and return ONLY a JSON object — no prose, no '
      'markdown fences. Award a rubric its full points only when the answer '
      'clearly satisfies its requirement; otherwise award partial or zero '
      'points. Never exceed a rubric\'s maximum points.';

  /// Only auto-graded rubrics are sent to the model.
  String buildUser(List<Question> questions) {
    final payload = {
      'instructions':
          'Grade each question against its rubrics. Respond with JSON of the '
              'exact shape shown in "responseSchema". awarded must be between 0 '
              'and the rubric points.',
      'responseSchema': {
        'questions': [
          {
            'questionId': 'string',
            'rubrics': [
              {
                'rubricId': 'string',
                'awarded': 0,
                if (includeRationale) 'rationale': 'string',
              }
            ],
          }
        ],
      },
      'questions': questions
          .map((q) => {
                'questionId': q.id,
                'prompt': q.prompt,
                'studentAnswer': q.answer,
                'rubrics': q.rubrics
                    .where((r) => r.autoGraded)
                    .map((r) => {
                          'rubricId': r.id,
                          'description': r.description,
                          'requirement': r.requirement,
                          'points': r.points,
                        })
                    .toList(),
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Parses [raw] into a [GradingResult], using [questions] as the source of
  /// truth for rubric points and totals. Tolerant of code fences and of missing
  /// entries (a rubric the model omitted scores 0).
  GradingResult parse(String raw, List<Question> questions) {
    final decoded = _decode(raw);
    final modelByQuestion = <String, Map<String, _ModelScore>>{};

    final questionsJson = decoded['questions'];
    if (questionsJson is List) {
      for (final q in questionsJson) {
        if (q is! Map) continue;
        final qid = q['questionId']?.toString();
        if (qid == null) continue;
        final rubricMap = <String, _ModelScore>{};
        final rubricsJson = q['rubrics'];
        if (rubricsJson is List) {
          for (final r in rubricsJson) {
            if (r is! Map) continue;
            final rid = r['rubricId']?.toString();
            if (rid == null) continue;
            rubricMap[rid] = _ModelScore(
              awarded: _toNum(r['awarded']),
              rationale: r['rationale']?.toString(),
            );
          }
        }
        modelByQuestion[qid] = rubricMap;
      }
    }

    final grades = <QuestionGrade>[];
    num grandAwarded = 0;
    num grandPossible = 0;

    for (final question in questions) {
      final modelScores = modelByQuestion[question.id] ?? const {};
      final scores = <RubricScore>[];
      num qAwarded = 0;
      num qPossible = 0;

      for (final rubric in question.rubrics.where((r) => r.autoGraded)) {
        final model = modelScores[rubric.id];
        final awarded = (model?.awarded ?? 0).clamp(0, rubric.points);
        scores.add(RubricScore(
          rubricId: rubric.id,
          awarded: awarded,
          possible: rubric.points,
          rationale: model?.rationale,
        ));
        qAwarded += awarded;
        qPossible += rubric.points;
      }

      grades.add(QuestionGrade(
        questionId: question.id,
        rubricScores: scores,
        awarded: qAwarded,
        possible: qPossible,
      ));
      grandAwarded += qAwarded;
      grandPossible += qPossible;
    }

    return GradingResult(
      questionGrades: grades,
      awarded: grandAwarded,
      possible: grandPossible,
    );
  }

  Map<String, dynamic> _decode(String raw) {
    final cleaned = _stripFences(raw);
    final value = jsonDecode(cleaned);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object at the top level');
    }
    return value;
  }

  static String _stripFences(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      final firstNewline = t.indexOf('\n');
      if (firstNewline != -1) t = t.substring(firstNewline + 1);
      final lastFence = t.lastIndexOf('```');
      if (lastFence != -1) t = t.substring(0, lastFence);
    }
    return t.trim();
  }

  static num _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class _ModelScore {
  const _ModelScore({required this.awarded, this.rationale});
  final num awarded;
  final String? rationale;
}
