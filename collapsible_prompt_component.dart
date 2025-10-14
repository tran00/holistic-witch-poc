// Collapsible Prompt Component for three_card_draw_page.dart
// Replace the section from line 395-402 with this code:

                        if (lastSystemPrompt != null) ...[
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ExpansionTile(
                              title: const Text(
                                'Voir le prompt envoyé à l\'IA',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              leading: const Icon(Icons.code, size: 20),
                              childrenPadding: const EdgeInsets.all(16),
                              children: [
                                SelectableText(
                                  lastSystemPrompt!,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

// This replaces the old prompt display:
//                        if (lastSystemPrompt != null) ...[
//                          const SelectableText('Prompt envoyé à l'IA :', style: TextStyle(fontWeight: FontWeight.bold)),
//                          Padding(
//                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                            child: SelectableText(lastSystemPrompt!),
//                          ),
//                          const SizedBox(height: 16),
//                        ],

// BENEFITS:
// ✅ Prompt is now collapsible - users can focus on the answer
// ✅ Clean UI with Card design and ExpansionTile
// ✅ Code icon to indicate technical content
// ✅ Monospace font for better readability of the prompt
// ✅ Compact initial view that can be expanded when needed

// You can also apply the same pattern to the bonus prompt section around line 570:
// Replace bonusRagQuery display with a similar ExpansionTile pattern