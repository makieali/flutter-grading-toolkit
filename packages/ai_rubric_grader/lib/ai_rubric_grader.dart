/// LLM-agnostic, rubric-based automatic grading for Dart.
///
/// Provide an [LlmClient] (OpenAI, Gemini, Anthropic, Azure, a local model, or
/// a fake), describe your [Question]s and [Rubric]s, and [RubricGrader] returns
/// a structured [GradingResult] with clamped per-rubric scores and optional
/// rationale.
library ai_rubric_grader;

export 'src/grader.dart' show RubricGrader, GradingException;
export 'src/llm_client.dart' show LlmClient, CallbackLlmClient;
export 'src/models.dart'
    show Rubric, Question, RubricScore, QuestionGrade, GradingResult;
export 'src/prompt.dart' show GradingPrompt;
