import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/participant.dart';

class ParticipantGrid extends StatelessWidget {
  final RTCVideoRenderer localRenderer;
  final List<Participant> remoteParticipants;
  final bool isFrontCamera;
  final bool isVideoEnabled;
  final bool isMuted;

  const ParticipantGrid({
    super.key,
    required this.localRenderer,
    required this.remoteParticipants,
    required this.isFrontCamera,
    required this.isVideoEnabled,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate grid dimensions based on number of participants
    int totalParticipants = remoteParticipants.length + 1; // +1 for local
    int crossAxisCount = totalParticipants <= 2 ? 1 : 2;
    
    List<Widget> participantWidgets = [];
    
    // Add local participant (self)
    participantWidgets.add(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              RTCVideoView(localRenderer, mirror: isFrontCamera),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              if (!isVideoEnabled)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Icon(Icons.videocam_off, color: Colors.white, size: 32),
                  ),
                ),
              if (isMuted)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.mic_off, color: Colors.red, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
    
    // Add remote participants
    for (var participant in remoteParticipants) {
      participantWidgets.add(
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                RTCVideoView(participant.renderer),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      participant.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                if (participant.isAudioMuted)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.mic_off, color: Colors.red, size: 20),
                  ),
                if (!participant.isVideoEnabled)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(Icons.videocam_off, color: Colors.white, size: 32),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: participantWidgets,
    );
  }
}