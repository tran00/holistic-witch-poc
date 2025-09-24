import 'rag_service_singleton.dart';
import 'services/prompt_service.dart';

/// Helper for RAG integration in three card draw
class ThreeCardRagHelper {
  static Future<Map<String, dynamic>> askRagForThreeCards({
    required String question,
    required List<String> drawnCards,
  }) async {
    // Use a simple system prompt for RAG (no JSON enrichment)
    final systemPrompt = "Tu es un expert du tarot. Réponds à la question de l'utilisateur en t'appuyant uniquement sur le contexte fourni.";
    return await ragService.askQuestion(
      question,
      systemPrompt: systemPrompt,
      contextFilter: 'tarologie',
    );
  }
}
