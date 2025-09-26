import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =============================
  // Trigger SOS request
  // =============================
  Future<String?> triggerSOS(
    Position? currentPosition, {
    String? additionalInfo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ No user logged in, cannot send SOS");
      return null;
    }
    if (currentPosition == null) {
      print("❌ No location available, cannot send SOS");
      return null;
    }

    print('🚨 SOS TRIGGERED!');

    try {
      // 1. Create SOS Firestore document
      DocumentReference sosDoc = await _firestore.collection('sos_requests').add({
        "userId": user.uid,
        "userName": user.displayName,
        "userEmail": user.email,
        "latitude": currentPosition.latitude,
        "longitude": currentPosition.longitude,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "active",
        "additionalInfo": additionalInfo ?? "",
        "hasAttachments": false,
      });
      String sosRequestId = sosDoc.id;
      print("✅ SOS request created with ID: $sosRequestId");

      // 2. Create detailed JSON data
      Map<String, dynamic> sosData = {
        'sosRequestId': sosRequestId,
        'userId': user.uid,
        'userEmail': user.email,
        'timestamp': DateTime.now().toIso8601String(),
        'location': {
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
          'accuracy': currentPosition.accuracy,
          'altitude': currentPosition.altitude,
          'speed': currentPosition.speed,
          'heading': currentPosition.heading,
        },
        'deviceInfo': await _getDeviceInfo(),
        'uploadedFiles': [],
        'fileCount': 0,
        'additionalInfo': additionalInfo ?? "",
        'status': 'active',
        'emergencyContacts': await _getEmergencyContacts(),
      };

      // Upload JSON to Firebase Storage
      await _uploadSOSData(user.uid, sosRequestId, sosData);

      // Update Firestore document with basic info
      await sosDoc.update({
        'hasAttachments': false,
        'fileCount': 0,
        'attachmentUrls': [],
        'uploadStatus': 'completed',
      });

      // Trigger notifications
      await _notifyEmergencyContacts(currentPosition, sosRequestId);
      await _sendLocationToAuthorities(currentPosition, sosRequestId);

      print("✅ SOS fully processed with ID: $sosRequestId");
      return sosRequestId;
    } catch (e) {
      print("❌ Error processing SOS: $e");
      return null;
    }
  }

  // =============================
  // Upload SOS JSON data
  // =============================
  Future<void> _uploadSOSData(
      String userId, String sosRequestId, Map<String, dynamic> sosData) async {
    try {
      String jsonData = jsonEncode(sosData);
      String path = 'sos_requests/$userId/$sosRequestId/sos_data.json';
      Reference ref = _storage.ref().child(path);

      SettableMetadata metadata = SettableMetadata(
        contentType: 'application/json',
        customMetadata: {
          'sosRequestId': sosRequestId,
          'userId': userId,
          'dataType': 'sos_complete_data',
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(Uint8List.fromList(utf8.encode(jsonData)), metadata);
    } catch (e) {
      print("❌ Error uploading SOS data: $e");
    }
  }

  // =============================
  // Backup SOS
  // =============================
  Future<void> createSOSBackup(String sosRequestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      DocumentSnapshot sosDoc =
          await _firestore.collection('sos_requests').doc(sosRequestId).get();
      if (!sosDoc.exists) return;

      Map<String, dynamic> sosData = sosDoc.data() as Map<String, dynamic>;

      String date = DateTime.now().toIso8601String().split('T')[0];
      String backupFileName = '${user.uid}_${sosRequestId}.json';
      String backupPath = 'sos_backups/$date/$backupFileName';

      Reference backupRef = _storage.ref().child(backupPath);

      SettableMetadata metadata = SettableMetadata(
        contentType: 'application/json',
        customMetadata: {
          'sosRequestId': sosRequestId,
          'userId': user.uid,
          'backupType': 'complete_sos_backup',
          'backupTime': DateTime.now().toIso8601String(),
        },
      );

      await backupRef.putData(
          Uint8List.fromList(utf8.encode(jsonEncode(sosData))), metadata);
    } catch (e) {
      print("❌ Error creating SOS backup: $e");
    }
  }

  // =============================
  // Device info & contacts
  // =============================
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<List<String>> _getEmergencyContacts() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    QuerySnapshot contacts = await _firestore
        .collection('emergency_contacts')
        .where('userId', isEqualTo: user.uid)
        .get();

    return contacts.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['contactUserId'] as String)
        .toList();
  }

  // =============================
  // Notifications (to implement)
  // =============================
  Future<void> _notifyEmergencyContacts(Position position, String sosRequestId) async {
    print('📢 Notifying contacts: $sosRequestId at ${position.latitude}, ${position.longitude}');
  }

  Future<void> _sendLocationToAuthorities(Position position, String sosRequestId) async {
    print('🚔 Sending location to authorities: $sosRequestId at ${position.latitude}, ${position.longitude}');
  }
}
