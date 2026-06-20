## 0.1.0

- Initial release.
- `RubricGrader` with an injectable, provider-agnostic `LlmClient`.
- Strict-JSON grading with per-rubric score clamping and optional rationale.
- `autoGraded` flag to leave rubrics for manual grading.
- Immutable, JSON-serializable models: `Rubric`, `Question`, `RubricScore`,
  `QuestionGrade`, `GradingResult`.
