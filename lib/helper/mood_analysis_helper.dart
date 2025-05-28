import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:no_couch_needed/config/api_config.dart';

Future<Map<String, String>> getMoodAndColour(String transcription) async {
  final apiKey = ApiConfig.openAiApiKey;
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "model": "gpt-4.1",
      "messages": [
        {
          "role": "system",
          "content":
              "You are an emotion analysis AI. Given TEXT, return JSON like: {\"mood\": \"sad\", \"colour\": \"cyan\"}. Use neutral/gray if no mood detected.",
        },
        {"role": "user", "content": "Text: $transcription"},
      ],
      "max_tokens": 20,
    }),
  );

  if (response.statusCode == 200) {
    // Try parsing the response
    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    // The model returns a string – parse it as JSON.
    return Map<String, String>.from(jsonDecode(content));
  } else {
    // Fallback to neutral/gray
    return {'mood': 'neutral', 'colour': 'gray'};
  }
}
