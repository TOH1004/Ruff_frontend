// File: lib/firebase_friends_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friendmodel.dart';
class FirebaseFriendsService {
  static final _firestore = FirebaseFirestore.instance;

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🔍 [DEBUG] No current user found');
        return null;
      }
      
      print('🔍 [DEBUG] Getting user data for: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        print('🔍 [DEBUG] User document does not exist');
        return null;
      }
      
      final userData = doc.data();
      print('🔍 [DEBUG] Current user data: $userData');
      return userData;
    } catch (e) {
      print('🔍 [DEBUG] Error getting current user data: $e');
      return null;
    }
  }

  // Get current user's username
  static Future<String?> getCurrentUserUsername() async {
    final userData = await getCurrentUserData();
    return userData?['username'];
  }

  // Check if username exists and get user ID
  static Future<String?> getUserIdFromUsername(String username) async {
    try {
      print('🔍 [DEBUG] Looking up user ID for username: $username');
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        print('🔍 [DEBUG] Username not found: $username');
        return null;
      }
      
      final userId = query.docs.first.id;
      print('🔍 [DEBUG] Found user ID: $userId for username: $username');
      return userId;
    } catch (e) {
      print('🔍 [DEBUG] Error getting user ID from username: $e');
      return null;
    }
  }

  // Check if users are already friends
  static Future<bool> areAlreadyFriends(String userId1, String userId2) async {
    try {
      print('🔍 [DEBUG] Checking if users are already friends: $userId1 and $userId2');
      
      // Check if friendship exists (either direction)
      final friendshipQuery = await _firestore
          .collection('friends')
          .where('user1', isEqualTo: userId1)
          .where('user2', isEqualTo: userId2)
          .limit(1)
          .get();

      final reverseFriendshipQuery = await _firestore
          .collection('friends')
          .where('user1', isEqualTo: userId2)
          .where('user2', isEqualTo: userId1)
          .limit(1)
          .get();

      final areFriends = friendshipQuery.docs.isNotEmpty || reverseFriendshipQuery.docs.isNotEmpty;
      print('🔍 [DEBUG] Are already friends: $areFriends');
      return areFriends;
    } catch (e) {
      print('🔍 [DEBUG] Error checking friendship: $e');
      return false;
    }
  }

  // Check if friend request already exists
  static Future<bool> friendRequestExists(String fromUserId, String toUserId) async {
    try {
      print('🔍 [DEBUG] Checking if friend request exists between: $fromUserId and $toUserId');
      
      // Check both directions for pending requests
      final requestQuery = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      final reverseRequestQuery = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: toUserId)
          .where('toUserId', isEqualTo: fromUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      final exists = requestQuery.docs.isNotEmpty || reverseRequestQuery.docs.isNotEmpty;
      print('🔍 [DEBUG] Friend request exists: $exists');
      return exists;
    } catch (e) {
      print('🔍 [DEBUG] Error checking friend request existence: $e');
      return false;
    }
  }

  static Future<bool> ensureChatExists(String userId1, String userId2) async {
  try {
    final chatId = _generateChatId(userId1, userId2);
    print('🔍 [DEBUG] Ensuring chat exists: $chatId');
    
    // Check if chat already exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (chatDoc.exists) {
      print('🔍 [DEBUG] Chat already exists');
      return true;
    }
    
    // Create the chat document
    await _firestore.collection('chats').doc(chatId).set({
      'members': [userId1, userId2],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': null,
      'lastMessageSender': '',
    });
    
    print('🔍 [DEBUG] Chat document created: $chatId');
    return true;
    
  } catch (e) {
    print('🔍 [DEBUG] Error ensuring chat exists: $e');
    return false;
  }
}

// Updated acceptFriendRequest method to ensure chat creation
static Future<bool> acceptFriendRequest(String requestId) async {
  try {
    print('🔍 [DEBUG] Accepting friend request: $requestId');
    
    final batch = _firestore.batch();
    
    // Get the friend request
    final requestDoc = await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .get();
    
    if (!requestDoc.exists) {
      print('🔍 [DEBUG] Request document does not exist');
      return false;
    }
    
    final requestData = requestDoc.data()!;
    final fromUserId = requestData['fromUserId'];
    final toUserId = requestData['toUserId'];
    
    print('🔍 [DEBUG] Request data: $requestData');
    
    if (fromUserId == null || toUserId == null) {
      print('🔍 [DEBUG] Missing user IDs in request');
      return false;
    }

    // Create friendship document
    batch.set(
      _firestore.collection('friends').doc(),
      {
        'user1': fromUserId,
        'user2': toUserId,
        'since': FieldValue.serverTimestamp(),
      },
    );

    // Create chat document for the new friends
    final chatId = _generateChatId(fromUserId, toUserId);
    batch.set(
      _firestore.collection('chats').doc(chatId),
      {
        'members': [fromUserId, toUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': null,
        'lastMessageSender': '',
      },
    );

    // Update request status to 'accepted'
    batch.update(
      _firestore.collection('friend_requests').doc(requestId),
      {
        'status': 'accepted',
        'timestamp': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
    
    // Double-check that the chat was created successfully
    await Future.delayed(const Duration(milliseconds: 500)); // Small delay for consistency
    final chatCreated = await ensureChatExists(fromUserId, toUserId);
    
    if (chatCreated) {
      print('🔍 [DEBUG] Friend request accepted successfully and chat confirmed');
      return true;
    } else {
      print('🔍 [DEBUG] Friend request accepted but chat creation failed');
      return false;
    }
    
  } catch (e) {
    print('🔍 [DEBUG] Error accepting friend request: $e');
    return false;
  }
}

// Method to fix existing friendships that don't have chat documents
static Future<void> fixMissingChats(String userId) async {
  try {
    print('🔍 [DEBUG] Checking for missing chats for user: $userId');
    
    // Get all friendships for the user
    final friends1 = await _firestore
        .collection('friends')
        .where('user1', isEqualTo: userId)
        .get();
    
    final friends2 = await _firestore
        .collection('friends')
        .where('user2', isEqualTo: userId)
        .get();
    
    Set<String> friendIds = {};
    
    // Collect all friend IDs
    for (var doc in friends1.docs) {
      final data = doc.data();
      friendIds.add(data['user2']);
    }
    
    for (var doc in friends2.docs) {
      final data = doc.data();
      friendIds.add(data['user1']);
    }
    
    print('🔍 [DEBUG] Found ${friendIds.length} friends, checking chats...');
    
    // Check and create missing chats
    for (String friendId in friendIds) {
      final chatExists = await ensureChatExists(userId, friendId);
      if (chatExists) {
        print('🔍 [DEBUG] Chat confirmed for friend: $friendId');
      } else {
        print('🔍 [DEBUG] Failed to create chat for friend: $friendId');
      }
    }
    
  } catch (e) {
    print('🔍 [DEBUG] Error fixing missing chats: $e');
  }
}

// Call this method when user opens chat tab to ensure all chats exist
static Future<void> initializeChatsForUser(String userId) async {
  try {
    await fixMissingChats(userId);
    print('🔍 [DEBUG] Chat initialization complete for user: $userId');
  } catch (e) {
    print('🔍 [DEBUG] Error initializing chats: $e');
  }
}

  static Future<void> debugFriendsAndChats(String userId) async {
  try {
    print('🔍 [DEBUG] === DEBUGGING FRIENDS AND CHATS FOR USER: $userId ===');
    
    // Check friendships where user is user1
    print('🔍 [DEBUG] Checking friendships where user is user1...');
    final friends1 = await _firestore
        .collection('friends')
        .where('user1', isEqualTo: userId)
        .get();
    
    print('🔍 [DEBUG] Found ${friends1.docs.length} friendships as user1');
    for (var doc in friends1.docs) {
      final data = doc.data();
      print('🔍 [DEBUG] Friendship: ${doc.id} -> user1: ${data['user1']}, user2: ${data['user2']}');
      
      // Check if chat exists
      final chatId = _generateChatId(data['user1'], data['user2']);
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      print('🔍 [DEBUG] Chat $chatId exists: ${chatDoc.exists}');
      if (chatDoc.exists) {
        print('🔍 [DEBUG] Chat data: ${chatDoc.data()}');
      }
    }
    
    // Check friendships where user is user2
    print('🔍 [DEBUG] Checking friendships where user is user2...');
    final friends2 = await _firestore
        .collection('friends')
        .where('user2', isEqualTo: userId)
        .get();
    
    print('🔍 [DEBUG] Found ${friends2.docs.length} friendships as user2');
    for (var doc in friends2.docs) {
      final data = doc.data();
      print('🔍 [DEBUG] Friendship: ${doc.id} -> user1: ${data['user1']}, user2: ${data['user2']}');
      
      // Check if chat exists
      final chatId = _generateChatId(data['user1'], data['user2']);
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      print('🔍 [DEBUG] Chat $chatId exists: ${chatDoc.exists}');
      if (chatDoc.exists) {
        print('🔍 [DEBUG] Chat data: ${chatDoc.data()}');
      }
    }
    
    // List all chats where user is a member
    print('🔍 [DEBUG] Checking all chats where user is a member...');
    final allChats = await _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .get();
    
    print('🔍 [DEBUG] Found ${allChats.docs.length} chats as member');
    for (var doc in allChats.docs) {
      final data = doc.data();
      print('🔍 [DEBUG] Chat: ${doc.id} -> members: ${data['members']}, lastMessage: ${data['lastMessage']}');
    }
    
    print('🔍 [DEBUG] === END DEBUG ===');
    
  } catch (e) {
    print('🔍 [DEBUG] Error in debug method: $e');
  }
}

  // Send friend request using username
  static Future<String> sendFriendRequest(String toUsername) async {
    try {
      print('🔍 [DEBUG] Starting friend request process to: $toUsername');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'error_no_auth';
      
      // Get current user data
      final currentUserId = user.uid;
      final currentUserData = await getCurrentUserData();
      if (currentUserData == null) {
        print('🔍 [DEBUG] Failed: Current user data is null');
        return 'error_no_username';
      }
      
      final currentUsername = currentUserData['username'];
      if (currentUsername == null || currentUsername.isEmpty) {
        print('🔍 [DEBUG] Failed: Current user has no username');
        return 'error_no_username';
      }
      
      // Check if username exists and get target ID
      final targetUserId = await getUserIdFromUsername(toUsername);
      if (targetUserId == null) {
        print('🔍 [DEBUG] Failed: Target username does not exist');
        return 'error_user_not_found';
      }

      // Check if trying to add yourself
      if (currentUserId == targetUserId) {
        print('🔍 [DEBUG] Failed: Trying to add yourself');
        return 'error_self_add';
      }

      // Check if already friends
      final alreadyFriends = await areAlreadyFriends(currentUserId, targetUserId);
      if (alreadyFriends) {
        print('🔍 [DEBUG] Failed: Already friends');
        return 'error_already_friends';
      }

      // Check if friend request already exists
      final requestExists = await friendRequestExists(currentUserId, targetUserId);
      if (requestExists) {
        print('🔍 [DEBUG] Failed: Friend request already exists');
        return 'error_request_exists';
      }
      
      // Create friend request
      print('🔍 [DEBUG] Creating friend request...');
      final docRef = await _firestore.collection('friend_requests').add({
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('🔍 [DEBUG] Friend request created with ID: ${docRef.id}');
      return 'success';

    } catch (e) {
      print('🔍 [DEBUG] Error in sendFriendRequest: $e');
      return 'error_exception';
    }
  }

  // Accept friend request


  // Helper method to generate consistent chat ID
  static String _generateChatId(String userId1, String userId2) {
    // Sort user IDs to ensure consistent chat ID regardless of order
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Reject friend request
  static Future<bool> rejectFriendRequest(String requestId) async {
    try {
      print('🔍 [DEBUG] Rejecting friend request: $requestId');
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'rejected',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('🔍 [DEBUG] Friend request rejected successfully');
      return true;
    } catch (e) {
      print('🔍 [DEBUG] Error rejecting friend request: $e');
      return false;
    }
  }

  // Get user's friends list with last message info
static Stream<List<Friend>> getUserFriends(String userId) {
  return _firestore
      .collection('friends')
      .where('user1', isEqualTo: userId)
      .snapshots()
      .asyncMap((snapshot1) async {
    List<Friend> friends = [];
    
    // Get friends where current user is user1
    for (var doc in snapshot1.docs) {
      try {
        final data = doc.data();
        final friendId = data['user2'];
        
        if (friendId == null || friendId.isEmpty) continue;
        
        final friendData = await _firestore.collection('users').doc(friendId).get();
        
        if (friendData.exists && friendData.data() != null) {
          // Get chat info for last message with error handling
          final chatId = _generateChatId(userId, friendId);
          String lastMessage = '';
          String lastTime = '';
          
          try {
            final chatDoc = await _firestore.collection('chats').doc(chatId).get();
            
            if (chatDoc.exists && chatDoc.data() != null) {
              final chatData = chatDoc.data()!;
              lastMessage = chatData['lastMessage']?.toString() ?? '';
              final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
              
              if (lastMessageTime != null) {
                lastTime = _formatMessageTime(lastMessageTime.toDate());
              }
            } else {
              // Chat document doesn't exist, create it
              await _createChatIfNotExists(userId, friendId);
              lastMessage = '';
              lastTime = '';
            }
          } catch (e) {
            print('🔍 [DEBUG] Error accessing chat $chatId: $e');
            // If chat access fails, still show the friend but without last message info
            lastMessage = '';
            lastTime = '';
          }
          
          final userData = friendData.data()!;
          friends.add(Friend(
            userId: friendId,
            username: userData['username']?.toString() ?? '',
            name: userData['name']?.toString() ?? 'No Name',
            lastMessage: lastMessage,
            lastTime: lastTime,
            isOnline: userData['isOnline'] == true,
          ));
        }
      } catch (e) {
        print('🔍 [DEBUG] Error processing friend document: $e');
        continue; // Skip this friend and continue with others
      }
    }

    // Get friends where current user is user2
    try {
      final snapshot2 = await _firestore
          .collection('friends')
          .where('user2', isEqualTo: userId)
          .get();
      
      for (var doc in snapshot2.docs) {
        try {
          final data = doc.data();
          final friendId = data['user1'];
          
          if (friendId == null || friendId.isEmpty) continue;
          
          final friendData = await _firestore.collection('users').doc(friendId).get();
          
          if (friendData.exists && friendData.data() != null) {
            // Get chat info for last message with error handling
            final chatId = _generateChatId(userId, friendId);
            String lastMessage = '';
            String lastTime = '';
            
            try {
              final chatDoc = await _firestore.collection('chats').doc(chatId).get();
              
              if (chatDoc.exists && chatDoc.data() != null) {
                final chatData = chatDoc.data()!;
                lastMessage = chatData['lastMessage']?.toString() ?? '';
                final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
                
                if (lastMessageTime != null) {
                  lastTime = _formatMessageTime(lastMessageTime.toDate());
                }
              } else {
                // Chat document doesn't exist, create it
                await _createChatIfNotExists(userId, friendId);
                lastMessage = '';
                lastTime = '';
              }
            } catch (e) {
              print('🔍 [DEBUG] Error accessing chat $chatId: $e');
              // If chat access fails, still show the friend but without last message info
              lastMessage = '';
              lastTime = '';
            }
            
            final userData = friendData.data()!;
            friends.add(Friend(
              userId: friendId,
              username: userData['username']?.toString() ?? '',
              name: userData['name']?.toString() ?? 'No Name',
              lastMessage: lastMessage,
              lastTime: lastTime,
              isOnline: userData['isOnline'] == true,
            ));
          }
        } catch (e) {
          print('🔍 [DEBUG] Error processing friend document: $e');
          continue; // Skip this friend and continue with others
        }
      }
    } catch (e) {
      print('🔍 [DEBUG] Error querying friends where user2 = $userId: $e');
    }

    return friends;
  });
}

// Helper method to create chat document if it doesn't exist
static Future<void> _createChatIfNotExists(String userId1, String userId2) async {
  try {
    final chatId = _generateChatId(userId1, userId2);
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'members': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': null,
        'lastMessageSender': '',
      });
      print('🔍 [DEBUG] Created missing chat document: $chatId');
    }
  } catch (e) {
    print('🔍 [DEBUG] Error creating chat document: $e');
    // Don't throw error, just log it
  }
}

  // Helper method to format message time
  static String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Get pending friend requests for current user
  static Stream<List<FriendRequest>> getPendingFriendRequests(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      List<FriendRequest> requests = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fromUserId = data['fromUserId'];
        
        // Get sender's username
        final senderDoc = await _firestore.collection('users').doc(fromUserId).get();
        final senderUsername = senderDoc.data()?['username'] ?? 'Unknown';
        
        requests.add(FriendRequest(
          requestId: doc.id,
          fromUserId: fromUserId,
          fromUserName: senderUsername,
          toUserId: userId,
          toUserName: '', // Not needed for incoming requests
          status: data['status'],
          timestamp: data['timestamp'] ?? Timestamp.now(),
        ));
      }
      
      return requests;
    });
  }
}