// File: lib/ruff_app_screen.dart (The main entry screen)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// NOTE: Added conceptual Firebase imports
// import 'package:cloud_firestore/cloud_firestore.dart'; 
// import 'package:firebase_auth/firebase_auth.dart'; 
import '../testmap.dart'; 
// Component Imports
import 'hero_section.dart';
import 'action_cards_section.dart';
import 'journey_cards_section.dart';
import '../chat/chat_tab_manager.dart';
import 'journey_firebase.dart';
// Utility/Logic Imports (Keep necessary imports for functionality)
import '../videocall/videocall_data.dart';
import '../videocall/videocall.dart';
import '../videocall/wrapper.dart';
import '../profile.dart';
import '../guard/(guard)homepage_chat2.dart';

// NOTE: Placeholder class for Location and Firebase functionality
class UserLocation {
  // Hardcoded coordinates based on the image's existing record for demonstration
  final double latitude = 1.8640332; 
  final double longitude = 103.1141714; 
}

class RuffAppScreen extends StatelessWidget {
  RuffAppScreen({super.key});

  final ValueNotifier<int> _selectedChatTab = ValueNotifier<int>(0);

  // --- Logic for 'Ruff will take you home' (Video Call Starter) ---

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start Video Call',
              style: GoogleFonts.bangers(
                fontSize: 24,
                color: const Color(0xFF3075FF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connect with emergency responders or get help from nearby users.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
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

  // --- NEW: Firebase SOS Trigger Function ---
  Future<void> _triggerSosRequest(BuildContext context) async {
    // This function performs the Firebase write to 'sos_requests'
    // It mirrors the structure of the existing document in the image.
    try {
      // 1. Get current user info (Conceptual)
      // final user = FirebaseAuth.instance.currentUser;
      // final userId = user?.uid ?? 'unknown_user_id';
      // final userEmail = user?.email ?? 'unknown@email.com';
      
      // Hardcoded data based on the image for demonstration
      const userId = 'YULfb4OS68WNQSX6ZgZ4AQv0h0h1'; 
      const userEmail = 'tsthong4@gmail.com'; 
      const userName = null; 

      // 2. Get current location (Conceptual)
      final location = UserLocation(); 

      final sosData = {
        'additionalInfo': 'Emergency triggered during video call',
        'hasAttachments': false,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'status': 'Active',
        // 'timestamp': FieldValue.serverTimestamp(), // Use server timestamp when connected to Firebase
        'timestamp': DateTime.now().toIso8601String(), // Placeholder without Firebase SDK
        'userEmail': userEmail,
        'userId': userId,
        'userName': userName,
      };

      // 3. Write to Firebase (Conceptual line)
      // await FirebaseFirestore.instance.collection('sos_requests').add(sosData);
      
      print('SOS Request Triggered: $sosData'); 

    } catch (e) {
      print('Error triggering SOS: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger SOS (Error: $e)')),
        );
      }
    }
  }
  // --- END: Firebase SOS Trigger Function ---

  void _startEmergencyCall(BuildContext context) {
    // Show a connecting dialog 
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

    // 1. Trigger the Firebase SOS request first
    _triggerSosRequest(context).then((_) {
      // 2. Delay and proceed to call screen
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Navigator.pop(context); // Close connecting dialog
        }

        // 3. Add to history and start call. Added userId.
        _addToVideoCallHistory('Emergency Services', 'emergency', userId: 'emergency_sos_id'); 

        if (context.mounted) {
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
        }
      });
    });
  }

  void _startRegularCall(BuildContext context) {
    // Added userId for history link
    _addToVideoCallHistory('You\'ve started your journey', 'regular', userId: 'campus_security_id');
    
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

  // Modified to accept an optional userId parameter
  void _addToVideoCallHistory(String participantName, String callType, {String? userId}) {
    final newCall = VideoCallHistory(
      participantName: participantName,
      callType: callType,
      timestamp: DateTime.now(),
      duration: '0:00', // Will be updated when call ends
      status: 'started',
      // participantId: userId, // ASSUMING VideoCallHistory model supports this
    );
    
    List<VideoCallHistory> updatedList = List.from(videoCallHistory.value);
    updatedList.insert(0, newCall); // Add to beginning of list
    videoCallHistory.value = updatedList;
  }

  // --- Utility Methods (Required by ChatTabManager) ---

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
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

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3075FF),
      body: SafeArea(
        child: Column(
          children: [
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
                    // 1. Ruff will take you home (Hero Section)
                    HeroSection(
                      onStartNow: () => _showVideoCallOptions(context),
                    ),

                    // 2. Action Cards
                    const ActionCardsSection(),

                    // 3. Journey Joined
                    const JourneyCardsSection(),

                    // 4. Chat / Call History Tab Section
                    Expanded(
                      child: ChatTabManager(
                        selectedChatTab: _selectedChatTab,
                        formatDateTime: _formatDateTime,
                        getStatusColor: _getStatusColor,
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
                  GestureDetector(
                    onTap: () {},
                    child: _buildBottomNavItem(Icons.home, "Home", true),
                  ),
                  GestureDetector(
                    onTap: () {
                    },
                    child: _buildBottomNavItem(Icons.settings, "Settings", false),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
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
}