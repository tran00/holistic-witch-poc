// lib/models/numerology_analysis.dart

class NumerologyAnalysis {
  String? prompt;
  String? answer;
  bool isLoading;
  String? promptType; // 'openai' or 'rag'

  NumerologyAnalysis({
    this.prompt,
    this.answer,
    this.isLoading = false,
    this.promptType,
  });

  void reset() {
    prompt = null;
    answer = null;
    isLoading = false;
    promptType = null;
  }
}