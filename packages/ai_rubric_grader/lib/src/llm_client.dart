/// Abstraction over a chat LLM so this package stays provider-agnostic.
///
/// Implement this with OpenAI, Azure OpenAI, Gemini, Anthropic, a local model,
/// or a fake for testing. Keeping the client injectable means grading can run
/// **server-side**, where your API key belongs — never embed keys in a client
/// app.
///
/// Implementations should request deterministic output (e.g. `temperature: 0`)
/// and, where supported, JSON mode. The grader already instructs the model to
/// return JSON, so returning the raw assistant message is enough.
abstract class LlmClient {
  /// Sends [system] and [user] prompts and returns the assistant's raw text.
  Future<String> complete({required String system, required String user});
}

/// A trivial [LlmClient] backed by a function — handy for tests and adapters.
class CallbackLlmClient implements LlmClient {
  const CallbackLlmClient(this._fn);

  final Future<String> Function(String system, String user) _fn;

  @override
  Future<String> complete({required String system, required String user}) =>
      _fn(system, user);
}
