import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/tarot_service.dart';
import 'services/prompt_service.dart';
import 'services/openai_service.dart';
import 'mixins/tarot_page_mixin.dart';
import 'widgets/deck_selector.dart';
import 'widgets/app_drawer.dart';
// import 'widgets/reveal_tarot_card.dart'; // Add this if missing

class ThreeCardDrawPage extends StatefulWidget {
  const ThreeCardDrawPage({super.key});

  @override
  State<ThreeCardDrawPage> createState() => _ThreeCardDrawPageState();
}

class _ThreeCardDrawPageState extends State<ThreeCardDrawPage> with TarotPageMixin {
  String? customOpenAIAnswer;
  String? customPrompt;
  bool isCustomLoading = false;
  
  // ADD THESE BONUS SELECTION VARIABLES
  bool showingBonusSelection = false;
  List<bool> bonusSelectedCards = <bool>[];
  List<int> bonusSelectedIndices = <int>[];
  
  // ADD THESE IF MISSING
  List<String>? bonusCards;
  String? bonusOpenAIAnswer;
  bool isBonusLoading = false;
  
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
    print('🎯 askOpenAI called');
    
    if (drawnCards == null) {
      print('❌ No drawn cards');
      return;
    }
    
    final question = questionController.text.trim();
    if (question.isEmpty) {
      print('❌ Question is empty');
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
      // Make sure bonus state is reset
      bonusCards = null;
      bonusOpenAIAnswer = null;
      isBonusLoading = false;
    });
    
    try {
      final answer = await openAI.getTarotReading(builtPrompt);
      print('📥 OpenAI response received: ${answer.length} characters');
      
      if (mounted) {
        setState(() {
          openAIAnswer = answer;
        });
        print('✅ openAIAnswer set to: ${openAIAnswer?.substring(0, 50)}...');
        print('✅ bonusCards: $bonusCards');
        print('✅ isBonusLoading: $isBonusLoading');
        print('✅ Bonus button should be visible now');
      }
    } catch (e) {
      print('💥 Error in askOpenAI: $e');
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
      
      // Reset regular selection
      selectedCards = <bool>[];
      selectedIndices = <int>[];
      shuffledDeckOrder = <int>[];
      showingDeck = false;
      revealedCards = 0;
      
      // Reset bonus selection
      showingBonusSelection = false;
      bonusSelectedCards = <bool>[];
      bonusSelectedIndices = <int>[];
      
      questionController.clear();
    });
  }

  @override
  void drawBonusCards() {
    print('🎲 drawBonusCards called');
    if (drawnCards == null) {
      print('❌ No drawn cards for bonus');
      return;
    }
    
    setState(() {
      bonusCards = TarotService.drawBonusCards(drawnCards!, 2);
      print('✅ Bonus cards drawn: $bonusCards');
    });
  }

  void showBonusCardSelection() {
    print('🎲 showBonusCardSelection called');
    if (drawnCards == null) {
      print('❌ No drawn cards for bonus selection');
      return;
    }
    
    setState(() {
      showingBonusSelection = true;
      
      // Initialize selection state for all cards
      bonusSelectedCards = List.filled(TarotService.tarotDeck.length, false);
      bonusSelectedIndices = <int>[];
      
      print('✅ Bonus selection mode activated');
    });
  }

  void selectBonusCard(int index) {
    print('🎯 selectBonusCard called with index: $index');
    print('🎯 Current bonusSelectedIndices.length: ${bonusSelectedIndices.length}');
    print('🎯 Current bonusSelectedCards[index]: ${bonusSelectedCards[index]}');
    
    if (bonusSelectedIndices.length >= 2 && !bonusSelectedCards[index]) {
      print('⚠️ Already selected 2 bonus cards, cannot select more');
      return;
    }
    
    // Don't allow selecting already drawn cards
    final cardName = TarotService.tarotDeck[index];
    print('🎯 Card name at index $index: $cardName');
    print('🎯 Drawn cards: $drawnCards');
    
    if (drawnCards!.contains(cardName)) {
      print('⚠️ Cannot select already drawn card: $cardName');
      return;
    }
    
    print('🎯 About to setState...');
    setState(() {
      if (bonusSelectedCards[index]) {
        // Deselect card
        print('🎯 Deselecting card: $cardName');
        bonusSelectedCards[index] = false;
        bonusSelectedIndices.remove(index);
      } else {
        // Select card
        print('🎯 Selecting card: $cardName');
        bonusSelectedCards[index] = true;
        bonusSelectedIndices.add(index);
      }
      
      print('📋 Bonus cards selected: ${bonusSelectedIndices.length}/2');
      print('📋 Selected indices: $bonusSelectedIndices');
    });
  }

  void confirmBonusSelection() {
    print('🎯 confirmBonusSelection called');
    print('🎯 bonusSelectedIndices.length: ${bonusSelectedIndices.length}');
    print('🎯 bonusSelectedIndices: $bonusSelectedIndices');
    
    if (bonusSelectedIndices.length != 2) {
      print('⚠️ Must select exactly 2 bonus cards');
      return;
    }
    
    print('🎯 About to set bonusCards...');
    setState(() {
      bonusCards = bonusSelectedIndices
          .map((index) => TarotService.tarotDeck[index])
          .toList();
      showingBonusSelection = false;
      
      print('✅ Bonus cards confirmed: $bonusCards');
    });
  }

  void cancelBonusSelection() {
    setState(() {
      showingBonusSelection = false;
      bonusSelectedCards = <bool>[];
      bonusSelectedIndices = <int>[];
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
              const SizedBox(height: 21),
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
              
              // Regular deck selection
              if (showingDeck) ...[
                DeckSelector(
                  selectedCards: selectedCards,
                  selectedIndices: selectedIndices,
                  onCardSelected: (index) => selectCard(index, 3),
                  maxCards: 3,
                  shuffledOrder: shuffledDeckOrder,
                ),
              ],

              // Rest of your existing code...
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
                      // OpenAI response display
                      const SelectableText('Réponse de OpenAI :', style: TextStyle(fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SelectableText(openAIAnswer!),
                      ),
                      
                      // BONUS BUTTON MUST BE HERE, INSIDE THE Column
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: (bonusCards == null && !isBonusLoading) ? drawBonusCards : null,
                        child: const Text('bonus +2 cartes conseil'),
                      ),
                      
                      // Bonus cards display (if any)
                      if (bonusCards != null) ...[
                        const SizedBox(height: 16),
                        const SelectableText(
                          'Cartes bonus tirées :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          children: bonusCards!.map((card) => Chip(label: Text(card))).toList(),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: isBonusLoading ? null : askBonusOpenAI,
                          child: const Text('demander à openAI (bonus)'),
                        ),
                      ],
                      
                    ],
                  ),
                // Custom OpenAI Response
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
                        'Réponse OpenAI personnalisée :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SelectableText(customOpenAIAnswer!),
                      ),
                      
                      // BONUS BUTTON
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: (bonusCards == null && !isBonusLoading && !showingBonusSelection)
                            ? showBonusCardSelection
                            : null,
                        child: const Text('bonus +2 cartes conseil'),
                      ),
                      
                      // BONUS DECK SELECTOR (IF SHOWING)
                      if (showingBonusSelection) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purple, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.purple[50],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Choisissez 2 cartes bonus (${2 - bonusSelectedIndices.length} restantes)',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cartes déjà tirées: ${drawnCards?.join(", ") ?? ""}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              
                              // Bonus cards deck grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                ),
                                itemCount: TarotService.tarotDeck.length,
                                itemBuilder: (context, index) {
                                  final cardName = TarotService.tarotDeck[index];
                                  final isAlreadyDrawn = drawnCards?.contains(cardName) ?? false;
                                  final isSelected = bonusSelectedCards[index];
                                  final isAvailable = !isAlreadyDrawn;
                                  
                                  return GestureDetector(
                                    onTap: isAvailable ? () => selectBonusCard(index) : null,
                                    child: Card(
                                      color: isAlreadyDrawn 
                                          ? Colors.grey[400] 
                                          : isSelected 
                                              ? Colors.green[200] 
                                              : Colors.grey[300],
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: isSelected 
                                              ? Border.all(color: Colors.green, width: 2)
                                              : isAlreadyDrawn
                                                  ? Border.all(color: Colors.red, width: 2)
                                                  : null,
                                        ),
                                        child: Center(
                                          child: isAlreadyDrawn
                                              ? Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.block, color: Colors.red, size: 16),
                                                    Text(
                                                      cardName,
                                                      style: const TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.red,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ],
                                                )
                                              : isSelected
                                                  ? Text(
                                                      cardName,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    )
                                                  : const Icon(
                                                      Icons.help_outline,
                                                      size: 24,
                                                      color: Colors.grey,
                                                    ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: cancelBonusSelection,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: bonusSelectedIndices.length == 2 
                                        ? confirmBonusSelection 
                                        : null,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: Text('Confirmer (${bonusSelectedIndices.length}/2)'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // BONUS CARDS DISPLAY (if any)
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
                      
                      // Add this right before the bonus OpenAI response
                      if (bonusPrompt != null) ...[
                        const SizedBox(height: 16),
                        const SelectableText(
                          'Prompt envoyé à OpenAI (bonus) :',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: SelectableText(
                            bonusPrompt!,
                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      ],

                      // BONUS OPENAI RESPONSE (if any)
                      if (isBonusLoading)
                        const CircularProgressIndicator()
                      else if (bonusOpenAIAnswer != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const SelectableText(
                              'Réponse bonus OpenAI :',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: SelectableText(bonusOpenAIAnswer!),
                            ),
                          ],
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