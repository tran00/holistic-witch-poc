// READMORE IMPLEMENTATION GUIDE
// File: lib/three_card_draw_page.dart

// STEP 1: Add the import at the top (after other imports)
/*
import 'package:readmore/readmore.dart';
*/

// STEP 2: Find this code (around line 395-402):
/*
                        if (lastSystemPrompt != null) ...[
                          const SelectableText('Prompt envoyé à l'IA :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: SelectableText(lastSystemPrompt!),
                          ),
                          const SizedBox(height: 16),
                        ],
*/

// STEP 3: Replace with this ReadMoreText implementation:
/*
                        if (lastSystemPrompt != null) ...[
                          const SelectableText('Prompt envoyé à l'IA :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: ReadMoreText(
                              lastSystemPrompt!,
                              trimLines: 3,
                              colorClickableText: Colors.blue,
                              trimMode: TrimMode.Line,
                              trimCollapsedText: 'Voir plus',
                              trimExpandedText: 'Voir moins',
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
*/

// STEP 4: OPTIONAL - Also update the bonus prompt section (around line 570):
// Find:
/*
                        if (bonusRagQuery != null && bonusRagQuery!.isNotEmpty) ...[
                          const SelectableText('Prompt envoyé à la recherche (bonus) :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: SelectableText(bonusRagQuery!),
                          ),
                          const SizedBox(height: 16),
                        ],
*/

// Replace with:
/*
                        if (bonusRagQuery != null && bonusRagQuery!.isNotEmpty) ...[
                          const SelectableText('Prompt envoyé à la recherche (bonus) :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: ReadMoreText(
                              bonusRagQuery!,
                              trimLines: 3,
                              colorClickableText: Colors.blue,
                              trimMode: TrimMode.Line,
                              trimCollapsedText: 'Voir plus',
                              trimExpandedText: 'Voir moins',
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
*/

// FEATURES:
// ✅ Shows only 3 lines of prompt by default
// ✅ "Voir plus" / "Voir moins" toggle links in French
// ✅ Blue clickable text for expand/collapse
// ✅ Monospace font for technical readability
// ✅ Much simpler than ExpansionTile
// ✅ Smooth animation
// ✅ Better user experience - focuses on AI responses

// BENEFITS:
// 🎯 Clean, minimal interface
// 📱 Mobile-friendly collapsible text
// 🇫🇷 French UI labels
// 🎨 Consistent with your app design
// ⚡ Lightweight and performant