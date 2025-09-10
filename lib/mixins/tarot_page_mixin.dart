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

  Future<void> askBonusOpenAI() async {
    if (drawnCards == null || bonusCards == null) return;
    if (!mounted) return;
    
    final question = questionController.text.trim();
    if (question.isEmpty) return;
    
    final allCards = [...drawnCards!, ...bonusCards!];
    final builtPrompt = PromptService.buildStandardPrompt(
      question, 
      allCards, 
      "Les 3 premières cartes sont le tirage principal, les 2 dernières sont des cartes bonus pour approfondir le conseil. Explique comment ces cartes bonus complètent ou nuancent l'interprétation initiale."
    );
    
    setState(() {
      isBonusLoading = true;
      bonusPrompt = builtPrompt;
      bonusOpenAIAnswer = null;
    });
    
    try {
      final answer = await openAI.getBonusReading(builtPrompt); // Use bonus method
      if (mounted) {
        setState(() {
          bonusOpenAIAnswer = answer;
        });
      }
    } catch (e) {
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