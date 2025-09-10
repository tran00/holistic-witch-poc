// lib/services/prompt_service.dart
import 'tarot_service.dart';

class PromptService {
  static String buildStandardPrompt(String question, List<String> cards, String context) {
    return "En tant qu'expert du tarot, donne un conseil détaillé à la question suivante : \"$question\" en t'appuyant sur un tirage de ${cards.length} cartes : ${cards.join(', ')}. $context";
  }

  static String buildThreeCardCustomPrompt(String question, List<String> drawnCards) {
    String cardMeanings = '';
    
    for (int i = 0; i < drawnCards.length; i++) {
      final card = drawnCards[i];
      String position = '';
      String meaningType = '';
      
      switch (i) {
        case 0:
          position = 'PREMIÈRE CARTE (Aspects positifs)';
          meaningType = 'positive';
          break;
        case 1:
          position = 'DEUXIÈME CARTE (Obstacles/Défis)';
          meaningType = 'negative';
          break;
        case 2:
          position = 'TROISIÈME CARTE (Conseils)';
          meaningType = 'advice';
          break;
      }
      
      cardMeanings += '\n\n--- $position ---\n';
      cardMeanings += 'Carte: $card\n';
      
      final cardData = TarotService.getCardData(card);
      if (cardData != null) {
        final description = cardData['description'] ?? '';
        cardMeanings += 'Description générale: $description\n\n';
        
        switch (meaningType) {
          case 'positive':
            final keywords = cardData['meanings']?['positive']?['keywords']?.join(', ') ?? '';
            final interpretation = cardData['meanings']?['positive']?['interpretation'] ?? '';
            final predictive = cardData['meanings']?['positive']?['predictive'] ?? '';
            
            cardMeanings += 'SIGNIFICATION POSITIVE (ce qui vous soutient):\n';
            if (keywords.isNotEmpty) cardMeanings += '• Mots-clés: $keywords\n';
            if (interpretation.isNotEmpty) cardMeanings += '• Interprétation: $interpretation\n';
            if (predictive.isNotEmpty) cardMeanings += '• Prédictif: $predictive\n';
            break;
            
          case 'negative':
            final keywords = cardData['meanings']?['negative']?['keywords']?.join(', ') ?? '';
            final interpretation = cardData['meanings']?['negative']?['interpretation'] ?? '';
            final predictive = cardData['meanings']?['negative']?['predictive'] ?? '';
            
            cardMeanings += 'SIGNIFICATION NÉGATIVE (obstacles à surmonter):\n';
            if (keywords.isNotEmpty) cardMeanings += '• Mots-clés: $keywords\n';
            if (interpretation.isNotEmpty) cardMeanings += '• Interprétation: $interpretation\n';
            if (predictive.isNotEmpty) cardMeanings += '• Prédictif: $predictive\n';
            break;
            
          case 'advice':
            final keywords = cardData['meanings']?['advice']?['keywords']?.join(', ') ?? '';
            final interpretation = cardData['meanings']?['advice']?['interpretation'] ?? '';
            final practical = cardData['meanings']?['advice']?['practical'] ?? '';
            
            cardMeanings += 'CONSEILS (actions à entreprendre):\n';
            if (keywords.isNotEmpty) cardMeanings += '• Mots-clés: $keywords\n';
            if (interpretation.isNotEmpty) cardMeanings += '• Interprétation: $interpretation\n';
            if (practical.isNotEmpty) cardMeanings += '• Pratique: $practical\n';
            break;
        }
      } else {
        cardMeanings += 'Carte non trouvée dans le mapping JSON.\n';
      }
    }
    
    return """En tant qu'expert du tarot, donne un conseil détaillé à la question suivante : "$question" en t'appuyant sur un tirage de trois cartes structuré.

STRUCTURE DU TIRAGE:
• 1ère carte: Aspects positifs et atouts à votre disposition
• 2ème carte: Obstacles, défis ou aspects négatifs à surmonter
• 3ème carte: Conseils et actions concrètes à entreprendre

SIGNIFICATIONS SPÉCIFIQUES: $cardMeanings

Analyse chaque carte selon sa position spécifique dans le tirage. Pour la première carte, concentre-toi sur les aspects positifs qui soutiennent la situation. Pour la deuxième, identifie les défis et obstacles basés sur les aspects négatifs. Pour la troisième, donne des conseils pratiques et actionables. Termine par une synthèse qui intègre les trois perspectives: atouts, défis, et plan d'action.""";
  }
}