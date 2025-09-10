// lib/widgets/deck_selector.dart
import 'package:flutter/material.dart';
import '../services/tarot_service.dart';

class DeckSelector extends StatelessWidget {
  final List<bool> selectedCards;
  final List<int> selectedIndices;
  final Function(int) onCardSelected;
  final int maxCards;
  final List<int> shuffledOrder;

  const DeckSelector({
    super.key,
    required this.selectedCards,
    required this.selectedIndices,
    required this.onCardSelected,
    required this.maxCards,
    required this.shuffledOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Choisissez $maxCards cartes (${maxCards - selectedIndices.length} restantes)',
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
          itemCount: TarotService.tarotDeck.length,
          itemBuilder: (context, index) {
            // Use shuffled order if available, otherwise use normal order
            final actualIndex = shuffledOrder.isNotEmpty && index < shuffledOrder.length 
                ? shuffledOrder[index] 
                : index;
            
            // Safety check
            if (actualIndex >= TarotService.tarotDeck.length || 
                actualIndex >= selectedCards.length) {
              return const SizedBox.shrink();
            }
            
            return GestureDetector(
              onTap: () => selectedCards[actualIndex] ? null : onCardSelected(actualIndex),
              child: Card(
                color: selectedCards[actualIndex] ? Colors.blue[100] : Colors.grey[300],
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: selectedCards[actualIndex] 
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: selectedCards[actualIndex]
                        ? Text(
                            TarotService.tarotDeck[actualIndex],
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
    );
  }
}