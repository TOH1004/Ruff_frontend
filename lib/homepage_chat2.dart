import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aibuddy.dart';
import 'reportspage.dart'; // Updated import
import 'videocall_data.dart'; // New import for video call history
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ruff/videocall.dart'; // Import the enhanced video call page
import 'report.dart'; // Import the Report model and history

class RuffAppScreen extends StatelessWidget {
  RuffAppScreen({super.key});

  final ValueNotifier<int> _selectedChatTab = ValueNotifier<int>(0);

  Widget _buildActionCardAsset({
    required String assetPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 110,
        height: 100,
        margin: const EdgeInsets.only(top: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath.isNotEmpty)
              Image.asset(
                assetPath,
                width: 77,
                height: 77,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show video call options
  void _showVideoCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Start Video Call',
              style: GoogleFonts.climateCrisis(
                fontSize: 24,
                color: const Color(0xFF3075FF),
              ),
            ),
            const SizedBox(height: 20),
            
            // Description
            const Text(
              'Connect with emergency responders or get help from nearby users.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            
            // Emergency Call Button
            Container(
              width: double.infinity,
              height: 60,
              margin: const EdgeInsets.only(bottom: 15),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _startEmergencyCall(context);
                },
                icon: const Icon(Icons.emergency, color: Colors.white),
                label: const Text(
                  'Emergency Call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            
            // Regular Call Button
            Container(
              width: double.infinity,
              height: 60,
              margin: const EdgeInsets.only(bottom: 15),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _startRegularCall(context);
                },
                icon: const Icon(Icons.videocam, color: Colors.white),
                label: const Text(
                  'Video Call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3075FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            
            // Cancel Button
            Container(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _startEmergencyCall(BuildContext context) {
    // Show loading indicator first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text('Connecting to emergency services...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate delay then navigate
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog
      
      // Add to video call history
      _addToVideoCallHistory('Emergency Services', 'emergency');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallPermissionWrapper(
            onPermissionDenied: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera and microphone permissions are required for emergency calls.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const VideoCallPage(),
          ),
        ),
      );
    });
  }

  void _startRegularCall(BuildContext context) {
    // Add to video call history
    _addToVideoCallHistory('Campus Security', 'regular');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallPermissionWrapper(
          onPermissionDenied: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera and microphone permissions are required for video calls.'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          child: const VideoCallPage(),
        ),
      ),
    );
  }

  void _addToVideoCallHistory(String participantName, String callType) {
    final newCall = VideoCallHistory(
      participantName: participantName,
      callType: callType,
      timestamp: DateTime.now(),
      duration: '0:00', // Will be updated when call ends
      status: 'started',
    );
    
    List<VideoCallHistory> updatedList = List.from(videoCallHistory.value);
    updatedList.insert(0, newCall); // Add to beginning of list
    videoCallHistory.value = updatedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3075FF),
      body: SafeArea(
        child: Column(
          children: [
            // Main Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Hero Section with Dog
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3075FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 20,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Dog image
                            Container(
                              width: 216,
                              height: 200,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3075FF),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: Image.asset(
                                  "assets/hellodog.png",
                                  width: 213,
                                  height: 200,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Text and button
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "RUFF",
                                    style: GoogleFonts.climateCrisis(
                                      fontSize: 35,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "will take you home",
                                    style: TextStyle(
                                      fontFamily: 'TiltWarp',
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  InkWell(
                                    onTap: () {
                                      // Show video call options instead of directly navigating
                                      _showVideoCallOptions(context);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        "Start Now",
                                        style: TextStyle(
                                          fontFamily: 'TiltWarp',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Cards with background box
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Transform.translate(
                        offset: const Offset(0, -50),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionCardAsset(
                                assetPath: 'assets/status.png',
                                label: 'Status',
                                onTap: () {
                                  // TODO: show status page
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Status page coming soon!')),
                                  );
                                },
                              ),
                              _buildActionCardAsset(
                                assetPath: 'assets/aibuddy.png',
                                label: 'AI Buddy',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AIBuddyPage(),
                                    ),
                                  );
                                },
                              ),
                              _buildActionCardAsset(
                                assetPath: 'assets/report.png',
                                label: 'Reports', // Changed from 'Report' to 'Reports'
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ReportsPage(), // Navigate to new ReportsPage
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Journey Cards
                    Transform.translate(
                      offset: const Offset(0, -25),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildJourneyCard(
                                "Joe, Lim & ...",
                                "journey started 3 min",
                                "🌻",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildJourneyCard(
                                "Michelle",
                                "journey started 8 min",
                                "👩",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Chat section - Expanded to take remaining space
                    Expanded(
                      child: Column(
                        children: [
                          // Chat / Call History tab
                          Padding(
                            padding: const EdgeInsets.only(top: 0, bottom: 6),
                            child: ValueListenableBuilder<int>(
                              valueListenable: _selectedChatTab,
                              builder: (context, selectedTab, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _selectedChatTab.value = 0,
                                      child: Column(
                                        children: [
                                          Text(
                                            "Chat",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: selectedTab == 0
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 35,
                                            height: 2,
                                            color: selectedTab == 0
                                                ? Colors.blue
                                                : Colors.transparent,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                    GestureDetector(
                                      onTap: () => _selectedChatTab.value = 1,
                                      child: Column(
                                        children: [
                                          Text(
                                            "History", // Changed from "History" to "Call History"
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: selectedTab == 1
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 35,
                                            height: 2,
                                            color: selectedTab == 1
                                                ? Colors.blue
                                                : Colors.transparent,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Chat List / Call History - Now properly scrollable
                          Expanded(
                            child: ValueListenableBuilder<int>(
                              valueListenable: _selectedChatTab,
                              builder: (context, selectedTab, _) {
                                return selectedTab == 0
                                    // Chat tab
                                    ? ListView(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        children: [
                                          _buildChatItem("Alex", "Bye see u later", "8:27 pm", true),
                                          _buildChatItem("Emma", "Bye see u later", "8/29", false),
                                          _buildChatItem("Felicia", "Bye see u later", "8/26", true),
                                        ],
                                      )
                                    // Call History tab - Now shows video call history
                                    : ValueListenableBuilder<List<VideoCallHistory>>(
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
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10,
                                              ),
                                              itemCount: historyList.length,
                                              itemBuilder: (context, index) {
                                                final call = historyList[index];
                                                return Container(
                                                  padding: const EdgeInsets.all(12),
                                                  margin: const EdgeInsets.only(bottom: 10),
                                                  decoration: BoxDecoration(
                                                    color: call.callType == 'emergency' 
                                                        ? Colors.red.shade50 
                                                        : Colors.blue.shade50,
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
                                                      // Call type icon
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
                                                      
                                                      // Call details
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
                                                                  _formatDateTime(call.timestamp),
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
                                                      
                                                      // Status indicator
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: _getStatusColor(call.status),
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
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home button (already active)
                  GestureDetector(
                    onTap: () {
                      // TODO: Add navigation logic if needed
                    },
                    child: _buildBottomNavItem(Icons.home, "Home", true),
                  ),

                  // Settings button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings page coming soon!')),
                      );
                    },
                    child: _buildBottomNavItem(Icons.settings, "Settings", false),
                  ),

                  // Profile button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile page coming soon!')),
                      );
                    },
                    child: _buildBottomNavItem(Icons.person, "Profile", false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      case 'started':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionCard(String emoji, String title) {
    return Container(
      width: 72,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(String name, String subtitle, String emoji) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(
                  emoji,
                  style: const TextStyle(fontFamily: 'SF Pro', fontSize: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name on top
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtitle + Join button in a row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            print('Join pressed for $name');
                            // You can integrate video call here too if needed
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              "Join",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    String name,
    String message,
    String time,
    bool isOnline,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[300],
            child: Text(
              name[0],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
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
            time,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }
}