// lib/services/tarot_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class TarotService {
  static const List<String> _tarotDeck = [
    'LE JUGEMENT',           // 0
    'LA JUSTICE',            // 1
    'LE PENDU',              // 2
    'LA MORT (L\'ARCANE SANS NOM)', // 3
    'LA TEMPÉRANCE',         // 4
    'LE DIABLE',             // 5
    'LA MAISON DIEU',        // 6
    'L\'ÉTOILE',             // 7
    'LA LUNE',               // 8
    'LE SOLEIL',             // 9
    'LE MONDE',              // 10
    'LA FORCE',              // 11
    'L\'HERMITE',            // 12
    'LA ROUE DE FORTUNE',    // 13
    'LA PAPESSE',            // 14
    'L\'IMPÉRATRICE',        // 15
    'L\'EMPEREUR',           // 16
    'LE PAPE',               // 17
    'L\'AMOUREUX',           // 18
    'LE CHARIOT',            // 19
    'LE BATELEUR',           // 20
    'LE MAT',                // 21
  ];

  static const Map<String, String> _cardToJsonKey = {
    'LE JUGEMENT': '0',
    'LA JUSTICE': '1',
    'LE PENDU': '2',
    'LA MORT (L\'ARCANE SANS NOM)': '3',
    'LA TEMPÉRANCE': '4',
    'LE DIABLE': '5',
    'LA MAISON DIEU': '6',
    'L\'ÉTOILE': '7',
    'LA LUNE': '8',
    'LE SOLEIL': '9',
    'LE MONDE': '10',
    'LA FORCE': '11',
    'L\'HERMITE': '12',
    'LA ROUE DE FORTUNE': '13',
    'LA PAPESSE': '14',
    'L\'IMPÉRATRICE': '15',
    'L\'EMPEREUR': '16',
    'LE PAPE': '17',
    'L\'AMOUREUX': '18',
    'LE CHARIOT': '19',
    'LE BATELEUR': '20',
    'LE MAT': '21',
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
}