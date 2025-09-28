// File: lib/firebase_journey_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JourneyData {
  final String journeyId;
  final String userId;
  final String name;
  final String profilePic;
  final DateTime startTime;
  final bool isActive;

  JourneyData({
    required this.journeyId,
    required this.userId,
    required this.name,
    required this.profilePic,
    required this.startTime,
    this.isActive = true,
  });

  factory JourneyData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JourneyData(
      journeyId: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unknown',
      profilePic: data['profilePic'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'profilePic': profilePic,
      'startTime': Timestamp.fromDate(startTime),
      'isActive': isActive,
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(startTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inDays} days';
    }
  }
}

class FirebaseJourneyService {
  static final _firestore = FirebaseFirestore.instance;

  // Start a new journey
  static Future<String?> startJourney() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('ðŸ” [DEBUG] No current user found');
        return null;
      }

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('ðŸ” [DEBUG] User document does not exist');
        return null;
      }

      final userData = userDoc.data()!;
      final name = userData['name'] ?? userData['username'] ?? 'Unknown User';
      final profilePic = userData['profilePic'] ?? '';

      // Check if user already has an active journey
      final existingJourneys = await _firestore
          .collection('journeys')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      // End existing active journeys
      for (var doc in existingJourneys.docs) {
        await doc.reference.update({'isActive': false});
      }

      // Create new journey
      final journeyData = JourneyData(
        journeyId: '',
        userId: user.uid,
        name: name,
        profilePic: profilePic,
        startTime: DateTime.now(),
      );

      final docRef = await _firestore.collection('journeys').add(journeyData.toFirestore());
      
      print('ðŸ” [DEBUG] Journey started with ID: ${docRef.id}');
      return docRef.id;

    } catch (e) {
      print('ðŸ” [DEBUG] Error starting journey: $e');
      return null;
    }
  }

  // End a journey
  static Future<bool> endJourney(String journeyId) async {
    try {
      await _firestore.collection('journeys').doc(journeyId).update({
        'isActive': false,
        'endTime': FieldValue.serverTimestamp(),
      });
      
      print('ðŸ” [DEBUG] Journey ended: $journeyId');
      return true;
    } catch (e) {
      print('ðŸ” [DEBUG] Error ending journey: $e');
      return false;
    }
  }

  // Get active journeys from friends
  static Stream<List<JourneyData>> getFriendsActiveJourneys(String userId) {
    return _firestore
        .collection('friends')
        .where('user1', isEqualTo: userId)
        .snapshots()
        .asyncMap((friendsSnapshot1) async {
      
      try {
        List<String> friendIds = [];
        
        // Get friends where current user is user1
        for (var doc in friendsSnapshot1.docs) {
          final data = doc.data();
          final friendId = data['user2'];
          if (friendId != null && friendId.isNotEmpty) {
            friendIds.add(friendId);
          }
        }

        // Get friends where current user is user2
        try {
          final friendsSnapshot2 = await _firestore
              .collection('friends')
              .where('user2', isEqualTo: userId)
              .get();
          
          for (var doc in friendsSnapshot2.docs) {
            final data = doc.data();
            final friendId = data['user1'];
            if (friendId != null && friendId.isNotEmpty) {
              friendIds.add(friendId);
            }
          }
        } catch (e) {
          print('ðŸ” [DEBUG] Error getting friends where user2 = $userId: $e');
        }

        if (friendIds.isEmpty) {
          print('ðŸ” [DEBUG] No friends found for user: $userId');
          return <JourneyData>[];
        }

        print('ðŸ” [DEBUG] Found ${friendIds.length} friends: $friendIds');

        // Get active journeys from friends
        List<JourneyData> allJourneys = [];
        
        // Process friends in batches of 10 (Firestore whereIn limit)
        for (int i = 0; i < friendIds.length; i += 10) {
          final batch = friendIds.skip(i).take(10).toList();
          
          try {
            final journeysSnapshot = await _firestore
                .collection('journeys')
                .where('userId', whereIn: batch)
                .where('isActive', isEqualTo: true)
                .orderBy('startTime', descending: true)
                .get();

            print('ðŸ” [DEBUG] Found ${journeysSnapshot.docs.length} journeys for batch: $batch');

            for (var doc in journeysSnapshot.docs) {
              try {
                allJourneys.add(JourneyData.fromFirestore(doc));
              } catch (e) {
                print('ðŸ” [DEBUG] Error parsing journey document ${doc.id}: $e');
                continue;
              }
            }
          } catch (e) {
            print('ðŸ” [DEBUG] Error querying journeys for batch $batch: $e');
            continue;
          }
        }

        // Sort by start time (most recent first) and filter recent journeys
        allJourneys.sort((a, b) => b.startTime.compareTo(a.startTime));
        
        // Filter journeys that are less than 24 hours old
        final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
        allJourneys = allJourneys.where((journey) => journey.startTime.isAfter(oneDayAgo)).toList();
        
        print('ðŸ” [DEBUG] Returning ${allJourneys.length} active journeys');
        return allJourneys;

      } catch (e) {
        print('ðŸ” [DEBUG] Error in getFriendsActiveJourneys: $e');
        return <JourneyData>[];
      }
    }).handleError((error) {
      print('ðŸ” [DEBUG] Stream error in getFriendsActiveJourneys: $error');
      return <JourneyData>[];
    });
  }

  // Get user's current active journey
  static Future<JourneyData?> getCurrentUserJourney(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('journeys')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return JourneyData.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('ðŸ” [DEBUG] Error getting current user journey: $e');
      return null;
    }
  }

  // Clean up old journeys (call this periodically)
  static Future<void> cleanupOldJourneys() async {
    try {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      
      final oldJourneys = await _firestore
          .collection('journeys')
          .where('startTime', isLessThan: Timestamp.fromDate(threeDaysAgo))
          .get();

      final batch = _firestore.batch();
      
      for (var doc in oldJourneys.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      print('ðŸ” [DEBUG] Cleaned up ${oldJourneys.docs.length} old journeys');
    } catch (e) {
      print('ðŸ” [DEBUG] Error cleaning up old journeys: $e');
    }
  }
}