import 'package:flutter/material.dart';
import 'services/tarot_service.dart';
import 'three_card_rag_helper.dart';
import 'mixins/tarot_page_mixin.dart';
import 'widgets/app_drawer.dart';
import 'rag_service_singleton.dart';
import 'services/prompt_service.dart';
// import 'widgets/reveal_tarot_card.dart'; // Add this if missing

// ...existing code...
  class ThreeCardDrawPage extends StatefulWidget {
    const ThreeCardDrawPage({super.key});

    @override
    State<ThreeCardDrawPage> createState() => _ThreeCardDrawPageState();
  }

  class _ThreeCardDrawPageState extends State<ThreeCardDrawPage> with TarotPageMixin {
  // --- OpenAI custom button logic ---
  Future<void> askOpenAICustom() async {
    if (drawnCards == null || drawnCards!.length != 3) return;
    if (!mounted) return;
    final question = questionController.text.trim();
    if (question.isEmpty) return;
    setState(() {
      isLoading = true;
      ragAnswer = null;
      ragContext = null;
      lastSystemPrompt = null;
    });
    try {
      final prompt = PromptService.buildThreeCardCustomPrompt(question, drawnCards!);
      // Direct OpenAI chat completion, no RAG, no Pinecone
      final answer = await _askOpenAIWithPromptOnly(question, prompt);
      if (mounted) {
        setState(() {
          ragAnswer = answer;
          ragContext = null;
          lastSystemPrompt = prompt;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          ragAnswer = 'Erreur : $e';
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

  Future<String> _askOpenAIWithPromptOnly(String question, String systemPrompt) async {
    // This uses the same logic as generateContextualResponse in RagService, but with no context
    return await ragService.generateContextualResponse(question, '', systemPrompt: systemPrompt);
  }
  // Store selected card indices for deck selection (avoid mixin conflict)
  List<int> deckSelectedIndices = [];

  void deckSelectCard(int index) {
    setState(() {
      if (deckSelectedIndices.contains(index)) {
        deckSelectedIndices.remove(index);
      } else if (deckSelectedIndices.length < 3) {
        deckSelectedIndices.add(index);
      }
    });
  }

  void deckConfirmSelection() {
    setState(() {
      drawnCards = deckSelectedIndices.map((i) => TarotService.tarotDeck[i]).toList();
      showingDeck = false;
      deckSelectedIndices.clear();
    });
  }
  // Store the last system prompt sent to RAG
  String? lastSystemPrompt;
    // --- STATE ---
    String? ragAnswer;
    String? ragContext;
    bool isLoading = false;
    bool showingBonusSelection = false;
    List<bool> bonusSelectedCards = <bool>[];
    List<int> bonusSelectedIndices = <int>[];
    List<String>? bonusCards;
    String? bonusRagAnswer;
    String? bonusRagContext;
    bool isBonusLoading = false;

    @override
    void initState() {
      super.initState();
      initializeServices();
    }

    @override
    void initializeServices() {
      super.initializeServices();
    }

    void showBonusCardSelection() {
      if (TarotService.tarotDeck.isEmpty) return;
      setState(() {
        showingBonusSelection = true;
        // Mark all cards as not selected for bonus, but visually disable the 3 drawn cards
        bonusSelectedCards = List.filled(TarotService.tarotDeck.length, false);
        bonusSelectedIndices = <int>[];
      });
    }

    void selectBonusCard(int index) {
      if (bonusSelectedIndices.length >= 2 && !bonusSelectedCards[index]) return;
      if (drawnCards != null && drawnCards!.contains(TarotService.tarotDeck[index])) return;
      setState(() {
        if (bonusSelectedCards[index]) {
          bonusSelectedCards[index] = false;
          bonusSelectedIndices.remove(index);
        } else {
          bonusSelectedCards[index] = true;
          bonusSelectedIndices.add(index);
        }
      });
    }

    void cancelBonusSelection() {
      setState(() {
        showingBonusSelection = false;
        bonusSelectedCards = <bool>[];
        bonusSelectedIndices = <int>[];
      });
    }

    void confirmBonusSelection() {
      if (bonusSelectedIndices.length != 2) return;
      setState(() {
        showingBonusSelection = false;
        bonusCards = bonusSelectedIndices.map((i) => TarotService.tarotDeck[i]).toList();
        bonusRagAnswer = null;
        bonusRagContext = null;
      });
    }

    Future<void> askRag() async {
      if (drawnCards == null || drawnCards!.length != 3) return;
      if (!mounted) return;
      final userQuestion = questionController.text.trim();
      if (userQuestion.isEmpty) return;
      setState(() {
        isLoading = true;
        ragAnswer = null;
        ragContext = null;
        lastSystemPrompt = null;
      });
      try {
        // System prompt: mention the three cards and their roles, but no detailed meanings
        final systemPrompt = "Tu es un expert du tarot. Voici un tirage de 3 cartes :\n"
          "- 1ère carte (aspects positifs) : ${drawnCards![0]}\n"
          "- 2ème carte (obstacles/défis) : ${drawnCards![1]}\n"
          "- 3ème carte (conseils) : ${drawnCards![2]}\n"
          "Réponds à la question de l'utilisateur en t'appuyant uniquement sur le contexte fourni et sur le rôle de chaque carte.";
        // Enrich the vector search query with the system prompt and user question
        final enrichedQuery = systemPrompt + "\n\nQuestion de l'utilisateur : " + userQuestion;
        // Debug: print the query and prompt
        // ignore: avoid_print
        print('RAG QUERY DEBUG: question = "${enrichedQuery}"');
        // ignore: avoid_print
        print('RAG QUERY DEBUG: systemPrompt = "${systemPrompt}"');
        // Pass the enriched query as the question for vector search
        final result = await ThreeCardRagHelper.askRagForThreeCards(
          question: enrichedQuery,
          drawnCards: drawnCards!,
        );
        if (mounted) {
          setState(() {
            ragAnswer = result['answer'] as String?;
            ragContext = result['context_used'] as String?;
            lastSystemPrompt = systemPrompt;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            ragAnswer = 'Erreur : $e';
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

    Future<void> askBonusRag() async {
      if (drawnCards == null || drawnCards!.length != 3 || bonusCards == null || bonusCards!.length != 2) return;
      if (!mounted) return;
      final question = questionController.text.trim();
      if (question.isEmpty) return;
      setState(() {
        isBonusLoading = true;
        bonusRagAnswer = null;
        bonusRagContext = null;
      });
      try {
        final systemPrompt = '''
  Tu es un expert du tarot. Voici un tirage de 5 cartes :
  - 1ère carte (aspects positifs) : ${drawnCards![0]}
  - 2ème carte (obstacles/défis) : ${drawnCards![1]}
  - 3ème carte (conseils) : ${drawnCards![2]}
  - 4ème carte (bonus) : ${bonusCards![0]}
  - 5ème carte (bonus) : ${bonusCards![1]}

  Réponds à la question de l'utilisateur en expliquant le rôle de chaque carte dans le contexte de la question, puis donne une synthèse/conseil global.
  ''';
        final result = await ragService.askQuestion(
          question,
          systemPrompt: systemPrompt,
        );
        if (mounted) {
          setState(() {
            bonusRagAnswer = result['answer'] as String?;
            bonusRagContext = result['context_used'] as String?;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            bonusRagAnswer = 'Erreur : $e';
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
                // ...existing code...
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
                Center(
                  child: ElevatedButton(
                    onPressed: showDeck,
                    child: const Text('choisir mes cartes'),
                  ),
                ),
                const SizedBox(height: 24),
                if (showingDeck) ...[
                  const SizedBox(height: 16),
                  Text('Sélectionnez 3 cartes dans le deck :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      TarotService.tarotDeck.length,
                      (index) {
                        final isSelected = deckSelectedIndices.contains(index);
                        return GestureDetector(
                          onTap: () {
                            deckSelectCard(index);
                          },
                          child: Container(
                            width: 60,
                            height: 90,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blueAccent.withOpacity(0.7) : Colors.grey[300],
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: isSelected
                                  ? Text(
                                      TarotService.tarotDeck[index],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: deckSelectedIndices.length == 3 ? deckConfirmSelection : null,
                    child: const Text('Valider la sélection'),
                  ),
                ],
                if (showingBonusSelection)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Text('Sélectionnez 2 cartes bonus dans le deck :', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          TarotService.tarotDeck.length,
                          (index) {
                            final isSelected = bonusSelectedCards[index];
                            final isDrawn = drawnCards != null && drawnCards!.contains(TarotService.tarotDeck[index]);
                            return GestureDetector(
                              onTap: isDrawn ? null : () { selectBonusCard(index); },
                              child: Opacity(
                                opacity: isDrawn ? 0.4 : 1.0,
                                child: Container(
                                  width: 60,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: isDrawn
                                        ? Colors.blueGrey.withOpacity(0.7)
                                        : (isSelected ? Colors.orangeAccent.withOpacity(0.7) : Colors.grey[300]),
                                    border: Border.all(
                                      color: isDrawn
                                          ? Colors.blueGrey
                                          : (isSelected ? Colors.orange : Colors.black26),
                                      width: isSelected || isDrawn ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: isDrawn
                                        ? Icon(Icons.check, color: Colors.white, size: 20)
                                        : (isSelected
                                            ? Text(
                                                TarotService.tarotDeck[index],
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: bonusSelectedIndices.length == 2 ? confirmBonusSelection : null,
                            child: const Text('Valider les bonus'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: cancelBonusSelection,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: const Text('Annuler'),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (drawnCards != null && !showingDeck)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => RevealTarotCard(
                        revealed: true,
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
                        onPressed: isLoading ? null : askOpenAICustom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('OpenAI custom'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : askRag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Réponse IA (RAG)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (isLoading)
                    const CircularProgressIndicator(),
                  if (ragAnswer != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lastSystemPrompt != null) ...[
                          const SelectableText('Prompt envoyé à l’IA :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: SelectableText(lastSystemPrompt!),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SelectableText('Réponse IA :', style: TextStyle(fontWeight: FontWeight.bold)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: SelectableText(ragAnswer!),
                        ),
                        if (ragContext != null && ragContext!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const SelectableText('Contexte utilisé :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: SelectableText(ragContext!),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Ajouter 2 cartes bonus'),
                              onPressed: isBonusLoading ? null : showBonusCardSelection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
                if (drawnCards != null)...[
                  const SizedBox(height: 60),
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
                ],
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