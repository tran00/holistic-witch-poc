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
    });
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

  Widget _pyramidLayout(List<String> cards) {
    // cards[0]=1, cards[1]=2, cards[2]=3, cards[3]=4, cards[4]=5, cards[5]=6
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sommet (Synthèse)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  cards[5],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        // Milieu (Futur proche et lointain)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  cards[3],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  cards[4],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        // Base (Passé, Présent, Obstacles)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  cards[0],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  cards[2],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  cards[1],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
              ElevatedButton(
                onPressed: drawCards,
                child: const Text('tirez vos cartes'),
              ),
              const SizedBox(height: 24),
              if (drawnCards != null) _pyramidLayout(drawnCards!),
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