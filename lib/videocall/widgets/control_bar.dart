import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  final bool isMuted;
  final bool isVideoEnabled;
  final VoidCallback onMutePressed;
  final VoidCallback onVideoPressed;
  final VoidCallback onSwitchCameraPressed;
  final VoidCallback onEndCallPressed;

  const ControlBar({
    super.key,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.onMutePressed,
    required this.onVideoPressed,
    required this.onSwitchCameraPressed,
    required this.onEndCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute button
            GestureDetector(
              onTap: onMutePressed,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isMuted ? Colors.red : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMuted ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Video on/off button
            GestureDetector(
              onTap: onVideoPressed,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: !isVideoEnabled ? Colors.red : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Switch camera button
            GestureDetector(
              onTap: onSwitchCameraPressed,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // End call button
            GestureDetector(
              onTap: onEndCallPressed,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}