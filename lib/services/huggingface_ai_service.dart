import 'dart:convert';
import 'package:http/http.dart' as http;

class HuggingFaceAIService {
  // OpenAI-compatible Chat Completions endpoint on Hugging Face Inference Router
  static const String endpoint = "https://router.huggingface.co/v1/chat/completions";
  
  // Preferred Qwen model
  static const String defaultModel = "Qwen/Qwen2.5-7B-Instruct";

  // Development fallback token holder.
  // Can be configured at runtime via Settings or passed through --dart-define=HF_TOKEN=your_token
  static String _runtimeToken = const String.fromEnvironment('HF_TOKEN', defaultValue: '');

  static void setApiToken(String token) {
    _runtimeToken = token.trim();
  }

  static String get apiToken => _runtimeToken;
  static bool get hasToken => _runtimeToken.isNotEmpty;

  /// Calls the real Hugging Face OpenAI-compatible Chat Completion API
  static Future<String> generateResponse(List<Map<String, String>> messages, {String? model}) async {
    final token = _runtimeToken;

    if (token.isEmpty) {
      throw Exception(
        "HF_TOKEN is not configured.\n\n"
        "Please provide a Hugging Face API Token in Settings or pass via --dart-define=HF_TOKEN=your_token to connect to real Qwen2.5-7B-Instruct."
      );
    }

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    final body = jsonEncode({
      "model": model ?? defaultModel,
      "messages": messages,
      "max_tokens": 800,
      "temperature": 0.7,
      "stream": false,
    });

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null && message['content'] != null) {
            return message['content'] as String;
          }
        }
        throw Exception("Invalid response structure from Hugging Face: ${response.body}");
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception("Authentication failed (HTTP ${response.statusCode}). Please check your Hugging Face API Token.");
      } else if (response.statusCode == 503) {
        throw Exception("Model is currently loading or busy on Hugging Face (HTTP 503). Please retry in a few seconds.");
      } else {
        throw Exception("Inference error (HTTP ${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("AI connection failed. Please check your internet connection or Hugging Face configuration: $e");
    }
  }
}
