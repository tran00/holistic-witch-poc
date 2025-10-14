// lib/services/prompt_service.dart

class PromptService {
  /// Generic prompt builder for any tarot reading layout
  static String buildStandardPrompt(String question, List<String> cards, String context) {
    return "En tant qu'expert du tarot, donne un conseil détaillé à la question suivante : \"$question\" en t'appuyant sur un tirage de ${cards.length} cartes : ${cards.join(', ')}. $context";
  }
}