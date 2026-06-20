import 'package:meta/meta.dart';

/// A single grading criterion attached to a [Question].
///
/// A rubric is worth [points] and is awarded all-or-nothing or partially by the
/// grader, depending on how well the answer meets [requirement].
@immutable
class Rubric {
  const Rubric({
    required this.id,
    required this.description,
    required this.requirement,
    required this.points,
    this.autoGraded = true,
  }) : assert(points >= 0, 'points must be non-negative');

  /// Stable identifier, unique within a [Question].
  final String id;

  /// Human-readable label, e.g. "Correct final answer".
  final String description;

  /// What the answer must satisfy to earn the points. This is the instruction
  /// the LLM evaluates against.
  final String requirement;

  /// Maximum points this rubric can award.
  final num points;

  /// When `false`, the rubric is left for a human to grade and is excluded from
  /// the LLM request.
  final bool autoGraded;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'requirement': requirement,
        'points': points,
        'autoGraded': autoGraded,
      };

  factory Rubric.fromJson(Map<String, dynamic> json) => Rubric(
        id: json['id'] as String,
        description: json['description'] as String? ?? '',
        requirement: json['requirement'] as String? ?? '',
        points: json['points'] as num? ?? 0,
        autoGraded: json['autoGraded'] as bool? ?? true,
      );
}

/// A question to be graded, with the student's [answer] and its [rubrics].
@immutable
class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.answer,
    required this.rubrics,
  });

  /// Stable identifier, unique within a grading request.
  final String id;

  /// The question text.
  final String prompt;

  /// The student's answer (plain text, LaTeX, transcribed handwriting, ...).
  final String answer;

  /// The rubrics this question is graded against.
  final List<Rubric> rubrics;

  /// Total points available across all rubrics.
  num get totalPoints =>
      rubrics.fold<num>(0, (sum, r) => sum + r.points);

  /// Total points available across rubrics that are auto-graded.
  num get autoGradablePoints => rubrics
      .where((r) => r.autoGraded)
      .fold<num>(0, (sum, r) => sum + r.points);

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'answer': answer,
        'rubrics': rubrics.map((r) => r.toJson()).toList(),
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        prompt: json['prompt'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        rubrics: (json['rubrics'] as List<dynamic>? ?? [])
            .map((e) => Rubric.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// The score awarded for a single [Rubric].
@immutable
class RubricScore {
  const RubricScore({
    required this.rubricId,
    required this.awarded,
    required this.possible,
    this.rationale,
  });

  final String rubricId;

  /// Points awarded, always within `[0, possible]`.
  final num awarded;

  /// Maximum points (mirrors the rubric's `points`).
  final num possible;

  /// Optional model explanation for the score.
  final String? rationale;

  /// Whether the rubric earned full marks.
  bool get isFullyMet => awarded >= possible;

  Map<String, dynamic> toJson() => {
        'rubricId': rubricId,
        'awarded': awarded,
        'possible': possible,
        if (rationale != null) 'rationale': rationale,
      };
}

/// The grade for a single [Question]: its rubric scores and totals.
@immutable
class QuestionGrade {
  const QuestionGrade({
    required this.questionId,
    required this.rubricScores,
    required this.awarded,
    required this.possible,
  });

  final String questionId;
  final List<RubricScore> rubricScores;

  /// Sum of awarded rubric points for this question.
  final num awarded;

  /// Sum of possible rubric points for this question.
  final num possible;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'awarded': awarded,
        'possible': possible,
        'rubricScores': rubricScores.map((s) => s.toJson()).toList(),
      };
}

/// The full result of grading a set of questions.
@immutable
class GradingResult {
  const GradingResult({
    required this.questionGrades,
    required this.awarded,
    required this.possible,
  });

  final List<QuestionGrade> questionGrades;

  /// Total awarded across all questions.
  final num awarded;

  /// Total possible across all questions.
  final num possible;

  /// Score as a fraction in `[0, 1]` (0 when nothing is gradable).
  double get fraction => possible == 0 ? 0 : awarded / possible;

  /// Score as a percentage in `[0, 100]`.
  double get percentage => fraction * 100;

  Map<String, dynamic> toJson() => {
        'awarded': awarded,
        'possible': possible,
        'percentage': percentage,
        'questionGrades': questionGrades.map((g) => g.toJson()).toList(),
      };
}
