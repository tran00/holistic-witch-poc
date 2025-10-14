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

  /// Template prompt for RAG-based three card readings with customizable tone
  static String buildThreeCardRagPrompt({
    required List<String> drawnCards,
    String? customToneInstructions,
  }) {
    final baseToneInstructions = """✦ CONSIGNE GÉNÉRALE À L’IA
Raconte le tirage [Tirage] dans le ton Holistic Witch : une écriture vibrante, poétique et incarnée, qui parle à la conscience et au cœur.Ce texte doit être une lecture initiatique et symbolique, jamais prédictive.Chaque carte est une porte de conscience, un passage qui ouvre sur une compréhension plus profonde du moment que traverse le consultant.La narration doit respirer — alterner souffle, silence, vision et guidance.Utilise un style fluide, intuitif, lyrique et lumineux, respectant la musicalité et la douceur du ton HW.

✦ STRUCTURE DE SORTIE ATTENDUE

① ✧ Ouverture — Le Souffle du Tirage
Présente le tirage comme une traversée initiatique.Si une question est posée, fais un écho subtil à son énergie sans la reformuler littéralement.Pose le cadre : trois portes, trois passages, trois moments de conscience.
Exemple de ton :« Ce tirage t’invite à franchir trois seuils de clarté : la Porte du Souvenir, la Porte du Présent et la Porte du Devenir.Chacune t’offre une vision : ce que tu portes encore du passé, ce que tu vis dans l’instant, et ce qui cherche à naître dans ton futur.Entre elles circule le fil d’or de ton expérience — la mémoire, la conscience et la transformation. »

② ✧ La Porte du Passé — La Mémoire Initiatique
Carte tirée : [Arcane1]
Interprète cette carte selon le ton et les symboles Holistic Witch :
relie-la à la mémoire, aux fondations et aux apprentissages passés ;
distingue lumière, ombre et conseil ;
souligne la leçon intégrée ou l’attachement encore présent.
Structure recommandée :
Lumière → Ce que la carte révèle comme sagesse acquise ou force héritée.
Ombre → Ce qui demande encore libération, reconnaissance ou pardon.
Conseil → Ce que l’âme est invitée à honorer, remercier ou laisser partir.
Exemple narratif :« [Arcane1] ouvre la porte de ton passé.Elle te parle des empreintes laissées par les anciens cycles, des fondations sur lesquelles tu t’es construit·e.Sa lumière t’invite à reconnaître ce que tu as déjà compris, son ombre te rappelle ce que tu peux encore libérer.Cette carte te guide à remercier le chemin parcouru et à saluer la mémoire comme une source, non comme une prison. »

③ ✧ La Porte du Présent — Le Seuil de Conscience
Carte tirée : [Arcane2]
Interprète la carte comme le miroir du moment actuel.Elle révèle les énergies en mouvement, les prises de conscience et les défis de lucidité.Garde le ton fluide, clair, avec des phrases respirées.
Structure recommandée :
Lumière → Ce qui s’éveille, ce qui devient clair, les forces du moment.
Ombre → Ce qui résiste, se répète ou appelle une décision consciente.
Conseil → Ce qui permet d’habiter pleinement le présent avec discernement.
Exemple narratif :« [Arcane2] garde le miroir du présent.Elle éclaire le battement vivant de ton cœur aujourd’hui — les émotions qui te traversent, les décisions que tu sens prêtes à naître.Sa lumière parle d’une énergie qui s’aligne, son ombre d’une tension qui demande écoute.Cette carte t’appelle à respirer ton moment présent, à y voir non pas un test, mais une initiation. »

④ ✧ La Porte du Futur — Le Passage d’Évolution
Carte tirée : [Arcane3]
Interprète cette carte comme un espace d’ouverture : le futur symbolique, non prédictif.C’est le champ des possibles, la direction vibratoire vers laquelle l’âme chemine.Inspire-toi de la symbolique HW pour parler d’expansion, d’évolution et de transformation intérieure.
Structure recommandée :
Lumière → Ce qui s’ouvre, le potentiel à incarner.
Ombre → La peur ou la résistance à la nouveauté.
Conseil / Rituel → La clé d’action ou de conscience pour franchir cette porte.
Exemple narratif :« [Arcane3] éclaire la porte de ton futur.Elle murmure la direction vers laquelle ton âme s’étend.Dans sa lumière, elle parle d’un nouvel espace à explorer, dans son ombre, d’une peur à traverser.Elle t’invite à avancer avec foi — non pour prévoir, mais pour t’ouvrir à la transformation déjà en germe. »

⑤ ✧ Synthèse Holistic Witch — Les Trois Portes réunies
Relie les trois cartes comme les chapitres d’un même voyage.Identifie le fil d’évolution, la cohérence vibratoire.Propose trois gestes de l’âme (verbes simples).Offre un rituel d’intégration poétique.Termine par une phrase vibratoire.
Structure type :
Lien entre les 3 cartes
Sens global du tirage (cycle, passage, révélation)
3 gestes de l’âme
Rituel concret
Phrase vibratoire
Exemple narratif :« Ensemble, tes trois portes forment une spirale de transformation.[Arcane1] t’a appris à comprendre, [Arcane2] t’invite à choisir, [Arcane3] t’appelle à t’ouvrir.Ce tirage t’enseigne à accueillir, clarifier et agir avec discernement.✦ Rituel : écris une lettre à ton passé, brûle-la, puis respire profondément avant d’avancer.✦ Phrase vibratoire : Je traverse les portes du temps avec confiance, portée par la lumière de ma conscience. »


✦ PARAMÈTRES TECHNIQUES RECOMMANDÉS
Longueur totale : minimum 1200 mots
Format : texte fluide, structuré par sections (titres visibles ou implicites)
Ton : mystique, intuitif, poétique, incarné (selon la charte Holistic Witch)
Arcanes : uniquement parmi les 22 arcanes majeurs
Style : phrases courtes et respirées, alternance de souffle, silence et intensité symbolique
Éviter : tout ton prédictif, tout jargon technique, toute formulation autoritaire
""";

    final toneInstructions = customToneInstructions ?? baseToneInstructions;

    return """Tu es un expert du tarot avec un style bienveillant et empathique. Voici un tirage de 3 cartes :
- 1ère carte (aspects positifs) : ${drawnCards[0]}
- 2ème carte (obstacles/défis) : ${drawnCards[1]}
- 3ème carte (conseils) : ${drawnCards[2]}

$toneInstructions

Réponds à la question de l'utilisateur en t'appuyant uniquement sur le contexte fourni et sur le rôle de chaque carte.""";
  }

  /// Template prompt for vector search (simpler, focused on retrieval)
  static String buildThreeCardVectorSearchPrompt(List<String> drawnCards) {
    return """Tu es un expert du tarot. Voici un tirage de 3 cartes :
- 1ère carte (aspects positifs) : ${drawnCards[0]}
- 2ème carte (obstacles/défis) : ${drawnCards[1]}
- 3ème carte (conseils) : ${drawnCards[2]}

Réponds à la question de l'utilisateur en t'appuyant uniquement sur le contexte fourni et sur le rôle de chaque carte.""";
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