import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String _apiKey = "AIzaSyCmBiQNAiQxAHEAardhLyXNsyRh3Ifk4TY"; // 🔑 replace with your key
  final String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";

  final String mode;

  GeminiService({this.mode = "caring"}); // default mode

  /// Ask Gemini AI for a response
  Future<String> askGemini(String userMessage) async {
    try {
      final systemPrompt = _getSystemPrompt(mode);
      final finalPrompt = "$systemPrompt\nUser: $userMessage";

      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": finalPrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final output =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        return output ?? "I couldn’t think of a reply 🤔";
      } else {
        return "Gemini API error: ${response.statusCode} → ${response.body}";
      }
    } catch (e) {
      return "Something went wrong: $e";
    }
  }

  /// Choose AI personality style
  String _getSystemPrompt(String mode) {
    switch (mode) {
      case "caring":
        return "You are a warm, caring AI friend. Respond with empathy, kindness, and gentle reassurance. Validate feelings, use soft language, offer practical help when useful, and ask one supportive question to invite sharing. Never claim real human experiences; be honest about limits. Keep tone comforting, patient, and non-judgmental.";
      case "silent":
        return "You are a minimal AI 🤐. Respond briefly and calmly.";
      case "chatty":
        return "You are an energetic, chatty AI friend. Engage the user with lively conversation and ask open-ended questions to encourage sharing.";
      default:
        return "You are a helpful AI assistant.";
    }
  }
}
