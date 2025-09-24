import '../openai_client.dart';
import '../utils/astrology_utils.dart';
import 'rag_service.dart';

class ChartInterpretationService {
  final OpenAIClient _openAIClient;
  final RagService? _ragService;

  ChartInterpretationService(this._openAIClient, [this._ragService]);

  /// Generate a comprehensive chart interpretation
  Future<String> generateChartInterpretation(Map<String, dynamic> chartData) async {
    final prompt = _buildChartAnalysisPrompt(chartData);
    
    // Use RAG if available, otherwise fallback to regular OpenAI
    if (_ragService != null) {
      return await generateRagBasedInterpretation(chartData);
    } else {
      return await _openAIClient.sendMessage(prompt);
    }
  }

  /// Generate interpretation using RAG (Retrieval-Augmented Generation)
  Future<String> generateRagBasedInterpretation(Map<String, dynamic> chartData) async {
    if (_ragService == null) {
      throw Exception('RAG service not available');
    }

    try {
      // Create a query based on the chart data
      final query = _buildRagQuery(chartData);
      
      // Custom system prompt for astrology interpretation
      final systemPrompt = '''
Tu es un astrologue expert utilisant une base de connaissances spécialisée. 
Analyse cette carte natale en utilisant les informations contextuelles fournies.
Combine les données astronomiques précises avec les interprétations traditionnelles et modernes.
Sois précis, bienveillant et constructif dans ton analyse.
''';

      // Get RAG-enhanced response
      final ragResponse = await _ragService!.askQuestion(
        query,
        topK: 10,
        scoreThreshold: 0.6,
        systemPrompt: systemPrompt,
        contextFilter: 'astronomie',
      );

      return ragResponse['answer'] as String;
    } catch (e) {
      // Fallback to regular interpretation if RAG fails
      print('⚠️ RAG interpretation failed, falling back to regular method: $e');
      final prompt = _buildChartAnalysisPrompt(chartData);
      return await _openAIClient.sendMessage(prompt);
    }
  }

  /// Build a query for RAG based on chart data
  String _buildRagQuery(Map<String, dynamic> chartData) {
    final planets = chartData['planets'] as List;
    final houses = chartData['houses'] as List;
    
    // Extract key astrological elements for RAG query
    final sun = planets.firstWhere((p) => p['name'] == 'Sun', orElse: () => null);
    final moon = planets.firstWhere((p) => p['name'] == 'Moon', orElse: () => null);
    final ascendant = houses.isNotEmpty ? houses[0] : null;
    
    String query = "Interprétation astrologique pour une personne née le ${chartData['date']} à ${chartData['time']}";
    
    if (sun != null) {
      query += " avec Soleil en ${sun['sign']}";
    }
    if (moon != null) {
      query += " et Lune en ${moon['sign']}";
    }
    if (ascendant != null) {
      query += " et Ascendant en ${ascendant['sign']}";
    }
    
    // Add retrograde planets to query
    final retrogradePlanets = planets.where((p) => p['is_retrograde'] == true).toList();
    if (retrogradePlanets.isNotEmpty) {
      final retroNames = retrogradePlanets.map((p) => p['name']).join(', ');
      query += ". Planètes rétrogrades: $retroNames";
    }
    
    query += ". Analyse personnalité, traits dominants, défis et opportunités.";
    
    return query;
  }

  /// Send a custom prompt for chart analysis
  Future<String> sendCustomPrompt(String prompt) async {
    // Use RAG for custom prompts if available
    if (_ragService != null) {
      try {
        final ragResponse = await _ragService!.askQuestion(prompt, contextFilter: 'astronomie');
        return ragResponse['answer'] as String;
      } catch (e) {
        print('⚠️ RAG custom prompt failed, falling back: $e');
      }
    }
    
    return await _openAIClient.sendMessage(prompt);
  }

  /// Ask a specific astrological question using RAG
  Future<Map<String, dynamic>> askAstrologicalQuestion(String question) async {
    if (_ragService == null) {
      throw Exception('RAG service not available');
    }

    return await _ragService!.askQuestion(
      question,
      topK: 8,
      scoreThreshold: 0.5, // Lowered from 0.7 to capture more relevant matches
      systemPrompt: '''
Tu es un astrologue expert avec accès à une vaste base de connaissances. 
Réponds aux questions astrologiques en utilisant les informations contextuelles disponibles.
Cite tes sources quand c'est pertinent et sois précis dans tes explications.
''',
      contextFilter: 'astronomie',
    );
  }

  /// Search for astrological concepts in the knowledge base
  Future<List<Map<String, dynamic>>> searchAstrologicalConcepts(String searchTerm) async {
    if (_ragService == null) {
      throw Exception('RAG service not available');
    }

    final ragResults = await _ragService!.performRagQuery(
      searchTerm,
      topK: 15,
      scoreThreshold: 0.5,
      contextFilter: 'astronomie',
    );

    return ragResults['results'] as List<Map<String, dynamic>>;
  }

  /// Build a comprehensive analysis prompt from chart data (fallback method)
  String _buildChartAnalysisPrompt(Map<String, dynamic> chartData) {
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
      final house = AstrologyUtils.findPlanetHouse(planet, houses);
      
      // Add retrograde indicator if present
      final isRetrograde = planet['is_retrograde'] == true;
      final retrogradeText = isRetrograde ? ' (R)' : '';
      
      prompt += "\n- $name en $sign ${degree?.toStringAsFixed(1)}°$retrogradeText (Maison $house)";
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

  /// Get the last generated prompt (useful for debugging/editing)
  String getLastPrompt(Map<String, dynamic> chartData) {
    return _buildChartAnalysisPrompt(chartData);
  }
}