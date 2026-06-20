import 'dart:convert';

import 'package:ai_rubric_grader/ai_rubric_grader.dart';
import 'package:test/test.dart';

/// A fake LLM that returns a scripted response and records the prompt it saw.
class FakeLlm implements LlmClient {
  FakeLlm(this.response);
  final String response;
  String? lastUser;
  String? lastSystem;

  @override
  Future<String> complete({required String system, required String user}) async {
    lastSystem = system;
    lastUser = user;
    return response;
  }
}

List<Question> sampleQuestions() => const [
      Question(
        id: 'q1',
        prompt: 'Differentiate x^2',
        answer: '2x',
        rubrics: [
          Rubric(id: 'r1', description: 'Correct derivative', requirement: 'equals 2x', points: 5),
          Rubric(id: 'r2', description: 'Notation', requirement: 'uses dy/dx', points: 2),
        ],
      ),
    ];

String response(Map<String, dynamic> body) => jsonEncode(body);

void main() {
  test('grades a correct answer with full marks', () async {
    final llm = FakeLlm(response({
      'questions': [
        {
          'questionId': 'q1',
          'rubrics': [
            {'rubricId': 'r1', 'awarded': 5, 'rationale': 'matches 2x'},
            {'rubricId': 'r2', 'awarded': 2},
          ],
        }
      ],
    }));

    final result = await RubricGrader(llm).grade(sampleQuestions());

    expect(result.awarded, 7);
    expect(result.possible, 7);
    expect(result.percentage, 100);
    expect(result.questionGrades.single.rubricScores.first.rationale, 'matches 2x');
  });

  test('clamps an over-awarded score to the rubric maximum', () async {
    final llm = FakeLlm(response({
      'questions': [
        {
          'questionId': 'q1',
          'rubrics': [
            {'rubricId': 'r1', 'awarded': 999}, // model tries to over-award
            {'rubricId': 'r2', 'awarded': 2},
          ],
        }
      ],
    }));

    final result = await RubricGrader(llm).grade(sampleQuestions());
    expect(result.awarded, 7); // 5 (clamped) + 2
  });

  test('negative awards are clamped to zero', () async {
    final llm = FakeLlm(response({
      'questions': [
        {'questionId': 'q1', 'rubrics': [{'rubricId': 'r1', 'awarded': -3}]}
      ],
    }));
    final result = await RubricGrader(llm).grade(sampleQuestions());
    expect(result.questionGrades.single.rubricScores.first.awarded, 0);
  });

  test('a rubric the model omitted scores zero', () async {
    final llm = FakeLlm(response({
      'questions': [
        {'questionId': 'q1', 'rubrics': [{'rubricId': 'r1', 'awarded': 5}]}
      ],
    }));
    final result = await RubricGrader(llm).grade(sampleQuestions());
    expect(result.awarded, 5); // r2 omitted -> 0
    expect(result.possible, 7);
  });

  test('strips ```json fences before parsing', () async {
    final body = response({
      'questions': [
        {'questionId': 'q1', 'rubrics': [{'rubricId': 'r1', 'awarded': 5}]}
      ],
    });
    final llm = FakeLlm('```json\n$body\n```');
    final result = await RubricGrader(llm).grade(sampleQuestions());
    expect(result.awarded, 5);
  });

  test('only auto-graded rubrics are sent to the model', () async {
    final llm = FakeLlm(response({'questions': []}));
    final questions = const [
      Question(id: 'q1', prompt: 'p', answer: 'a', rubrics: [
        Rubric(id: 'r1', description: 'auto', requirement: 'x', points: 3),
        Rubric(id: 'r2', description: 'manual', requirement: 'y', points: 4, autoGraded: false),
      ]),
    ];
    await RubricGrader(llm).grade(questions);
    expect(llm.lastUser, contains('r1'));
    expect(llm.lastUser, isNot(contains('r2')));
  });

  test('empty questions returns an empty result without calling the model', () async {
    var called = false;
    final llm = CallbackLlmClient((s, u) async {
      called = true;
      return '{}';
    });
    final result = await RubricGrader(llm).grade([]);
    expect(result.possible, 0);
    expect(called, isFalse);
  });

  test('invalid JSON throws GradingException', () async {
    final llm = FakeLlm('the answer is definitely correct, full marks!');
    expect(
      () => RubricGrader(llm).grade(sampleQuestions()),
      throwsA(isA<GradingException>()),
    );
  });

  test('LLM transport error is wrapped in GradingException', () async {
    final llm = CallbackLlmClient((s, u) async => throw StateError('boom'));
    expect(
      () => RubricGrader(llm).grade(sampleQuestions()),
      throwsA(isA<GradingException>()),
    );
  });
}
