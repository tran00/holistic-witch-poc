import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart';
import 'widgets/app_drawer.dart';

class SixCardDrawPage extends StatefulWidget {
  const SixCardDrawPage({super.key});

  @override
  State<SixCardDrawPage> createState() => _SixCardDrawPageState();
}

class _SixCardDrawPageState extends State<SixCardDrawPage> {
  static const List<String> tarotDeck = [
    'Le Mat', 'Le Bateleur', 'La Papesse', 'L’Impératrice', 'L’Empereur',
    'Le Pape', 'L’Amoureux', 'Le Chariot', 'La Justice', 'L’Hermite',
    'La Roue de Fortune', 'La Force', 'Le Pendu', 'L’Arcane sans nom',
    'Tempérance', 'Le Diable', 'La Maison Dieu', 'L’Étoile', 'La Lune',
    'Le Soleil', 'Le Jugement', 'Le Monde'
  ];

  final TextEditingController _questionController = TextEditingController();
  List<String>? drawnCards;
  String? openAIAnswer;
  String? prompt;
  bool isLoading = false;
  late final OpenAIClient _openAI;

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
      drawnCards = deck.take(6).toList();
      openAIAnswer = null;
      prompt = null;
      revealedCards = 0; // <-- reset revealed cards
      selectedCards = List<bool>.filled(6, false);
      selectedIndices = [];
      showingDeck = false;
    });
    revealCardsOneByOne(); // <-- start reveal animation
  }

  void revealCardsOneByOne() async {
    for (int i = 1; i <= 6; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        revealedCards = i;
      });
    }
  }

  Future<void> askOpenAI() async {
    if (drawnCards == null || drawnCards!.length != 6) return;
    if (!mounted) return;
    final question = _questionController.text.trim();
    final cards = drawnCards!.join(', ');
    final builtPrompt =
        "En tant qu'expert du tarot, interprète ce tirage de six cartes en pyramide pour répondre à la question suivante : \"$question\". "
        "Voici la signification des positions : "
        "1 = passé, 2 = obstacles ou influences, 3 = présent, 4 = évolution proche (futur proche), 5 = évolution lointaine (futur lointain), 6 = synthèse/conclusion. "
        "Décris le rôle de chaque carte dans sa position et propose une synthèse globale du tirage. Les cartes tirées sont : $cards.";
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

  int revealedCards = 0;

  Widget _pyramidLayout(List<String> cards) {
    // cards[0]=1, cards[1]=2, cards[2]=3, cards[3]=4, cards[4]=5, cards[5]=6
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sommet (Synthèse)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: (revealedCards > 5) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    cards[5],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Milieu (Futur proche et lointain)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: (revealedCards > 3) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    cards[3],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: (revealedCards > 4) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    cards[4],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Base (Passé, Présent, Obstacles)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: (revealedCards > 0) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    cards[0],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: (revealedCards > 2) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    cards[2],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: (revealedCards > 1) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    cards[1],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
    if (selectedIndices.length >= 6) return;

    setState(() {
      selectedCards[index] = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 6) {
      // User has selected 6 cards - add delay before switching views
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
      appBar: AppBar(title: const Text('Tirage 6 cartes pyramide')),
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
                  'Choisissez 6 cartes (${6 - selectedIndices.length} restantes)',
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

              // Show selected cards in pyramid layout
              if (drawnCards != null && !showingDeck) _pyramidLayout(drawnCards!),
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
                    ],
                  ),
              ],
              const SizedBox(height: 24),
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