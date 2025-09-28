// File: lib/home_sections/chat_tab_manager.dart

import '../videocall/videocall_data.dart'; // This import is necessary for VideoCallHistory
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friendmodel.dart'; // Import models
import 'firebase_friends_service.dart'; // Import service
import 'chat_screen.dart'; // Import ChatScreen

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

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

// Update the _getCurrentUser method in your chat_tab_manager.dart

void _getCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    _currentUserId = user.uid;
    if (mounted) setState(() {});
    
    // Initialize chats for this user to fix any missing chat documents
    await FirebaseFriendsService.initializeChatsForUser(user.uid);
  }
}

  // Updated _showAddFriendDialog method
  Future<void> _showAddFriendDialog(BuildContext context) async {
    if (_currentUserId == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not loaded yet. Please wait and try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController usernameController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            
            return AlertDialog(
              title: const Text('Add Friend by Username'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: "Enter Friend's Username",
                      prefixText: "@",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_search),
                      helperText: "Enter username without @",
                    ),
                    enabled: !isLoading,
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Sending request...'),
                      ],
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Send Request'),
                  onPressed: isLoading ? null : () async {
                    final username = usernameController.text.trim();
                    if (username.isEmpty) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a username'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    setState(() => isLoading = true);
                    
                    final result = await FirebaseFriendsService.sendFriendRequest(username);
                    
                    setState(() => isLoading = false);
                    // ignore: use_build_context_synchronously
                    Navigator.of(dialogContext).pop();
                    
                    // Handle different result cases
                    // ignore: use_build_context_synchronously
                    switch (result) {
                      case 'success':
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Friend request sent to @$username!'),
                            backgroundColor: Colors.green,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                        break;
                        
                      case 'error_user_not_found':
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User @$username not found. Check the spelling and try again.'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        break;
                        
                      case 'error_self_add':
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("You can't add yourself as a friend!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        break;
                        
                      case 'error_already_friends':
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You are already friends with @$username'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                        break;
                        
                      case 'error_request_exists':
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Friend request with @$username already exists'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        break;
                        
                      case 'error_no_username':
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Your profile is missing a username. Please update your profile first.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        break;
                        
                      case 'error_exception':
                      default:
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Something went wrong. Please check your internet connection and try again.'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 4),
                          ),
                        );
                        break;
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildFriendRequestItem(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
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
                  style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${request.fromUserName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  _formatTime(request.timestamp.toDate()),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: 70,
                height: 32,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await FirebaseFriendsService.acceptFriendRequest(request.requestId);
                    if (success) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Accepted @${request.fromUserName} as a friend!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                height: 28,
                child: TextButton(
                  onPressed: () async {
                    final success = await FirebaseFriendsService.rejectFriendRequest(request.requestId);
                    if (success) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rejected @${request.fromUserName}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Friend friend) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(friend: friend),
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${friend.username}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.grey),
                  ),
                  if (friend.lastMessage.isNotEmpty)
                    Text(
                      friend.lastMessage,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (friend.lastTime.isNotEmpty)
              Text(
                friend.lastTime,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedChatContent(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Friend Requests Section
            StreamBuilder<List<FriendRequest>>(
              stream: FirebaseFriendsService.getPendingFriendRequests(_currentUserId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                final requests = snapshot.data!;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.notifications_active, 
                                       color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Friend Requests (${requests.length})',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }
                        return _buildFriendRequestItem(requests[index - 1]);
                      },
                      childCount: requests.length + 1,
                    ),
                  ),
                );
              },
            ),

            // Divider between requests and chats (only shows if there are requests)
            StreamBuilder<List<FriendRequest>>(
              stream: FirebaseFriendsService.getPendingFriendRequests(_currentUserId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Divider(thickness: 1, color: Colors.grey),
                  ),
                );
              },
            ),

            // Chats Section Header
            StreamBuilder<List<Friend>>(
              stream: FirebaseFriendsService.getUserFriends(_currentUserId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.chat, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Chats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Friends List (updated to use new service)
            StreamBuilder<List<Friend>>(
              stream: FirebaseFriendsService.getUserFriends(_currentUserId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, 
                                 size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              "No friends yet.\nTap the + button to add one.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final friends = snapshot.data!;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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

        // Floating Action Button (unchanged)
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

  Widget _buildCallHistoryList() {
    // NOTE: This assumes videoCallHistory is a globally or externally defined ValueNotifier<List<VideoCallHistory>>
    // as it was in the original monolithic file.
    return ValueListenableBuilder<List<VideoCallHistory>>(
      valueListenable: videoCallHistory,
      builder: (context, historyList, _) {
        if (historyList.isEmpty) {
          return const Center(
            child: Text("No call history available", style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: historyList.length,
          itemBuilder: (context, index) {
            final call = historyList[index];
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: call.callType == 'emergency' ? Colors.red.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: call.callType == 'emergency' ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      call.callType == 'emergency' ? Icons.emergency : Icons.videocam,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(call.participantName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(widget.formatDateTime(call.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        if (call.duration != '0:00')
                          Row(
                            children: [
                              Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('Duration: ${call.duration}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.getStatusColor(call.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      call.status,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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

        // Content
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: widget.selectedChatTab,
            builder: (context, selectedTab, _) {
              return selectedTab == 0
                  ? _buildUnifiedChatContent(context)
                  : _buildCallHistoryList();
            },
          ),
        ),
      ],
    );
  }
}