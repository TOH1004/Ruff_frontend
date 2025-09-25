import 'package:flutter/foundation.dart';

/// Status model class with Firebase support
class Status {
  final String issueText;
  final List<String> imagePaths; // Can contain both local paths and Firebase URLs
  final String location;
  final DateTime timestamp;
  final String id;
  
  // Additional Firebase fields
  final String? userId;
  final String? userName;
  final String? userEmail;
  final List<String>? mentionedFriends;
  final String? visibility;
  final List<String>? likes;
  final List<Map<String, dynamic>>? comments;
  final bool isActive;

  Status({
    required this.issueText,
    required this.imagePaths,
    required this.location,
    DateTime? timestamp,
    String? id,
    this.userId,
    this.userName,
    this.userEmail,
    this.mentionedFriends,
    this.visibility,
    this.likes,
    this.comments,
    this.isActive = true,
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Convert to Map for Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'issueText': issueText,
      'imagePaths': imagePaths,
      'imageUrls': imagePaths, // For backward compatibility
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'mentionedFriends': mentionedFriends ?? [],
      'visibility': visibility ?? 'Friends',
      'likes': likes ?? [],
      'comments': comments ?? [],
      'isActive': isActive,
      'createdAt': timestamp.toIso8601String(),
    };
  }

  /// Create from Map for Firebase deserialization
  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: map['userId'],
      userName: map['userName'],
      userEmail: map['userEmail'],
      issueText: map['issueText'] ?? 'No issue text',
      imagePaths: List<String>.from(map['imageUrls'] ?? map['imagePaths'] ?? []),
      location: map['location'] ?? 'Unknown Location',
      timestamp: DateTime.tryParse(map['createdAt'] ?? map['timestamp'] ?? '') ?? DateTime.now(),
      mentionedFriends: List<String>.from(map['mentionedFriends'] ?? []),
      visibility: map['visibility'] ?? 'Friends',
      likes: List<String>.from(map['likes'] ?? []),
      comments: List<Map<String, dynamic>>.from(map['comments'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Create a copy with updated fields
  Status copyWith({
    String? issueText,
    List<String>? imagePaths,
    String? location,
    DateTime? timestamp,
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    List<String>? mentionedFriends,
    String? visibility,
    List<String>? likes,
    List<Map<String, dynamic>>? comments,
    bool? isActive,
  }) {
    return Status(
      issueText: issueText ?? this.issueText,
      imagePaths: imagePaths ?? this.imagePaths,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      mentionedFriends: mentionedFriends ?? this.mentionedFriends,
      visibility: visibility ?? this.visibility,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if current user has liked this status
  bool isLikedByUser(String userId) {
    return likes?.contains(userId) ?? false;
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'Status(id: $id, userId: $userId, issueText: $issueText, location: $location, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Status && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Global history list for local caching (still useful for offline support)
ValueNotifier<List<Status>> statusHistory = ValueNotifier<List<Status>>([]);

/// Status manager to handle both local and Firebase operations
class StatusManager {
  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  static final ValueNotifier<String> syncStatus = ValueNotifier<String>('synced');

  /// Add status to local history (for immediate UI update)
  static void addToLocalHistory(Status status) {
    List<Status> currentList = List.from(statusHistory.value);
    currentList.insert(0, status); // Add to beginning
    statusHistory.value = currentList;
  }

  /// Remove status from local history
  static void removeFromLocalHistory(String statusId) {
    List<Status> currentList = List.from(statusHistory.value);
    currentList.removeWhere((status) => status.id == statusId);
    statusHistory.value = currentList;
  }

  /// Update status in local history
  static void updateInLocalHistory(Status updatedStatus) {
    List<Status> currentList = List.from(statusHistory.value);
    int index = currentList.indexWhere((status) => status.id == updatedStatus.id);
    if (index != -1) {
      currentList[index] = updatedStatus;
      statusHistory.value = currentList;
    }
  }

  /// Clear local history
  static void clearLocalHistory() {
    statusHistory.value = [];
  }

  /// Sync Firebase data with local history
  static void syncWithFirebase(List<Status> firebaseStatuses) {
    statusHistory.value = firebaseStatuses;
    syncStatus.value = 'synced';
  }

  /// Mark as syncing
  static void setSyncStatus(String status) {
    syncStatus.value = status;
  }
}

/// User model for Firebase

  class AppUser {
  final String uid;
  final String email;
  final String name;
  final List<String> friends;
  final int statusCount;
  final DateTime lastActive;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.friends = const [],
    this.statusCount = 0,
    DateTime? lastActive,
    DateTime? createdAt,
  })  : lastActive = lastActive ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Deserialize from Firebase
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? 'Anonymous',
      friends: List<String>.from(map['friends'] ?? []),
      statusCount: map['statusCount'] ?? 0,
      lastActive: DateTime.tryParse(map['lastActive']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Serialize to Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'friends': friends,
      'statusCount': statusCount,
      'lastActive': lastActive.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with updates
  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    List<String>? friends,
    int? statusCount,
    DateTime? lastActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      friends: friends ?? this.friends,
      statusCount: statusCount ?? this.statusCount,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, name: $name, statusCount: $statusCount, lastActive: $lastActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
