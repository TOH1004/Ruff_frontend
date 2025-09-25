// video_call_data.dart
import 'package:flutter/material.dart';

// Model class for video call history
class VideoCallHistory {
  final String participantName;
  final String callType; // 'emergency' or 'regular'
  final DateTime timestamp;
  final String duration;
  final String status; // 'completed', 'missed', 'declined'

  VideoCallHistory({
    required this.participantName,
    required this.callType,
    required this.timestamp,
    required this.duration,
    required this.status,
  });
}

// Global video call history store
ValueNotifier<List<VideoCallHistory>> videoCallHistory = ValueNotifier<List<VideoCallHistory>>([
  // Sample data
  VideoCallHistory(
    participantName: 'Emergency Services',
    callType: 'emergency',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    duration: '5:23',
    status: 'completed',
  ),
  VideoCallHistory(
    participantName: 'Campus Security',
    callType: 'regular',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    duration: '3:45',
    status: 'completed',
  ),
  VideoCallHistory(
    participantName: 'Safety Team',
    callType: 'emergency',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    duration: '7:12',
    status: 'completed',
  ),
]);