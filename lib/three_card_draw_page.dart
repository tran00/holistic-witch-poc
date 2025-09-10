import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/tarot_service.dart';
import 'services/prompt_service.dart';
import 'services/openai_service.dart';
import 'mixins/tarot_page_mixin.dart';
import 'widgets/deck_selector.dart';
import 'widgets/app_drawer.dart';

class ThreeCardDrawPage extends StatefulWidget {
  const ThreeCardDrawPage({super.key});

  @override
  State<ThreeCardDrawPage> createState() => _ThreeCardDrawPageState();
}

class _ThreeCardDrawPageState extends State<ThreeCardDrawPage> with TarotPageMixin {
  String? customOpenAIAnswer;
  String? customPrompt;
  bool isCustomLoading = false;

  @override
  void initializeServices() {
    print('🚀 initializeServices called');
    super.initializeServices(); // This will handle OpenAI service creation
    
    // REMOVE OR COMMENT OUT THIS LINE:
    // openAI = OpenAIClient(apiKey);
    
    // The super.initializeServices() call above already creates the OpenAI service
  }

  // ADD THIS METHOD TO OVERRIDE THE MIXIN VERSION
  @override
  void showDeck() {
    print('showDeck called');
    
    // Wait for TarotService to be loaded
    if (TarotService.tarotDeck.isEmpty) {
      print('TarotService.tarotDeck is empty, waiting...');
      return;
    }
    
    print('TarotService.tarotDeck.length: ${TarotService.tarotDeck.length}');
    
    setState(() {
      selectedCards = List.filled(TarotService.tarotDeck.length, false);
      selectedIndices = <int>[];
      drawnCards = null;
      showingDeck = true;
      revealedCards = 0;
      
      // Automatically shuffle the deck order every time
      shuffledDeckOrder = List.generate(TarotService.tarotDeck.length, (index) => index);
      shuffledDeckOrder.shuffle();
      
      // Clear all responses
      openAIAnswer = null;
      prompt = null;
      customOpenAIAnswer = null;
      customPrompt = null;
      bonusCards = null;
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
      isLoading = false;
      isCustomLoading = false;
      isBonusLoading = false;
    });
    
    print('showDeck complete - selectedCards.length: ${selectedCards.length}, deck shuffled');
  }

  void drawCards() {
    debugState(); // Add this line
    setState(() {
      drawnCards = TarotService.drawCards(3);
      showingDeck = false;
      revealedCards = 0;
    });
    revealCardsOneByOne(3);
  }

  Future<void> askCustomOpenAI() async {
    if (drawnCards == null || drawnCards!.length != 3) return;
    if (!mounted) return;
    
    final question = questionController.text.trim();
    if (question.isEmpty) return;
    
    final builtPrompt = PromptService.buildThreeCardCustomPrompt(question, drawnCards!);
    
    setState(() {
      isCustomLoading = true;
      customPrompt = builtPrompt;
      customOpenAIAnswer = null;
    });
    
    try {
      final answer = await openAI.sendMessage(builtPrompt);
      if (mounted) {
        setState(() {
          customOpenAIAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          customOpenAIAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isCustomLoading = false;
        });
      }
    }
  }

  @override
  Future<void> askOpenAI() async {
    print('askOpenAI called');
    if (drawnCards == null) {
      print('No drawn cards');
      return;
    }
    if (!mounted) {
      print('Widget not mounted');
      return;
    }
    
    final question = questionController.text.trim();
    if (question.isEmpty) {
      print('Question is empty');
      return;
    }
    
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
      final answer = await openAI.sendMessage(builtPrompt);
      print('OpenAI response received: ${answer.length} characters');
      if (mounted) {
        setState(() {
          openAIAnswer = answer;
        });
        print('openAIAnswer set, bonusCards: $bonusCards, isBonusLoading: $isBonusLoading');
      }
    } catch (e) {
      print('OpenAI error: $e');
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

  @override
  Future<void> askBonusOpenAI() async {
    print('askBonusOpenAI called');
    if (drawnCards == null || bonusCards == null) {
      print('Missing drawn cards or bonus cards');
      return;
    }
    if (!mounted) {
      print('Widget not mounted');
      return;
    }
    
    final question = questionController.text.trim();
    if (question.isEmpty) {
      print('Question is empty');
      return;
    }
    
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
      final answer = await openAI.sendMessage(builtPrompt);
      print('Bonus OpenAI response received: ${answer.length} characters');
      if (mounted) {
        setState(() {
          bonusOpenAIAnswer = answer;
        });
      }
    } catch (e) {
      print('Bonus OpenAI error: $e');
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

  @override
  Future<void> revealCardsOneByOne(int totalCards) async {
    if (drawnCards == null) return;
    
    for (int i = 0; i < totalCards; i++) {
      await Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          revealedCards = i + 1;
        });
      });
    }
  }

  @override
  void selectCard(int index, int maxCards) {
    if (selectedIndices.length >= maxCards) return;

    setState(() {
      selectedCards[index] = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == maxCards) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          // Add null check and safe mapping
          if (selectedIndices.isNotEmpty) {
            drawnCards = selectedIndices.map((i) {
              if (i < TarotService.tarotDeck.length) {
                return TarotService.tarotDeck[i];
              }
              return 'Unknown Card'; // fallback
            }).toList();
          }
          showingDeck = false;
          revealedCards = 0;
        });
        revealCardsOneByOne(maxCards);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print('🚀 ThreeCardDrawPage initState called');
    try {
      initializeServices();
      print('✅ Services initialized successfully');
    } catch (e, stackTrace) {
      print('💥 Error in initState: $e');
      print('💥 Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    print('🛑 ThreeCardDrawPage dispose called');
    try {
      questionController.dispose();
      super.dispose();
      print('✅ Dispose completed successfully');
    } catch (e, stackTrace) {
      print('💥 Error in dispose: $e');
      print('💥 Stack trace: $stackTrace');
    }
  }

  @override
  void resetState() {
    setState(() {
      drawnCards = null;
      bonusCards = null;
      openAIAnswer = null;
      prompt = null;
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
      customOpenAIAnswer = null;
      customPrompt = null;
      isLoading = false;
      isCustomLoading = false;
      isBonusLoading = false;
      
      // Don't call .clear() on these lists - reinitialize them instead
      selectedCards = <bool>[];
      selectedIndices = <int>[];
      shuffledDeckOrder = <int>[]; // Make sure this is included
      
      showingDeck = false;
      revealedCards = 0;
      questionController.clear();
    });
  }

  @override
  void drawBonusCards() {
    print('drawBonusCards called');
    if (drawnCards == null) {
      print('No drawn cards for bonus');
      return;
    }
    
    setState(() {
      bonusCards = TarotService.drawBonusCards(drawnCards!, 2);
      print('Bonus cards drawn: $bonusCards');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tirage 3 cartes conseil')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 21), // for top space (adjust as needed)
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Quel conseil demander ?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: drawCards,
                    child: const Text('tirage automatique'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: showDeck,
                    child: const Text('choisir mes cartes'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Show deck if user wants to choose cards
              if (showingDeck) ...[
                DeckSelector(
                  selectedCards: selectedCards,
                  selectedIndices: selectedIndices,
                  onCardSelected: (index) => selectCard(index, 3),
                  maxCards: 3,
                  shuffledOrder: shuffledDeckOrder,
                ),
              ],

              // Show selected cards (your existing RevealTarotCard widgets)
              if (drawnCards != null && !showingDeck)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => RevealTarotCard(
                      revealed: revealedCards > index,
                      cardName: drawnCards![index],
                    ),
                  ),
                ),
              if (drawnCards != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isLoading ? null : askOpenAI,
                      child: const Text('openAI standard'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: isCustomLoading ? null : askCustomOpenAI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('openAI custom'),
                    ),
                  ],
                ),
                const SizedBox(height: 32), // <-- 32px margin before prompt label
                if (prompt != null) ...[
                  const SelectableText(
                    'Prompt envoyé à OpenAI :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      prompt!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Standard OpenAI Response
                if (isLoading)
                  const CircularProgressIndicator()
                else if (openAIAnswer != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SelectableText(
                        'Réponse de OpenAI :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SelectableText(openAIAnswer!),
                      ),
                      
                      // ADD THIS SECTION - BONUS BUTTON
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: (bonusCards == null && !isBonusLoading)
                            ? drawBonusCards
                            : null,
                        child: const Text('bonus +2 cartes conseil'),
                      ),
                      
                      // Bonus cards display
                      if (bonusCards != null) ...[
                        const SizedBox(height: 16),
                        const SelectableText(
                          'Cartes bonus tirées :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          children: bonusCards!
                              .map((card) => Chip(label: Text(card)))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: isBonusLoading ? null : askBonusOpenAI,
                          child: const Text('demander à openAI (bonus)'),
                        ),
                      ],
                    ],
                  ),
                // Custom OpenAI Response (ADD HERE)
                if (customPrompt != null) ...[
                  const SizedBox(height: 32),
                  const SelectableText(
                    'Prompt envoyé à OpenAI (custom) :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      customPrompt!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (isCustomLoading)
                  const CircularProgressIndicator()
                else if (customOpenAIAnswer != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SelectableText(
                        'Réponse de OpenAI (custom) :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SelectableText(customOpenAIAnswer!),
                      ),
                    ],
                  ),

                // ADD BONUS OPENAI RESPONSE SECTION HERE
                if (bonusPrompt != null) ...[
                  const SizedBox(height: 32),
                  const SelectableText(
                    'Prompt envoyé à OpenAI (bonus) :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      bonusPrompt!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (isBonusLoading)
                  const CircularProgressIndicator()
                else if (bonusOpenAIAnswer != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SelectableText(
                        'Réponse de OpenAI (bonus) :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SelectableText(bonusOpenAIAnswer!),
                      ),
                    ],
                  ),
              ],
              if (drawnCards != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réinitialiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    resetState();
                  },
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class RevealTarotCard extends StatelessWidget {
  final bool revealed;
  final String cardName;
  final bool selected;
  const RevealTarotCard({super.key, required this.revealed, required this.cardName, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: revealed
          ? Card(
              key: const ValueKey('front'),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 160,
                height: 140,
                child: Center(
                  child: SelectableText(
                    cardName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey('empty'),
              width: 160,
              height: 140,
            ),
    );
  }
}