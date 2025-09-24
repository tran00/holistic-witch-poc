import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// DEBUG FLAG - Set to true to disable real OpenAI calls
const bool DISABLE_OPENAI = false;

class OpenAIClient {
  final String apiKey;

  OpenAIClient(this.apiKey);

  Future<String> sendMessage(String prompt) async {
    if (DISABLE_OPENAI) {
      print('🤖 OpenAI DISABLED - returning mock response');
      // For now, return a mock response
      // Replace this with your actual OpenAI implementation
      await Future.delayed(const Duration(seconds: 2));
      return 'Mock response for: ${prompt.substring(0, 50)}...';
    }

    // Real OpenAI implementation (only runs if DISABLE_OPENAI is false)
    if (apiKey.isEmpty) {
      throw Exception('API key is not configured');
    }

    if (prompt.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": dotenv.env['OPENAI_CHAT_MODEL'] ?? 'gpt-4o-mini',
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response: ${response.body}');
    }
  }
}

// Usage example:
// Make sure to call `await dotenv.load();` in your main() before using OpenAIClient.
final openAI = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
// Example usage in an async function:
// final reply = await openAI.sendMessage('Hello, OpenAI!');