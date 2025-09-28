// File: lib/home_sections/chat_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_tab_manager.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final ValueNotifier<int> _selectedChatTab = ValueNotifier<int>(0);

  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(messageDate).inDays == 1) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'emergency':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatTabManager(
      selectedChatTab: _selectedChatTab,
      formatDateTime: formatDateTime,
      getStatusColor: getStatusColor,
    );
  }

  @override
  void dispose() {
    _selectedChatTab.dispose();
    super.dispose();
  }

Future<void> createChat(String user1Uid, String user2Uid) async {
  try {
    final chatCollection = FirebaseFirestore.instance.collection('chats');

    // Check if a chat already exists between these two users
    final existingChat = await chatCollection
        .where('members', arrayContainsAny: [user1Uid, user2Uid])
        .get();

    bool chatExists = existingChat.docs.any((doc) {
      List members = doc['members'];
      return members.contains(user1Uid) && members.contains(user2Uid);
    });

    if (chatExists) {
      print('Chat already exists');
      return;
    }

    // Create new chat
    await chatCollection.add({
      'members': [user1Uid, user2Uid], // Array of the two users
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null, // Optional: for showing recent message preview
    });

    print('Chat created successfully!');
  } catch (e) {
    print('Error creating chat: $e');
  }
}

}