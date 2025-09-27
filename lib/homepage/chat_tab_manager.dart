// File: lib/home_sections/chat_tab_manager.dart

import '../videocall/videocall_data.dart'; // Make sure to replace package_name
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- CHAT MODELS ---

// Model: Represents a friend request
class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String toUserId;
  final String fromName;

  FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
  });

  // Factory constructor to create a FriendRequest from a Firestore document
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      requestId: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      fromName: data['fromName'] ?? 'Unknown',
    );
  }
}

// Model: Represents a friend in the chat list
class Friend {
  final String username; // This is the friend's username
  final String name;
  final String lastMessage;
  final String lastTime;
  final bool isOnline;

  Friend({
    required this.username,
    required this.name,
    required this.lastMessage,
    required this.lastTime,
    this.isOnline = false,
  });

  // Factory constructor to create a Friend from a Firestore document
  factory Friend.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Friend(
      username: data['username'] ?? 'No Username',
      name: data['name'] ?? 'No Name',
      // lastMessage & lastTime would typically come from a separate 'chats' collection.
      // For now, we'll use placeholders.
      lastMessage: 'New friend! Say hi.',
      lastTime: '',
      // isOnline would typically be managed by a presence system (e.g., Realtime Database)
      isOnline: false,
    );
  }
}

// --- FIREBASE SERVICE (MODIFIED) ---
class FirebaseFriendsService {
  static final _firestore = FirebaseFirestore.instance;

  // MODIFIED: Fetches a user profile by their unique USERNAME
  static Future<Map<String, dynamic>?> fetchUserProfileByUsername(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // Include the document ID (Firebase UID) in the returned map
      return data;
    }
    return null; // User with that username not found
  }

  // Sends a friend request by creating a document in the 'friend_requests' collection
  static Future<bool> sendFriendRequest(String senderId, String receiverId, String senderName) async {
    // Prevent sending a request to oneself
    if (senderId == receiverId) return false;

    // 1. Check if they are already friends
    final friendDoc = await _firestore.collection('users').doc(senderId).collection('friends').doc(receiverId).get();
    if (friendDoc.exists) {
      debugPrint("Friendship already exists.");
      return false;
    }

    // 2. Check if a request already exists (either way)
    final existingRequest1 = await _firestore.collection('friend_requests')
        .where('fromUserId', isEqualTo: senderId)
        .where('toUserId', isEqualTo: receiverId)
        .limit(1).get();

    final existingRequest2 = await _firestore.collection('friend_requests')
        .where('fromUserId', isEqualTo: receiverId)
        .where('toUserId', isEqualTo: senderId)
        .limit(1).get();

    if (existingRequest1.docs.isNotEmpty || existingRequest2.docs.isNotEmpty) {
      debugPrint("Friend request already pending.");
      return false;
    }

    // 3. If no blockers, create the new request
    await _firestore.collection('friend_requests').add({
      'fromUserId': senderId,
      'toUserId': receiverId,
      'fromName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return true;
  }

  // Accepts a friend request using a batched write for atomicity
  static Future<void> acceptFriendRequest(FriendRequest request, String currentUserId) async {
    final batch = _firestore.batch();

    // Fetch full profiles to store relevant info
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final fromUserDoc = await _firestore.collection('users').doc(request.fromUserId).get();

    if (!currentUserDoc.exists || !fromUserDoc.exists) {
        throw Exception("Could not find user profiles to complete friendship.");
    }
    
    final currentUserData = currentUserDoc.data()!;
    final fromUserData = fromUserDoc.data()!;

    // 1. Add friend to current user's 'friends' subcollection
    final currentUserFriendRef = _firestore.collection('users').doc(currentUserId).collection('friends').doc(request.fromUserId);
    batch.set(currentUserFriendRef, {
      'name': fromUserData['name'] ?? 'No Name',
      'username': fromUserData['username'] ?? 'No Username',
      'profilePic': fromUserData['profilePic'] ?? '',
      'friendSince': FieldValue.serverTimestamp(),
    });

    // 2. Add current user to the other user's 'friends' subcollection
    final fromUserFriendRef = _firestore.collection('users').doc(request.fromUserId).collection('friends').doc(currentUserId);
    batch.set(fromUserFriendRef, {
      'name': currentUserData['name'] ?? 'No Name',
      'username': currentUserData['username'] ?? 'No Username',
      'profilePic': currentUserData['profilePic'] ?? '',
      'friendSince': FieldValue.serverTimestamp(),
    });

    // 3. Delete the friend request document
    final requestRef = _firestore.collection('friend_requests').doc(request.requestId);
    batch.delete(requestRef);

    await batch.commit();
  }

  // Deletes the friend request document from Firestore
  static Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }
}


// --- CHAT SCREEN (Functional Placeholder) ---

class ChatPage extends StatelessWidget {
  final Friend friend;

  const ChatPage({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friend.name),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Message List Placeholder
          Expanded(
            child: Center(
              child: Text(
                'This is the live chat room with ${friend.name} (@${friend.username}).\nStart sending messages!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ),
          // Input Field Placeholder
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      // **TODO: Implement message sending logic**
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- CHAT TAB MANAGER ---

class ChatTabManager extends StatefulWidget {
  final ValueNotifier<int> selectedChatTab;
  final String Function(DateTime) formatDateTime;
  final Color Function(String) getStatusColor;

  const ChatTabManager({
    super.key,
    required this.selectedChatTab,
    required this.formatDateTime,
    required this.getStatusColor,
  });

  @override
  State<ChatTabManager> createState() => _ChatTabManagerState();
}

class _ChatTabManagerState extends State<ChatTabManager> {
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  // Fetches the current user's info from FirebaseAuth and Firestore
  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      // Fetch profile from Firestore to get the user's name
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((snapshot) {
        if (mounted && snapshot.exists) {
          setState(() {
            _currentUserName = snapshot.data()?['name'] ?? 'User';
          });
        }
      });
    }
  }

  // --- Friend Request Logic ---

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    if (_currentUserId == null) return;
    try {
      await FirebaseFriendsService.acceptFriendRequest(request, _currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted ${request.fromName} as a friend!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request. Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectFriendRequest(FriendRequest request) async {
    try {
      await FirebaseFriendsService.rejectFriendRequest(request.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected request from ${request.fromName}.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request. Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UI Builder Methods ---

  Widget _buildFriendRequestItem(FriendRequest request) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.red.shade100,
            child: const Icon(Icons.person_add_alt, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Friend Request",
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
                Text(
                  request.fromName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Accept Button
          ElevatedButton(
            onPressed: () => _acceptFriendRequest(request),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(60, 30),
            ),
            child: const Text('Accept', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          // Reject Button
          TextButton(
            onPressed: () => _rejectFriendRequest(request),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(60, 30),
            ),
            child: const Text('Reject', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Friend friend) {
    return InkWell(
      onTap: () {
        // Navigate to the specific chat screen when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(friend: friend),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    friend.name.isNotEmpty ? friend.name[0] : '?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                // Online indicator
                if (friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${friend.username}', // Display username
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              friend.lastTime,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Friend Management Logic (MODIFIED) ---

  Future<void> _showAddFriendDialog(BuildContext context) async {
    final TextEditingController usernameController = TextEditingController(); // Renamed for clarity
    if (_currentUserId == null || _currentUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not loaded yet.')));
      return;
    }
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Friend by Username'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: "Enter Friend's Username",
              prefixText: "@",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_search),
            ),
            keyboardType: TextInputType.text,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Send Request'),
              onPressed: () async {
                final String receiverUsername = usernameController.text.trim();
                if (receiverUsername.isEmpty) return;
                
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Searching for user...')));

                // MODIFIED: Call the new service method to find user by username
                final Map<String, dynamic>? userProfile = await FirebaseFriendsService.fetchUserProfileByUsername(receiverUsername);
                
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                
                if (userProfile != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User found. Sending request...')));
                  
                  final bool success = await FirebaseFriendsService.sendFriendRequest(
                    _currentUserId!,
                    userProfile['id'], // 'id' contains the Firebase UID
                    _currentUserName!,
                  );

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent!'), backgroundColor: Colors.blue));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send: Already friends or request pending.'), backgroundColor: Colors.orange));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User with username "@$receiverUsername" not found.'), backgroundColor: Colors.red));
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Chat Tab Content Builder with FAB ---
  // This widget now uses StreamBuilders to listen for real-time Firebase data
  Widget _buildChatContent(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Use a CustomScrollView to combine different list types efficiently
        CustomScrollView(
          slivers: [
            // Sliver for Friend Requests Stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('friend_requests')
                  .where('toUserId', isEqualTo: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                final requests = snapshot.data!.docs
                    .map((doc) => FriendRequest.fromFirestore(doc))
                    .toList();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        // Header for the requests section
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text('Friend Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                               Divider(),
                            ],
                          )
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildFriendRequestItem(requests[index - 1]),
                      );
                    },
                    childCount: requests.length + 1,
                  ),
                );
              },
            ),

            // Sliver for Friends List Stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUserId)
                  .collection('friends')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text( "No friends yet.\nTap the button to add one.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                final friends = snapshot.data!.docs.map((doc) => Friend.fromFirestore(doc)).toList();
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Padding for the list
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildChatItem(friends[index]),
                      childCount: friends.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        // Floating Action Button (FAB) at bottom right
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddFriendDialog(context),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            child: const Icon(Icons.person_add, size: 28),
          ),
        ),
      ],
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 6),
          child: ValueListenableBuilder<int>(
            valueListenable: widget.selectedChatTab,
            builder: (context, selectedTab, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabItem(context, "Chat", 0, selectedTab),
                  const SizedBox(width: 40),
                  _buildTabItem(context, "History", 1, selectedTab),
                ],
              );
            },
          ),
        ),

        // Chat List / Call History Content
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: widget.selectedChatTab,
            builder: (context, selectedTab, _) {
              return selectedTab == 0
                  // Chat tab content with real-time data
                  ? _buildChatContent(context)
                  // Call History tab content
                  : _buildCallHistoryList();
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets (for Tabs and History) ---

  Widget _buildTabItem(BuildContext context, String title, int index, int selectedTab) {
    return GestureDetector(
      onTap: () => widget.selectedChatTab.value = index,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: selectedTab == index ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 35,
            height: 2,
            color: selectedTab == index ? Colors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // NOTE: This uses widget.formatDateTime and widget.getStatusColor
  Widget _buildCallHistoryList() {
    return ValueListenableBuilder<List<VideoCallHistory>>(
      valueListenable: videoCallHistory,
      builder: (context, historyList, _) {
        if (historyList.isEmpty) {
          return const Center(
            child: Text(
              "No call history available",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final call = historyList[index];
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: call.callType == 'emergency'
                      ? Colors.red.shade50
                      //: Colors.blue.shade50,
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: call.callType == 'emergency'
                            ? Colors.red
                            : Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        call.callType == 'emergency'
                            ? Icons.emergency
                            : Icons.videocam,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.participantName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.formatDateTime(call.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (call.duration != '0:00')
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Duration: ${call.duration}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.getStatusColor(call.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        call.status,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}