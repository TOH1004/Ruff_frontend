import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class WebRTCService {
  Future<webrtc.MediaStream> getUserMedia(bool isFrontCamera) async {
    return await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'width': 640,
        'height': 480,
        'facingMode': isFrontCamera ? 'user' : 'environment',
      },
    });
  }

  Future<webrtc.MediaStream> switchCamera(bool newCameraFront, webrtc.RTCPeerConnection? peerConnection) async {
    // Get new media with the opposite camera
    final newStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'width': 640,
        'height': 480,
        'facingMode': newCameraFront ? 'user' : 'environment',
      },
    });

    // Replace video track in peer connection
    if (peerConnection != null) {
      final senders = await peerConnection.getSenders();
      final videoSender = senders.firstWhere(
        (s) => s.track?.kind == 'video',
        orElse: () => throw Exception('Video sender not found'),
      );
      await videoSender.replaceTrack(newStream.getVideoTracks().first);
    }

    return newStream;
  }

  Future<webrtc.RTCPeerConnection> createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject'
        },
      ],
      'iceCandidatePoolSize': 10,
    };

    return await webrtc.createPeerConnection(configuration);
  }
}