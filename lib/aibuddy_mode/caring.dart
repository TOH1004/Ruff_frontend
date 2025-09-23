import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:ruff/services/gemini_service.dart';

class CaringModePage extends StatefulWidget {
  const CaringModePage({super.key});

  @override
  State<CaringModePage> createState() => _CaringModePageState();
}

class _CaringModePageState extends State<CaringModePage> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiService _aiService = GeminiService();

  String _response = "Hello 🤗, I'm here to comfort you.";
  String _userMessage = "";
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speak(_response); // Speak default message when page opens
  }

  /// Text-to-speech
  Future<void> _speak(String text) async {
    try {
      await _flutterTts.stop(); // stop any ongoing speech
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  /// Call Gemini AI
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
      await _speak(_response);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Start or stop listening
  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print("Speech status: $status");
          if (status == "done" || status == "notListening") {
            setState(() => _isListening = false);

            if (_userMessage.isNotEmpty) {
              _getAIResponse(_userMessage);
            } else {
              setState(() {
                _response = "I didn’t catch that, could you try again? 🥺";
              });
              _speak(_response);
            }
          }
        },
        onError: (val) {
          print("Speech error: $val");
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _userMessage = "";
        });

        _speech.listen(
          listenFor: const Duration(seconds: 20), // listen up to 20s
          pauseFor: const Duration(seconds: 5),   // allow 5s silence before ending
          onResult: (val) {
            setState(() {
              _userMessage = val.recognizedWords;
            });

            if (val.finalResult && _userMessage.isNotEmpty) {
              _getAIResponse(_userMessage);
            }
          },
        );
      } else {
        setState(() {
          _response = "Speech recognition not available 😢";
        });
        _speak(_response);
      }
    } else {
      // If already listening, stop manually
      setState(() => _isListening = false);
      _speech.stop();
      if (_userMessage.isNotEmpty) {
        _getAIResponse(_userMessage);
      }
    }
  }

  /// Stop AI talking (TTS)
  Future<void> _stopTalking() async {
    await _flutterTts.stop();
    setState(() {
      _response = "I stopped talking 😊";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Caring Mode 🎵")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // AI response display
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            // Show user speech text
            if (_userMessage.isNotEmpty)
              Text(
                "You said: $_userMessage",
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 10),

            // Loading spinner or buttons
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _listen,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    label: Text(_isListening ? "Listening..." : "Speak"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _stopTalking,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
