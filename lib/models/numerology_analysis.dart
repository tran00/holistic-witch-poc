// lib/models/numerology_analysis.dart

class NumerologyAnalysis {
  String? prompt;
  String? answer;
  bool isLoading;

  NumerologyAnalysis({
    this.prompt,
    this.answer,
    this.isLoading = false,
  });

  void reset() {
    prompt = null;
    answer = null;
    isLoading = false;
  }
}