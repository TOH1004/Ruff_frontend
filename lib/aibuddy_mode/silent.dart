import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ruff/services/gemini_service.dart';

class SilentModePage extends StatefulWidget {
  const SilentModePage({super.key});

  @override
  State<SilentModePage> createState() => _SilentModePageState();
}

class _SilentModePageState extends State<SilentModePage> {
 
  final FlutterTts _flutterTts = FlutterTts();
  String _response = "Hello 🤗, I'm here to comfort you.";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _speak(_response); // Speak default message when page opens
  }

  /// Text-to-speech
  Future<void> _speak(String text) async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  /// Call GPT
final GeminiService _aiService = GeminiService();

Future<void> _getAIResponse(String userMessage) async {
  setState(() => _isLoading = true);
  try {
    final response = await _aiService.askGemini(userMessage);
    setState(() {
      _response = response;
    });
    await _speak(response);
  } catch (e) {
    setState(() {
      _response = "Error: $e";
    });
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Silent Mode 🎵")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display AI response
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            // User input
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Tell me how you feel 💬",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Button or loading spinner
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        _getAIResponse(_controller.text);
                        _controller.clear();
                      }
                    },
                    child: const Text("Send"),
                  ),
          ],
        ),
      ),
    );
  }
}
