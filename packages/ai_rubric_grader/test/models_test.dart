import 'package:ai_rubric_grader/ai_rubric_grader.dart';
import 'package:test/test.dart';

void main() {
  group('Question totals', () {
    final question = Question(
      id: 'q1',
      prompt: 'Solve 2 + 2',
      answer: '4',
      rubrics: const [
        Rubric(id: 'r1', description: 'Correct', requirement: 'answer is 4', points: 3),
        Rubric(id: 'r2', description: 'Shown work', requirement: 'shows steps', points: 2, autoGraded: false),
      ],
    );

    test('totalPoints sums all rubrics', () {
      expect(question.totalPoints, 5);
    });

    test('autoGradablePoints excludes manual rubrics', () {
      expect(question.autoGradablePoints, 3);
    });
  });

  group('serialization', () {
    test('Rubric round-trips through JSON', () {
      const r = Rubric(
        id: 'r1', description: 'd', requirement: 'req', points: 4, autoGraded: false);
      final back = Rubric.fromJson(r.toJson());
      expect(back.id, 'r1');
      expect(back.points, 4);
      expect(back.autoGraded, isFalse);
    });

    test('Question round-trips with rubrics', () {
      final q = Question(
        id: 'q1', prompt: 'p', answer: 'a',
        rubrics: const [Rubric(id: 'r1', description: 'd', requirement: 'r', points: 1)]);
      final back = Question.fromJson(q.toJson());
      expect(back.rubrics.single.id, 'r1');
      expect(back.answer, 'a');
    });

    test('GradingResult exposes fraction and percentage', () {
      const result = GradingResult(questionGrades: [], awarded: 3, possible: 4);
      expect(result.fraction, closeTo(0.75, 1e-9));
      expect(result.percentage, closeTo(75, 1e-9));
    });

    test('percentage is 0 when nothing is possible', () {
      const result = GradingResult(questionGrades: [], awarded: 0, possible: 0);
      expect(result.percentage, 0);
    });
  });
}
