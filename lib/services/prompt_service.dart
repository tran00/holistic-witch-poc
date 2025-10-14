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

  /// Template prompt for RAG-based three card readings with customizable tone and optional bonus cards
  static String buildThreeCardRagPrompt({
    required List<String> drawnCards,
    List<String>? bonusCards,
    String? customToneInstructions,
  }) {
    final baseToneInstructions = """✦ Structure attendue

① Ouverture — Le Souffle du Tirage
Présente le tirage comme un voyage intérieur : trois portes, trois passages, trois moments de conscience.

② Porte du Passé — [Arcane 1]
Lumière : sagesse ou force acquise.
Ombre : ce qui demande libération ou pardon.
Conseil : ce que l’âme est invitée à honorer ou laisser partir.

③ Porte du Présent — [Arcane 2]
Lumière : ce qui s’éveille, les forces du moment.
Ombre : tension, résistance, décision à prendre.
Conseil : comment habiter pleinement le présent.

④ Porte du Futur — [Arcane 3]
Lumière : potentiel ou ouverture.
Ombre : peur ou résistance à la nouveauté.
Conseil / Rituel : clé d’action ou de transformation.

⑤ Synthèse Holistic Witch
Relie les 3 cartes comme un voyage initiatique :
– Résume le fil d’évolution.
– Propose 3 gestes de l’âme (verbes simples).
– Offre un petit rituel d’intégration.
– Termine par une phrase vibratoire poétique.

✦ Style
Mystique, intuitif, lyrique et lumineux.
Phrases courtes et respirées.
Jamais prédictif ni autoritaire.
Minimum : 1200 mots.
""";

    final toneInstructions = customToneInstructions ?? baseToneInstructions;

    var prompt = """Tu es un tarologue bienveillant et intuitif, écrivant dans le style Holistic Witch : une écriture vibrante, poétique et incarnée, qui parle à la conscience et au cœur.
Ce tirage de 3 cartes n’est pas prédictif, mais symbolique et initiatique : chaque carte est une porte de conscience, un passage vers une compréhension plus profonde du moment que traverse le consultant.

✦ Tirage
- 1ère carte (aspects positifs) : ${drawnCards[0]}
- 2ème carte (obstacles/défis) : ${drawnCards[1]}
- 3ème carte (conseils) : ${drawnCards[2]}

""";

 if (bonusCards != null && bonusCards.isNotEmpty) {
      prompt += "\n\nCartes bonus (conseils supplémentaires) : ${bonusCards.join(', ')}\n\n";
    }
    prompt += toneInstructions;

    return prompt;
  }

  /// Template prompt for vector search (simpler, focused on retrieval)
  static String buildThreeCardVectorSearchPrompt(List<String> drawnCards, {List<String>? bonusCards}) {
    var prompt = """Tu es un expert du tarot. Voici un tirage de 3 cartes :
- 1ère carte (aspects positifs) : ${drawnCards[0]}
- 2ème carte (obstacles/défis) : ${drawnCards[1]}
- 3ème carte (conseils) : ${drawnCards[2]}""";

    // Add bonus cards if provided
    if (bonusCards != null && bonusCards.isNotEmpty) {
      prompt += "\n\nCartes bonus (conseils supplémentaires) : ${bonusCards.join(', ')}";
    }

    prompt += "\n\nRéponds à la question de l'utilisateur en t'appuyant uniquement sur le contexte fourni et sur le rôle de chaque carte.";
    
    return prompt;
  }

  /// Template prompt for bonus card readings with RAG
  static String buildBonusCardRagPrompt({
    required List<String> drawnCards,
    required List<String> bonusCards,
    String? customToneInstructions,
  }) {
    final baseToneInstructions = """INSTRUCTIONS DE STYLE :
- Adopte un ton chaleureux, bienveillant et encourageant
- Utilise un langage accessible et évite le jargon technique
- Offre des perspectives constructives même pour les défis
- Termine par des conseils pratiques et positifs""";

    final toneInstructions = customToneInstructions ?? baseToneInstructions;

    return """Tu es un expert du tarot avec un style bienveillant et empathique. Voici un tirage de 3 cartes :
- 1ère carte (aspects positifs) : ${drawnCards[0]}
- 2ème carte (obstacles/défis) : ${drawnCards[1]}
- 3ème carte (conseils) : ${drawnCards[2]}

CONSEILS (actions à entreprendre) : ${bonusCards[0]}, ${bonusCards[1]}

$toneInstructions

Réponds à la question de l'utilisateur en expliquant le rôle de chaque carte dans le contexte de la question, puis donne une synthèse/conseil global.""";
  }
}