import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart';
import 'widgets/app_drawer.dart';

class ThreeCardDrawPage extends StatefulWidget {
  const ThreeCardDrawPage({super.key});

  @override
  State<ThreeCardDrawPage> createState() => _ThreeCardDrawPageState();
}

class _ThreeCardDrawPageState extends State<ThreeCardDrawPage> {
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
      drawnCards = deck.take(3).toList();
      bonusCards = null;
      openAIAnswer = null;
      prompt = null;
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
      revealedCards = 0;
    });
    revealCardsOneByOne();
  }

  void revealCardsOneByOne() async {
    for (int i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        revealedCards = i;
      });
    }
  }

  void drawBonusCards() {
    if (drawnCards == null) return;
    final deck = List<String>.from(tarotDeck);
    // Remove already drawn cards
    deck.removeWhere((card) => drawnCards!.contains(card));
    deck.shuffle(Random());
    setState(() {
      bonusCards = deck.take(2).toList();
      bonusPrompt = null;
      bonusOpenAIAnswer = null;
    });
  }

  Future<void> askOpenAI() async {
    if (drawnCards == null || drawnCards!.length != 3) return;
    if (!mounted) return;
    final question = _questionController.text.trim();
    final cards = drawnCards!.join(', ');
    final builtPrompt =
        "En tant qu'expert du tarot, donne un conseil détaillé à la question suivante : \"$question\" en t'appuyant sur un tirage de trois cartes : $cards. Explique le sens de chaque carte dans le contexte de la question et donne une synthèse.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const SelectableText('Tirage 3 cartes conseil')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 21), // for top space (adjust as needed)
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Quel conseil demander ?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: drawCards,
                child: const Text('tirez vos cartes'),
              ),
              const SizedBox(height: 24),
              if (drawnCards != null)
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
                ElevatedButton(
                  onPressed: isLoading ? null : askOpenAI,
                  child: const Text('demander à openAI'),
                ),
                if (prompt != null) ...[
                  const SizedBox(height: 32), // <-- 32px margin before prompt label
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
                        child: const Text('bonus +2 cartes conseil'),
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
                          const SizedBox(height: 32), // <-- 32px margin before bonus prompt label
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
              if (drawnCards != null)
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
                      bonusCards = null;
                      openAIAnswer = null;
                      prompt = null;
                      bonusPrompt = null;
                      bonusOpenAIAnswer = null;
                      isLoading = false;
                      isBonusLoading = false;
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

class RevealTarotCard extends StatelessWidget {
  final bool revealed;
  final String cardName;
  const RevealTarotCard({super.key, required this.revealed, required this.cardName});

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