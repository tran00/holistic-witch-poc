// lib/services/tarot_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class TarotService {
  static const List<String> _tarotDeck = [
    'LE MAT',                    // 0
    'LE BATELEUR',               // 1
    'LA PAPESSE',                // 2
    'L\'IMPÉRATRICE',            // 3
    'L\'EMPEREUR',               // 4
    'LE PAPE',                   // 5
    'L\'AMOUREUX',               // 6
    'LE CHARIOT',                // 7
    'LA FORCE',                  // 8
    'L\'HERMITE',                // 9
    'LA ROUE DE FORTUNE',        // 10
    'LA JUSTICE',                // 11
    'LE PENDU',                  // 12
    'LA MORT (L\'ARCANE SANS NOM)', // 13
    'LA TEMPÉRANCE',             // 14
    'LE DIABLE',                 // 15
    'LA MAISON DIEU',            // 16
    'L\'ÉTOILE',                 // 17
    'LA LUNE',                   // 18
    'LE SOLEIL',                 // 19
    'LE JUGEMENT',               // 20
    'LE MONDE',                  // 21 (add if missing)
  ];

  static const Map<String, String> _cardToJsonKey = {
    'LE MAT': '0',                          // JSON key "0" is "LE MAT (ou Le Fou)"
    'LE BATELEUR': '1',                     // JSON key "1" is "LE BATELEUR (ou Le Magicien)"
    'LA PAPESSE': '2',                      // JSON key "2" is "LA PAPESSE (ou La Grande Prêtresse)"
    'L\'IMPÉRATRICE': '3',                  // JSON key "3" is "L'IMPÉRATRICE"
    'L\'EMPEREUR': '4',                     // JSON key "4" is "L'EMPEREUR"
    'LE PAPE': '5',                         // JSON key "5" is "LE PAPE"
    'L\'AMOUREUX': '6',                     // JSON key "6" is "L'AMOUREUX"
    'LE CHARIOT': '7',                      // JSON key "7" is "LE CHARIOT"
    'LA FORCE': '8',                        // JSON key "8" is "LA FORCE"
    'L\'HERMITE': '9',                      // JSON key "9" is "L'ERMITE"
    'LA ROUE DE FORTUNE': '10',             // JSON key "10" is "LA ROUE DE FORTUNE"
    'LA JUSTICE': '11',                     // JSON key "11" is "LA JUSTICE"
    'LE PENDU': '12',                       // JSON key "12" is "LE PENDU"
    'LA MORT (L\'ARCANE SANS NOM)': '13',   // JSON key "13" is "LA MORT (L'ARCANE SANS NOM)"
    'LA TEMPÉRANCE': '14',                  // JSON key "14" is "LA TEMPÉRANCE"
    'LE DIABLE': '15',                      // JSON key "15" is "LE DIABLE"
    'LA MAISON DIEU': '16',                 // JSON key "16" is "LA MAISON DIEU"
    'L\'ÉTOILE': '17',                      // JSON key "17" is "L'ÉTOILE"
    'LA LUNE': '18',                        // JSON key "18" is "LA LUNE"
    'LE SOLEIL': '19',                      // JSON key "19" is "LE SOLEIL"
    'LE JUGEMENT': '20',                    // JSON key "20" is "LE JUGEMENT"
    'LE MONDE': '21',                       // Add this if missing
  };

  static Map<String, dynamic>? _tarotMeanings;

  static List<String> get tarotDeck => _tarotDeck;
  static Map<String, String> get cardToJsonKey => _cardToJsonKey;

  static Future<void> loadTarotMeanings() async {
    if (_tarotMeanings != null) return;
    
    try {
      print('🔄 Loading tarot meanings...');
      final String jsonString = await rootBundle.loadString('assets/tarot.json');
      print('✅ JSON string loaded, length: ${jsonString.length}');
      
      if (jsonString.isEmpty) {
        print('❌ JSON string is empty!');
        _tarotMeanings = {};
        return;
      }
      
      _tarotMeanings = json.decode(jsonString);
      print('✅ JSON decoded successfully');
      print('✅ Tarot meanings loaded: ${_tarotMeanings?.keys.length} cards');
    } catch (e, stackTrace) {
      print('💥 Error loading tarot meanings: $e');
      print('💥 Stack trace: $stackTrace');
      _tarotMeanings = {};
    }
  }

  static List<String> drawCards(int count) {
    final deck = List<String>.from(_tarotDeck);
    deck.shuffle(Random());
    return deck.take(count).toList();
  }

  static List<String> drawBonusCards(List<String> alreadyDrawn, int count) {
    final deck = List<String>.from(_tarotDeck);
    deck.removeWhere((card) => alreadyDrawn.contains(card));
    deck.shuffle(Random());
    return deck.take(count).toList();
  }

  static Map<String, dynamic>? getCardData(String cardName) {
    if (_tarotMeanings == null || !_cardToJsonKey.containsKey(cardName)) {
      return null;
    }
    
    final jsonKey = _cardToJsonKey[cardName]!;
    return _tarotMeanings![jsonKey];
  }

  static String? getCardMeaning(String cardName) {
    if (_tarotMeanings == null || _tarotMeanings!.isEmpty) {
      print('⚠️ Tarot meanings not loaded yet');
      return null;
    }
    
    // Find the JSON key for this card name
    final jsonKey = _cardToJsonKey[cardName];
    if (jsonKey == null) {
      print('⚠️ No JSON key found for card: $cardName');
      return null;
    }
    
    // Get the card data from the JSON
    final cardData = _tarotMeanings![jsonKey];
    if (cardData == null) {
      print('⚠️ No card data found for key: $jsonKey');
      return null;
    }
    
    // Extract the advice section for the prompt
    if (cardData['meanings'] != null && cardData['meanings']['advice'] != null) {
      final advice = cardData['meanings']['advice'];
      
      // Build a comprehensive meaning string
      String meaning = '';
      
      // Add description if available
      if (cardData['description'] != null) {
        meaning += '${cardData['description']}\n\n';
      }
      
      // Add advice interpretation
      if (advice['interpretation'] != null) {
        meaning += 'Conseil: ${advice['interpretation']}';
      }
      
      // Add practical advice if available
      if (advice['practical'] != null) {
        meaning += '\nPratique: ${advice['practical']}';
      }
      
      return meaning.trim();
    }
    
    print('⚠️ No advice found for card: $cardName');
    return null;
  }
}