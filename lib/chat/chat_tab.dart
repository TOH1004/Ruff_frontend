import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _friendIdController = TextEditingController();

  Future<void> _addFriend() async {
    final friendId = _friendIdController.text.trim();
    if (friendId.isEmpty) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final friendRef = FirebaseFirestore.instance.collection('users').doc(friendId);

    final friendDoc = await friendRef.get();
    if (!friendDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend not found")),
      );
      return;
    }

    await userRef.update({
      "friends.$friendId": true,
    });

    await friendRef.update({
      "friends.${user.uid}": true,
    });

    _friendIdController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔹 Add friend button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _friendIdController,
                  decoration: const InputDecoration(
                    labelText: "Enter Friend's UserID",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: _addFriend,
              ),
            ],
          ),
        ),

        // 🔹 Friends List
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final friends = (data["friends"] ?? {}) as Map<String, dynamic>;

              if (friends.isEmpty) {
                return const Center(child: Text("No friends yet. Add some!"));
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: friends.keys.map((friendId) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection("users").doc(friendId).get(),
                    builder: (context, friendSnapshot) {
                      if (!friendSnapshot.hasData) return const SizedBox();
                      final friendData = friendSnapshot.data!.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(friendData["name"] ?? "Unknown"),
                        subtitle: Text(friendId),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(friendId: friendId, friendName: friendData["name"]),
                            ),
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
