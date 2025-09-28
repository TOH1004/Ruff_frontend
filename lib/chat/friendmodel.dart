// File: lib/friendmodel.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// --- CHAT MODELS ---

class Friend {
  final String userId;
  final String username;
  final String name;
  final String lastMessage;
  final String lastTime;
  final bool isOnline;

  Friend({
    required this.userId,
    required this.username,
    required this.name,
    required this.lastMessage,
    required this.lastTime,
    this.isOnline = false,
  });

  // This factory is no longer used with the new structure
  // Keeping it for backward compatibility
  factory Friend.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Friend(
      userId: doc.id,
      username: data['username'] ?? 'No Username',
      name: data['name'] ?? 'No Name',
      lastMessage: data['lastMessage'] ?? 'Start a conversation!',
      lastTime: data['lastTime'] ?? '',
      isOnline: data['isOnline'] ?? false,
    );
  }
}

class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String status;
  final Timestamp timestamp;

  FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.status,
    required this.timestamp,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      requestId: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '', // This will be populated by the service
      toUserId: data['toUserId'] ?? '',
      toUserName: data['toUserName'] ?? '', // This will be populated by the service
      status: data['status'] ?? 'pending',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}