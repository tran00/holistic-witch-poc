// lib/services/openai_chart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIChartService {
  static OpenAIChartService? _instance;
  final String _apiKey;
  
  // Singleton pattern
  factory OpenAIChartService() {
    _instance ??= OpenAIChartService._internal();
    return _instance!;
  }
  
  OpenAIChartService._internal() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '' {
    if (_apiKey.isEmpty) {
      print('⚠️ Warning: OpenAI API key not found');
    }
  }
  
  /// Standard chat completion
  Future<String> sendMessage(String message) async {
    return _makeRequest(message, model: 'gpt-3.5-turbo');
  }
  
  /// Specialized method for chart interpretation
  Future<String> interpretChart(Map<String, dynamic> chartData) async {
    final planets = chartData['planets'] as List;
    final houses = chartData['houses'] as List;
    
    String prompt = """En tant qu'astrologue expert, analyse cette carte natale complète et donne une interprétation détaillée:

INFORMATIONS DE NAISSANCE:
- Nom: ${chartData['name'] ?? 'Personne'}
- Date: ${chartData['date']}
- Heure: ${chartData['time']}
- Lieu: ${chartData['location']}

POSITIONS PLANÉTAIRES:""";

    // Add planetary positions
    for (final planet in planets) {
      final name = planet['name'];
      final sign = planet['sign'];
      final degree = planet['longitude'] ?? planet['full_degree'];
      final house = _findPlanetHouse(planet, houses);
      prompt += "\n- $name en $sign ${degree?.toStringAsFixed(1)}° (Maison $house)";
    }

    prompt += "\n\nMAISONS ASTROLOGIQUES:";
    
    // Add house cusps
    for (int i = 0; i < houses.length; i++) {
      final house = houses[i];
      final sign = house['sign'];
      final degree = house['longitude'];
      prompt += "\n- Maison ${i + 1}: $sign ${degree?.toStringAsFixed(1)}°";
    }

    prompt += """

DEMANDE D'ANALYSE:
1. Analyse la personnalité générale basée sur le Soleil, la Lune et l'Ascendant
2. Décris les traits dominants de caractère
3. Explique les aspects majeurs entre planètes et leur influence
4. Analyse les secteurs de vie importants (maisons occupées)
5. Donne des conseils pour l'évolution personnelle
6. Mentionne les défis et opportunités principaux

Sois précis, bienveillant et constructif dans ton analyse.
Tu t'adresses à l'utilisateur de manière directe et personnelle.""";

    return await sendMessage(prompt);
  }

  /// Helper function to find which house a planet is in
  int _findPlanetHouse(Map<String, dynamic> planet, List houses) {
    final planetDegree = (planet['longitude'] ?? planet['full_degree'] ?? 0).toDouble();
    
    for (int i = 0; i < houses.length; i++) {
      final houseStart = (houses[i]['start_degree'] as num).toDouble();
      final houseEnd = (houses[i]['end_degree'] as num).toDouble();
      
      if (houseEnd > houseStart) {
        if (planetDegree >= houseStart && planetDegree < houseEnd) {
          return i + 1;
        }
      } else {
        // Handle houses that cross 0°
        if (planetDegree >= houseStart || planetDegree < houseEnd) {
          return i + 1;
        }
      }
    }
    return 1; // Default to house 1 if not found
  }

  /// Build the chart interpretation prompt (useful for editing)
  String buildChartPrompt(Map<String, dynamic> chartData) {
    final planets = chartData['planets'] as List;
    final houses = chartData['houses'] as List;
    
    String prompt = """En tant qu'astrologue expert, analyse cette carte natale complète et donne une interprétation détaillée:

INFORMATIONS DE NAISSANCE:
- Nom: ${chartData['name'] ?? 'Personne'}
- Date: ${chartData['date']}
- Heure: ${chartData['time']}
- Lieu: ${chartData['location']}

POSITIONS PLANÉTAIRES:""";

    // Add planetary positions
    for (final planet in planets) {
      final name = planet['name'];
      final sign = planet['sign'];
      final degree = planet['longitude'] ?? planet['full_degree'];
      final house = _findPlanetHouse(planet, houses);
      prompt += "\n- $name en $sign ${degree?.toStringAsFixed(1)}° (Maison $house)";
    }

    prompt += "\n\nMAISONS ASTROLOGIQUES:";
    
    // Add house cusps
    for (int i = 0; i < houses.length; i++) {
      final house = houses[i];
      final sign = house['sign'];
      final degree = house['longitude'];
      prompt += "\n- Maison ${i + 1}: $sign ${degree?.toStringAsFixed(1)}°";
    }

    prompt += """

DEMANDE D'ANALYSE:
1. Analyse la personnalité générale basée sur le Soleil, la Lune et l'Ascendant
2. Décris les traits dominants de caractère
3. Explique les aspects majeurs entre planètes et leur influence
4. Analyse les secteurs de vie importants (maisons occupées)
5. Donne des conseils pour l'évolution personnelle
6. Mentionne les défis et opportunités principaux

Sois précis, bienveillant et constructif dans ton analyse.
Tu t'adresses à l'utilisateur de manière directe et personnelle.""";

    return prompt;
  }
  
  /// Private method for actual API calls
  Future<String> _makeRequest(String message, {
    String model = 'gpt-3.5-turbo',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }
    
    if (message.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': message}
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 OpenAI Service Error: $e');
      rethrow;
    }
  }
  
  /// Check if service is properly configured
  bool get isConfigured => _apiKey.isNotEmpty;
}