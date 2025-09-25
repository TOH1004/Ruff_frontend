import 'package:flutter_webrtc/flutter_webrtc.dart';

class Participant {
  final String id;
  final String name;
  final RTCVideoRenderer renderer;
  final RTCPeerConnection? peerConnection;
  bool isAudioMuted;
  bool isVideoEnabled;

  Participant({
    required this.id,
    required this.name,
    required this.renderer,
    this.peerConnection,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
  });
}