import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../status/status_data.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String statusCollection = 'statuses';
  static const String usersCollection = 'users';

  /// Upload status to Firebase
  static Future<bool> uploadStatus({
    required String issueText,
    required List<File> images,
    required String location,
    required List<String> selectedFriends,
    required String visibility, // 'Friends', 'Community', 'Public'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload images first
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        String imageUrl = await _uploadImage(images[i], user.uid, i);
        imageUrls.add(imageUrl);
      }

      // Get user info
      DocumentSnapshot userDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

      // Create status document
      Map<String, dynamic> statusData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': user.uid,
        'userName': userData['name'] ?? user.displayName ?? 'Anonymous',
        'userEmail': user.email,
        'issueText': issueText,
        'imageUrls': imageUrls,
        'imagePaths': [], // Keep empty for Firebase version
        'location': location,
        'mentionedFriends': selectedFriends,
        'visibility': visibility,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'likes': [],
        'comments': [],
        'isActive': true,
      };

      // Add to Firestore
      await _firestore.collection(statusCollection).add(statusData);

      print('Status uploaded successfully to Firebase');
      return true;
    } catch (e) {
      print('Error uploading status: $e');
      return false;
    }
  }

  /// Upload single image to Firebase Storage
  static Future<String> _uploadImage(File image, String userId, int index) async {
    try {
      String fileName = 'status_${userId}_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
      Reference ref = _storage.ref().child('status_images/$userId/$fileName');
      
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Get all statuses (real-time stream)
  static Stream<List<Status>> getStatusesStream() {
    return _firestore
        .collection(statusCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return Status(
          id: data['id'] ?? doc.id,
          issueText: data['issueText'] ?? '',
          imagePaths: List<String>.from(data['imageUrls'] ?? []), // Use imageUrls for display
          location: data['location'] ?? '',
          timestamp: data['createdAt'] != null 
              ? DateTime.parse(data['createdAt']) 
              : DateTime.now(),
        );
      }).toList();
    });
  }

  /// Get statuses for specific user
  static Stream<List<Status>> getUserStatusesStream(String userId) {
    return _firestore
        .collection(statusCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return Status(
          id: data['id'] ?? doc.id,
          issueText: data['issueText'] ?? '',
          imagePaths: List<String>.from(data['imageUrls'] ?? []),
          location: data['location'] ?? '',
          timestamp: data['createdAt'] != null 
              ? DateTime.parse(data['createdAt']) 
              : DateTime.now(),
        );
      }).toList();
    });
  }

  /// Delete status
  static Future<bool> deleteStatus(String statusId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get the status document
      QuerySnapshot query = await _firestore
          .collection(statusCollection)
          .where('id', isEqualTo: statusId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (query.docs.isEmpty) return false;

      // Mark as inactive instead of deleting (soft delete)
      await query.docs.first.reference.update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      print('Status deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting status: $e');
      return false;
    }
  }

  /// Initialize user document
  static Future<void> initializeUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      DocumentSnapshot userDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection(usersCollection).doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'Anonymous',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'statusCount': 0,
        });
      } else {
        // Update last active
        await _firestore.collection(usersCollection).doc(user.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing user: $e');
    }
  }

  /// Search statuses
  static Future<List<Status>> searchStatuses(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(statusCollection)
          .where('isActive', isEqualTo: true)
          .get();

      List<Status> allStatuses = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Status(
          id: data['id'] ?? doc.id,
          issueText: data['issueText'] ?? '',
          imagePaths: List<String>.from(data['imageUrls'] ?? []),
          location: data['location'] ?? '',
          timestamp: data['createdAt'] != null 
              ? DateTime.parse(data['createdAt']) 
              : DateTime.now(),
        );
      }).toList();

      // Filter by query
      return allStatuses.where((status) {
        return status.issueText.toLowerCase().contains(query.toLowerCase()) ||
               status.location.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching statuses: $e');
      return [];
    }
  }

  /// Get friends list (you can implement your friend system)
  static Future<List<String>> getFriendsList() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      DocumentSnapshot userDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
      return List<String>.from(userData['friends'] ?? []);
    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }
}