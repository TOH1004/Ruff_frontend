import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ SECURITY WARNING: Do NOT hardcode your API key like this in production apps.
  // Use environment variables or a secure backend. For quick debugging, it's ok.
  final String _apiKey = "AIzaSyB7u_kb7wZDdbkcEn5k2Bd5ZW-e6BKqSCk"; 

  // --- CRITICAL CHANGE 1: Correct Base URL for generateContent ---
  // The base URL for the API is generativelanguage.googleapis.com/v1beta
  // The model path and generateContent method are appended to it.
  final String _baseUrl = "https://generativelanguage.googleapis.com/v1beta";
  final String _modelId = "gemini-2.0-flash"; 

  final String mode;

  GeminiService({this.mode = "caring"}); // default mode

  Future<String> askGemini(String userMessage) async {
    try {
      final systemPrompt = _getSystemPrompt(mode);
      final finalPrompt = "$systemPrompt\nUser: $userMessage";

      // --- CRITICAL CHANGE 2: Correcting the POST URI ---
      // The API key should be appended as a query parameter to the base URL,
      // and the model specific endpoint comes after '/models/'
      final uri = Uri.parse('$_baseUrl/models/$_modelId:generateContent?key=$_apiKey');

      final response = await http.post(
        uri, // Use the correctly constructed URI
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": finalPrompt}
              ]
            }
          ],
          // Add generation config if needed, e.g., temperature, topP, topK
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 200, // Limit response length
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Gemini returns data["candidates"][0]["content"]["parts"][0]["text"]
        final output = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        return output ?? "I couldn’t think of a reply 🤔";
      } else {
        // --- IMPROVEMENT: Include full error details ---
        print('Gemini API Error: Status ${response.statusCode}');
        print('Response Body: ${response.body}');
        return "Gemini API error: ${response.statusCode} → ${response.body}";
      }
    } catch (e) {
      print('Caught exception: $e'); // Log the error for debugging
      return "Something went wrong: $e";
    }
  }

  String _getSystemPrompt(String mode) {
    switch (mode) {
      case "caring":
        return "You are a warm, caring AI friend. Respond with empathy, kindness, and gentle reassurance.";
      case "silent":
        return "You are a minimal AI 🤐. Respond briefly and calmly.";
      case "chatty":
        return "You are an energetic, chatty AI friend.";
      default:
        return "You are a helpful AI assistant.";
    }
  }
}
