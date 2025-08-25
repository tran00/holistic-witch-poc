import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIClient {
  final String apiKey;

  OpenAIClient(this.apiKey);

  Future<String> sendMessage(String message) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": message}
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