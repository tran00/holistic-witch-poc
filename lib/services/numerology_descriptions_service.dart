// lib/services/numerology_descriptions_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';

class NumerologyDescriptionsService {
  static Map<String, dynamic>? _descriptions;

  /// Load numerology descriptions from assets
  static Future<void> loadDescriptions() async {
    if (_descriptions != null) return; // Already loaded

    try {
      final String jsonString = await rootBundle.loadString('assets/numerologie.json');
      _descriptions = json.decode(jsonString);
      print('✅ Numerology descriptions loaded successfully');
    } catch (e) {
      print('❌ Error loading numerologie.json: $e');
      _descriptions = {};
    }
  }

  /// Get description for a specific number
  static Map<String, String>? getDescription(int number) {
    if (_descriptions == null) return null;
    
    final numberData = _descriptions![number.toString()];
    if (numberData == null) return null;

    return {
      'quotidien': numberData['quotidien'] ?? '',
      'figure': numberData['Figure'] ?? '',
      'symbole': numberData['Symbole'] ?? '',
    };
  }

  /// Get enhanced prompt with number description
  static String getEnhancedPrompt(
    int number,
    String basePrompt,
    String numberType, // e.g., "chemin de vie", "expression", etc.
  ) {
    final description = getDescription(number);
    if (description == null || _descriptions == null) {
      print('⚠️ No description found for number $number, using base prompt');
      return basePrompt;
    }

    String enhancedPrompt = basePrompt;

    // Add detailed descriptions if available
    if (description['quotidien']!.isNotEmpty) {
      enhancedPrompt += '\n\n**Aspect quotidien du nombre $number :** ${description['quotidien']}';
    }

    if (description['figure']!.isNotEmpty) {
      enhancedPrompt += '\n\n**Figure géométrique :** ${description['figure']}';
    }

    if (description['symbole']!.isNotEmpty) {
      enhancedPrompt += '\n\n**Symbolisme :** ${description['symbole']}';
    }

    enhancedPrompt += '\n\nUtilise ces informations pour donner une interprétation plus riche et personnalisée du nombre $number en tant que $numberType.';

    return enhancedPrompt;
  }

  /// Check if descriptions are loaded
  static bool get isLoaded => _descriptions != null && _descriptions!.isNotEmpty;

  /// Get all available number descriptions
  static Map<String, dynamic>? getAllDescriptions() {
    return _descriptions;
  }

  /// Get available numbers
  static List<int> getAvailableNumbers() {
    if (_descriptions == null) return [];
    return _descriptions!.keys
        .where((key) => int.tryParse(key) != null)
        .map((key) => int.parse(key))
        .toList()
        ..sort();
  }
}