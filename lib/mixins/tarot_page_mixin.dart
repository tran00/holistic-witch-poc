// mixins/tarot_page_mixin.dart
import 'package:flutter/material.dart';
import '../services/tarot_service.dart';
import '../services/openai_service.dart';
import '../services/prompt_service.dart';

mixin TarotPageMixin<T extends StatefulWidget> on State<T> {
  List<String>? drawnCards;
  String? openAIAnswer;
  String? prompt;
  bool isLoading = false;
  int revealedCards = 0;
  
  // Bonus functionality
  List<String>? bonusCards;
  String? bonusPrompt;
  String? bonusOpenAIAnswer;
  bool isBonusLoading = false;
  
  // Deck selection state
  List<bool> selectedCards = <bool>[];
  List<int> selectedIndices = <int>[];
  bool showingDeck = false;
  List<int> shuffledDeckOrder = <int>[];
  
  late OpenAIService openAI;
  final TextEditingController questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeServices();
  }

  void initializeServices() async {
    await TarotService.loadTarotMeanings();
    openAI = OpenAIService();
  }

  @override
  void dispose() {
    // SAFE DISPOSAL - Check if controller is still valid
    try {
      if (!questionController.hasListeners || questionController.text.isNotEmpty || questionController.text.isEmpty) {
        // Controller is still valid, safe to dispose
        questionController.dispose();
        print('✅ TextEditingController disposed safely');
      }
    } catch (e) {
      // Controller was already disposed, that's fine
      print('⚠️ TextEditingController was already disposed: $e');
    }
    
    super.dispose();
  }

  void showDeck() {
    print('showDeck called - TarotService.tarotDeck.length: ${TarotService.tarotDeck.length}');
    
    setState(() {
      selectedCards = List.filled(TarotService.tarotDeck.length, false);
      selectedIndices = <int>[];
      drawnCards = null;
      showingDeck = true;
      revealedCards = 0;
      
      // Initialize shuffled order if not already done
      if (shuffledDeckOrder.isEmpty) {
        shuffledDeckOrder = List.generate(TarotService.tarotDeck.length, (index) => index);
        shuffledDeckOrder.shuffle();
      }
      
      // Clear all OpenAI responses
      openAIAnswer = null;
      prompt = null;
      bonusCards = null;
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
      isLoading = false;
      isBonusLoading = false;
    });
    
    print('showDeck complete - selectedCards.length: ${selectedCards.length}');
  }

  void selectCard(int index, int maxCards) {
    if (selectedIndices.length >= maxCards) return;
    
    // Add bounds checking
    if (index < 0 || index >= TarotService.tarotDeck.length) {
      print('Invalid card index: $index');
      return;
    }

    setState(() {
      selectedCards[index] = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == maxCards) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          // Add safety checks and filtering
          final validIndices = selectedIndices.where((i) => 
            i >= 0 && i < TarotService.tarotDeck.length
          ).toList();
          
          if (validIndices.isNotEmpty) {
            drawnCards = validIndices.map((i) => TarotService.tarotDeck[i]).toList();
          } else {
            print('No valid indices found');
            drawnCards = [];
          }
          
          showingDeck = false;
          revealedCards = 0;
        });
        
        if (drawnCards != null && drawnCards!.isNotEmpty) {
          revealCardsOneByOne(maxCards);
        }
      });
    }
  }

  void revealCardsOneByOne(int maxCards) async {
    for (int i = 1; i <= maxCards; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        revealedCards = i;
      });
    }
  }

  Future<void> askOpenAI() async {
    if (drawnCards == null) return;
    if (!mounted) return;
    
    final question = questionController.text.trim();
    if (question.isEmpty) return;
    
    final builtPrompt = PromptService.buildStandardPrompt(
      question, 
      drawnCards!, 
      "Explique le sens de chaque carte dans le contexte de la question et donne une synthèse."
    );
    
    setState(() {
      isLoading = true;
      prompt = builtPrompt;
      openAIAnswer = null;
    });
    
    try {
      final answer = await openAI.getTarotReading(builtPrompt); // Use specialized method
      if (mounted) {
        setState(() {
          openAIAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          openAIAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void drawBonusCards() {
    if (drawnCards == null) return;
    setState(() {
      bonusCards = TarotService.drawBonusCards(drawnCards!, 2);
    });
  }

  @override
  Future<void> askBonusOpenAI() async {
    print('🎯 askBonusOpenAI called from mixin');
    
    if (bonusCards == null) {
      print('❌ No bonus cards');
      return;
    }
    
    final question = questionController.text.trim();
    if (question.isEmpty) {
      print('❌ Question is empty');
      return;
    }
    
    // BUILD SPECIFIC CARD MEANINGS (positive 1st, negative 2nd, advice 3rd)
    String originalCardMeaningsText = '';
    if (drawnCards != null && drawnCards!.length >= 3) {
      originalCardMeaningsText = '\nCartes principales:\n';
      
      // 1st card - POSITIVE only
      final firstCardData = TarotService.getFullCardData(drawnCards![0]);
      if (firstCardData != null) {
        originalCardMeaningsText += '- ${drawnCards![0]} (aspect positif):\n';
        if (firstCardData['meanings']?['positive'] != null) {
          originalCardMeaningsText += '  ${firstCardData['meanings']['positive']}\n\n';
        } else {
          originalCardMeaningsText += '  (aspect positif non trouvé)\n\n';
        }
      }
      
      // 2nd card - NEGATIVE only
      final secondCardData = TarotService.getFullCardData(drawnCards![1]);
      if (secondCardData != null) {
        originalCardMeaningsText += '- ${drawnCards![1]} (aspect négatif):\n';
        if (secondCardData['meanings']?['negative'] != null) {
          originalCardMeaningsText += '  ${secondCardData['meanings']['negative']}\n\n';
        } else {
          originalCardMeaningsText += '  (aspect négatif non trouvé)\n\n';
        }
      }
      
      // 3rd card - ADVICE only
      final thirdCardData = TarotService.getFullCardData(drawnCards![2]);
      if (thirdCardData != null) {
        originalCardMeaningsText += '- ${drawnCards![2]} (conseil):\n';
        if (thirdCardData['meanings']?['advice']?['interpretation'] != null) {
          originalCardMeaningsText += '  ${thirdCardData['meanings']['advice']['interpretation']}\n';
        }
        if (thirdCardData['meanings']?['advice']?['practical'] != null) {
          originalCardMeaningsText += '  Pratique: ${thirdCardData['meanings']['advice']['practical']}\n';
        }
        originalCardMeaningsText += '\n';
      }
    }
    
    // BUILD BONUS CARDS MEANINGS (advice only from both)
    String bonusCardMeaningsText = '\nCartes bonus (conseils supplémentaires):\n';
    for (String cardName in bonusCards!) {
      final cardData = TarotService.getFullCardData(cardName);
      if (cardData != null) {
        bonusCardMeaningsText += '- $cardName (conseil):\n';
        
        // Add advice interpretation
        if (cardData['meanings']?['advice']?['interpretation'] != null) {
          bonusCardMeaningsText += '  ${cardData['meanings']['advice']['interpretation']}\n';
        }
        
        // Add practical advice if available
        if (cardData['meanings']?['advice']?['practical'] != null) {
          bonusCardMeaningsText += '  Pratique: ${cardData['meanings']['advice']['practical']}\n';
        }
        
        bonusCardMeaningsText += '\n';
      } else {
        bonusCardMeaningsText += '- $cardName: (conseil non trouvé)\n\n';
      }
    }
    
    final builtPrompt = '''
Question: $question
$originalCardMeaningsText
$bonusCardMeaningsText

Instructions: En tant qu'expert en tarot, utilise les significations spécifiques des cartes ci-dessus pour donner une interprétation ciblée. 

Structure de lecture:
- 1ère carte (aspect positif): Les atouts et forces disponibles
- 2ème carte (aspect négatif): Les défis et obstacles à surmonter  
- 3ème carte (conseil): La guidance principale pour la situation
- Cartes bonus (conseils): Guidance supplémentaire et actions complémentaires

1. Explique comment l'aspect positif de la 1ère carte peut être utilisé comme force
2. Identifie les défis révélés par l'aspect négatif de la 2ème carte
3. Intègre le conseil de la 3ème carte comme direction principale
4. Enrichis avec les conseils des 2 cartes bonus pour une guidance complète
5. Synthétise en un plan d'action cohérent qui utilise les forces, surmonte les défis, et suit tous les conseils

Réponds en français avec une interprétation structurée et des conseils pratiques concrets.
''';

    setState(() {
      isBonusLoading = true;
      bonusPrompt = builtPrompt;
      bonusOpenAIAnswer = null;
    });
    
    try {
      final answer = await openAI.getTarotReading(builtPrompt);
      print('📥 Bonus OpenAI response received: ${answer.length} characters');
      
      if (mounted) {
        setState(() {
          bonusOpenAIAnswer = answer;
        });
      }
    } catch (e) {
      print('💥 Error in askBonusOpenAI: $e');
      if (mounted) {
        setState(() {
          bonusOpenAIAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isBonusLoading = false;
        });
      }
    }
  }

  void resetState() {
    setState(() {
      drawnCards = null;
      bonusCards = null;
      openAIAnswer = null;
      prompt = null;
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
      isLoading = false;
      isBonusLoading = false;
      
      // Reinitialize instead of clearing
      selectedCards = <bool>[];
      selectedIndices = <int>[];
      shuffledDeckOrder = <int>[];
      
      showingDeck = false;
      revealedCards = 0;
      questionController.clear();
    });
  }
  
  void debugState() {
    print('=== DEBUG STATE ===');
    print('TarotService.tarotDeck.length: ${TarotService.tarotDeck.length}');
    print('selectedCards.length: ${selectedCards.length}');
    print('selectedIndices: $selectedIndices');
    print('showingDeck: $showingDeck');
    print('drawnCards: $drawnCards');
    print('==================');
  }
  
  void shuffleDeck() {
    setState(() {
      // Create a shuffled list of indices
      final shuffledIndices = List.generate(TarotService.tarotDeck.length, (index) => index);
      shuffledIndices.shuffle();
      
      // Reset selection state
      selectedCards = List.filled(TarotService.tarotDeck.length, false);
      selectedIndices.clear();
      
      // Store the shuffled order
      shuffledDeckOrder = shuffledIndices;
    });
    
    print('Deck shuffled!');
  }
}