// lib/services/openai_tarot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAITarotService {
  static OpenAITarotService? _instance;
  final String _apiKey;
  
  // Singleton pattern
  factory OpenAITarotService() {
    _instance ??= OpenAITarotService._internal();
    return _instance!;
  }

  OpenAITarotService._internal() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '' {
    if (_apiKey.isEmpty) {
      print('⚠️ Warning: OpenAI API key not found');
    }
  }
  
  // Standard chat completion
  Future<String> sendMessage(String message) async {
    return _makeRequest(message, model: 'gpt-3.5-turbo');
  }
  
  // Specialized method for tarot readings
  Future<String> getTarotReading(String prompt) async {
    return _makeRequest(prompt, 
      model: 'gpt-3.5-turbo',
      maxTokens: 1000,
      temperature: 0.8  // More creative for tarot
    );
  }
  
  // Specialized method for bonus readings
  Future<String> getBonusReading(String prompt) async {
    return _makeRequest(prompt,
      model: 'gpt-3.5-turbo', 
      maxTokens: 800,
      temperature: 0.7
    );
  }
  
  // Private method for actual API calls
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
  
  // Method to check if service is properly configured
  bool get isConfigured => _apiKey.isNotEmpty;
}