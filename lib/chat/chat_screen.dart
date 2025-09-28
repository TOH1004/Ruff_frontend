// File: lib/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friendmodel.dart'; // Import models

// --- ENHANCED CHAT SCREEN ---
class ChatScreen extends StatefulWidget {
  final Friend friend;

  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser!; 

  String _getChatId() {
    final currentUserId = user.uid;
    final friendUserId = widget.friend.userId;
    
    // Create consistent chat ID by sorting user IDs
    final sortedIds = [currentUserId, friendUserId]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

void _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;

  final chatId = _getChatId();
  
  try {
    final batch = FirebaseFirestore.instance.batch();
    
    // Add message to messages subcollection
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
        
    batch.set(messageRef, {
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Anonymous',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Use SET with merge instead of UPDATE for chat document
    // This will create the document if it doesn't exist
    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId);
        
    batch.set(chatRef, {
      'members': [user.uid, widget.friend.userId], // Ensure members array is set
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': user.uid,
      'createdAt': FieldValue.serverTimestamp(), // Add createdAt if creating new
    }, SetOptions(merge: true)); // Use merge to update existing fields without overwriting

    await batch.commit();
    _messageController.clear();
    
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  } catch (e) {
    print('🔍 [DEBUG] Error sending message: $e');
    print('🔍 [DEBUG] Chat ID: $chatId');
    print('🔍 [DEBUG] Current user: ${user.uid}');
    print('🔍 [DEBUG] Friend user: ${widget.friend.userId}');
    
    if (mounted) {
      String errorMessage = 'Failed to send message';
      
      if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Permission denied. The chat may not be properly set up.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Debug',
            textColor: Colors.white,
            onPressed: () {
              _debugChatPermissions();
            },
          ),
        ),
      );
    }
  }
}

// Add this debug method to your _ChatScreenState class
Future<void> _debugChatPermissions() async {
  final chatId = _getChatId();
  
  try {
    print('🔍 [DEBUG] === CHAT DEBUG ===');
    print('🔍 [DEBUG] Chat ID: $chatId');
    print('🔍 [DEBUG] Current user: ${user.uid}');
    print('🔍 [DEBUG] Friend user: ${widget.friend.userId}');
    
    // Try to read the chat document
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        print('🔍 [DEBUG] Chat exists: ${chatDoc.data()}');
        final data = chatDoc.data()!;
        final members = data['members'] as List<dynamic>?;
        print('🔍 [DEBUG] Members: $members');
        print('🔍 [DEBUG] Current user in members: ${members?.contains(user.uid)}');
        print('🔍 [DEBUG] Friend in members: ${members?.contains(widget.friend.userId)}');
      } else {
        print('🔍 [DEBUG] Chat document does not exist');
        
        // Try to create the chat document
        print('🔍 [DEBUG] Attempting to create chat document...');
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set({
          'members': [user.uid, widget.friend.userId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': null,
          'lastMessageSender': '',
        });
        print('🔍 [DEBUG] Chat document created successfully');
      }
    } catch (e) {
      print('🔍 [DEBUG] Error accessing chat: $e');
    }
    
    // Check if both users exist
    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      print('🔍 [DEBUG] Current user exists: ${currentUserDoc.exists}');
      
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friend.userId)
          .get();
      print('🔍 [DEBUG] Friend exists: ${friendDoc.exists}');
    } catch (e) {
      print('🔍 [DEBUG] Error checking user documents: $e');
    }
    
    print('🔍 [DEBUG] === END CHAT DEBUG ===');
  } catch (e) {
    print('🔍 [DEBUG] Error in debug method: $e');
  }
}


  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
  Widget build(BuildContext context) {
    final chatId = _getChatId();

    return Scaffold(

      appBar: AppBar(
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.friend.name),
      Text(
        '@${widget.friend.username}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),
    ],
  ),
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
  elevation: 0,
  actions: [
    // Add this debug button temporarily
    IconButton(
      icon: const Icon(Icons.bug_report),
      onPressed: _debugChatPermissions,
      tooltip: 'Debug Chat',
    ),
  ],
),

      
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation with ${widget.friend.name}!',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == user.uid;
                    final text = messageData['text'] ?? '';
                    final timestamp = messageData['timestamp'] as Timestamp?;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            if (timestamp != null)
                              Text(
                                _formatTime(timestamp.toDate()),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
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
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
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