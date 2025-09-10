import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart';
import 'widgets/app_drawer.dart';

class FourCardDrawPage extends StatefulWidget {
  const FourCardDrawPage({super.key});

  @override
  State<FourCardDrawPage> createState() => _FourCardDrawPageState();
}

class _FourCardDrawPageState extends State<FourCardDrawPage> {
  static const List<String> tarotDeck = [
    'Le Mat', 'Le Bateleur', 'La Papesse', 'L’Impératrice', 'L’Empereur',
    'Le Pape', 'L’Amoureux', 'Le Chariot', 'La Justice', 'L’Hermite',
    'La Roue de Fortune', 'La Force', 'Le Pendu', 'L’Arcane sans nom',
    'Tempérance', 'Le Diable', 'La Maison Dieu', 'L’Étoile', 'La Lune',
    'Le Soleil', 'Le Jugement', 'Le Monde'
  ];

  final TextEditingController _questionController = TextEditingController();
  List<String>? drawnCards;
  List<String>? bonusCards;
  String? openAIAnswer;
  String? prompt;
  String? bonusPrompt;
  String? bonusOpenAIAnswer;
  bool isLoading = false;
  bool isBonusLoading = false;
  late final OpenAIClient _openAI;
  int revealedCards = 0;

  List<bool> selectedCards = [];
  List<int> selectedIndices = [];
  bool showingDeck = false;

  @override
  void initState() {
    super.initState();
    _openAI = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void drawCards() {
    final deck = List<String>.from(tarotDeck);
    deck.shuffle(Random());
    setState(() {
      drawnCards = deck.take(4).toList();
      bonusCards = null;
      openAIAnswer = null;
      prompt = null;
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
      revealedCards = 0;
      selectedCards = List<bool>.filled(4, false);
      selectedIndices = [];
      showingDeck = false;
    });
    revealCardsOneByOne();
  }

  void drawBonusCards() {
    if (drawnCards == null) return;
    final deck = List<String>.from(tarotDeck);
    // Remove already drawn cards
    deck.removeWhere((card) => drawnCards!.contains(card));
    deck.shuffle(Random());
    setState(() {
      bonusCards = deck.take(1).toList();
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
    });
  }

  Future<void> askOpenAI() async {
    if (drawnCards == null || drawnCards!.length != 4) return;
    if (!mounted) return;
    final question = _questionController.text.trim();
    final cards = drawnCards!.join(', ');
    final builtPrompt =
        "En tant qu'expert du tarot, interprète ce tirage de quatre cartes pour répondre à la question suivante : \"$question\". "
        "Le tirage est prédictif et doit décrire le déroulé des événements dans le temps : "
        "la première carte représente le passé, la deuxième le présent, la troisième l’évolution probable, la quatrième l’issue ou le conseil. "
        "Pour chaque carte ($cards), donne son sens dans la position correspondante et propose une synthèse sur le déroulé prévisible.";
    setState(() {
      isLoading = true;
      prompt = builtPrompt;
      openAIAnswer = null;
    });
    try {
      final answer = await _openAI.sendMessage(builtPrompt);
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

  Future<void> askBonusOpenAI() async {
    if (drawnCards == null || bonusCards == null) return;
    if (!mounted) return;
    final question = _questionController.text.trim();
    final allCards = [...drawnCards!, ...bonusCards!].join(', ');
    final builtPrompt =
        "En tant qu'expert du tarot, complète et approfondis le conseil à la question suivante : \"$question\" en prenant en compte maintenant un tirage de cinq cartes : $allCards. Explique le sens des deux nouvelles cartes et donne une synthèse enrichie.";
    setState(() {
      isBonusLoading = true;
      bonusPrompt = builtPrompt;
      bonusOpenAIAnswer = null;
    });
    try {
      final answer = await _openAI.sendMessage(builtPrompt);
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

  void revealCardsOneByOne() async {
    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        revealedCards = i;
      });
    }
  }

  void toggleCardSelection(int index) {
    setState(() {
      selectedCards[index] = !selectedCards[index];
      if (selectedCards[index]) {
        selectedIndices.add(index);
      } else {
        selectedIndices.remove(index);
      }
    });
  }

  void toggleDeckVisibility() {
    setState(() {
      showingDeck = !showingDeck;
    });
  }

  void showDeck() {
    setState(() {
      selectedCards = List.filled(tarotDeck.length, false);
      selectedIndices.clear();
      drawnCards = null;
      showingDeck = true;
    });
  }

  void selectCard(int index) {
    if (selectedIndices.length >= 4) return; // 4 cards for this page

    setState(() {
      selectedCards[index] = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 4) { // When 4 cards are selected
      // User has selected 4 cards - add delay before switching views
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          drawnCards = selectedIndices.map((i) => tarotDeck[i]).toList();
          showingDeck = false;
          revealedCards = 0;
        });
        revealCardsOneByOne();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const SelectableText('Tirage 4 cartes prédictif')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 21),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Quel conseil demander ?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Two buttons: automatic and manual selection
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
                Text(
                  'Choisissez 4 cartes (${4 - selectedIndices.length} restantes)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: tarotDeck.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => selectedCards[index] ? null : selectCard(index),
                      child: Card(
                        color: selectedCards[index] 
                            ? Colors.blue[100] 
                            : Colors.grey[300],
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: selectedCards[index] 
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: selectedCards[index]
                                ? Text(
                                    tarotDeck[index],
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
              ],

              // Show selected cards in the existing Stack layout
              if (drawnCards != null && !showingDeck)
                SizedBox(
                  width: 600, // much wider container
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Card 1 (left)
                      Positioned(
                        top: 60,
                        left: 40, // more space from the left
                        child: AnimatedOpacity(
                          opacity: (revealedCards > 0) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 160,
                                height: 48,
                                child: Center(
                                  child: SelectableText(
                                    drawnCards![0],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Card 2 (right)
                      Positioned(
                        top: 60,
                        right: 40, // more space from the right
                        child: AnimatedOpacity(
                          opacity: (revealedCards > 1) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 160,
                                height: 48,
                                child: Center(
                                  child: SelectableText(
                                    drawnCards![1],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Card 3 (center top)
                      Positioned(
                        top: 0,
                        left: 220, // center with new width
                        child: AnimatedOpacity(
                          opacity: (revealedCards > 2) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 160,
                                height: 48,
                                child: Center(
                                  child: SelectableText(
                                    drawnCards![2],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Card 4 (center bottom)
                      Positioned(
                        bottom: 0,
                        left: 220, // center with new width
                        child: AnimatedOpacity(
                          opacity: (revealedCards > 3) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 160,
                                height: 48,
                                child: Center(
                                  child: SelectableText(
                                    drawnCards![3],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (drawnCards != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : askOpenAI,
                  child: const Text('demander à openAI'),
                ),
                if (prompt != null) ...[
                  const SizedBox(height: 32),
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
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: (bonusCards == null && !isBonusLoading)
                            ? drawBonusCards
                            : null,
                        child: const Text('bonus +1 cartes conseil'),
                      ),
                      if (bonusCards != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: bonusCards!
                              .map((card) => Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    color: Colors.amber[100],
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SelectableText(
                                        card,
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isBonusLoading ? null : askBonusOpenAI,
                          child: const Text('demander à openAI (bonus)'),
                        ),
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
                              color: Colors.amber[100],
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
                    ],
                  ),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    drawnCards = null;
                    openAIAnswer = null;
                    prompt = null;
                    isLoading = false;
                    _questionController.clear();
                  });
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