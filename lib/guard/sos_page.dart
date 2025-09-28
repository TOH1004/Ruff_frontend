// File: lib/sos_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ensure FirebaseAuth is imported


class SosPage extends StatelessWidget {
  const SosPage({super.key});

  // Function to force token refresh (important for checking 'guard' role)
  Future<void> _ensureTokenIsFresh() async {
    // Calling getIdTokenResult(true) forces the client to refresh the token 
    // from the server, picking up any new custom claims (like 'role: guard').
    await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3075FF);
    const pageBg = Color(0xFFF4F5F7);

    // MODIFICATION: Change 'status' filter to 'active' and 'orderBy' to 'timestamp'
    final q = FirebaseFirestore.instance
        .collection('sos_requests')
        .where('status', isEqualTo: 'active') 
        .orderBy('timestamp', descending: true); // Use 'timestamp' field

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Active SOS Requests',
          style: GoogleFonts.bangers(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder(
        future: _ensureTokenIsFresh(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot>(
            stream: q.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No active SOS requests at the moment. Stay safe!',
                    style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final sosId = docs[index].id;
                  
                  // Use new fields from sample data
                  final userName = data['userName'] ?? 'User ID: ${data['userId'] ?? 'N/A'}';
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  final additionalInfo = data['additionalInfo'] ?? 'No details provided.';
                  final lat = data['latitude'] as double?;
                  final lon = data['longitude'] as double?;

                  return _buildSosCard(
                    context, 
                    sosId, 
                    userName, 
                    timestamp, 
                    additionalInfo, 
                    lat, 
                    lon
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
  
  // Helper to format time
  String _formatTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Helper to build the SOS request card
  Widget _buildSosCard(
    BuildContext context,
    String sosId,
    String userName,
    DateTime timestamp,
    String additionalInfo,
    double? lat,
    double? lon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3075FF),
                  ),
                ),
                Text(
                  _formatTime(timestamp),
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Divider(height: 15, color: Colors.grey),
            Text(
              additionalInfo,
              style: GoogleFonts.lato(fontSize: 15, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_pin, color: Colors.red, size: 18),
                const SizedBox(width: 4),
                Text(
                  lat != null && lon != null ? 'Location Available (${lat!.toStringAsFixed(2)}, ${lon!.toStringAsFixed(2)})' : 'Location Unavailable',
                  style: GoogleFonts.lato(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Guard action: Attempt to accept the SOS request
                  _handleAcceptSos(context, sosId);
                },
                icon: const Icon(Icons.security, color: Colors.white),
                label: const Text('Accept and Respond', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAcceptSos(BuildContext context, String sosId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attempting to accept SOS...')),
    );

    final error = await acceptSOS(sosId);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS $sosId accepted successfully!')),
      );
      // Success: Optionally navigate to a map/tracking screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept SOS: $error')),
      );
    }
  }

}

/* ======================= Functions integration ======================= */

Future<String?> acceptSOS(String sosId) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('acceptSOS');
    final res = await callable.call({'sosId': sosId});
    final ok = (res.data is Map && (res.data['ok'] == true)) || (res.data == true);
    return ok ? null : 'Unknown error';
  } on FirebaseFunctionsException catch (e) {
    switch (e.code) {
      case 'failed-precondition':
        return "Another guard already accepted, or you're not on duty.";
      case 'permission-denied':
        return "Only guards can accept.";
      case 'not-found':
        return "SOS not found.";
      default:
        return e.message;
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF3075FF);
    const inactive = Colors.grey;

    Widget item(IconData icon, String label, bool isActive) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? active : inactive),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? active : inactive, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          item(Icons.home, 'Home', true),
          item(Icons.settings, 'Settings', false),
          item(Icons.person, 'Profile', false),
        ],
      ),
    );
  }
}