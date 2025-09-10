// models/tarot_card.dart
class TarotCard {
  final String name;
  final String jsonKey;
  final Map<String, dynamic>? meanings;

  TarotCard({
    required this.name,
    required this.jsonKey,
    this.meanings,
  });

  factory TarotCard.fromJson(String name, String jsonKey, Map<String, dynamic> json) {
    return TarotCard(
      name: name,
      jsonKey: jsonKey,
      meanings: json,
    );
  }

  String getKeywords(String type) {
    return meanings?['meanings']?[type]?['keywords']?.join(', ') ?? '';
  }

  String getInterpretation(String type) {
    return meanings?['meanings']?[type]?['interpretation'] ?? '';
  }

  String getPredictive(String type) {
    return meanings?['meanings']?[type]?['predictive'] ?? '';
  }

  String getPractical() {
    return meanings?['meanings']?['advice']?['practical'] ?? '';
  }

  String getDescription() {
    return meanings?['description'] ?? '';
  }
}