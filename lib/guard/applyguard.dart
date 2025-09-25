import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ApplyGuardPage extends StatefulWidget {
  const ApplyGuardPage({super.key});

  @override
  State<ApplyGuardPage> createState() => _ApplyGuardPageState();
}

class _ApplyGuardPageState extends State<ApplyGuardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String? _name;
  String? _email;
  String? _profilePic;
  String? _username;
  String? _staffId;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  File? _pickedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _name = data['name'] ?? '';
          _email = data['email'] ?? '';
          _username = data['username'] ?? '';
          _profilePic = data['profilePic'] ?? '';
          _staffId = data['staffId'] ?? '';

          _nameController.text = _name!;
          _usernameController.text = _username!;
          _staffIdController.text = _staffId ?? '';
        });
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
      final url = await _uploadProfilePicture(_pickedImage!);
      setState(() => _profilePic = url);
    }
  }

  Future<String> _uploadProfilePicture(File file) async {
    final uid = _auth.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child('guard_app_profile/$uid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _submitApplication() async {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _staffIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser!;
      final username = _usernameController.text.trim();

      // Check username uniqueness
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && query.docs.first.id != user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already taken')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Update user data
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'username': username,
        'profilePic': _profilePic ?? '',
        'staffId': _staffIdController.text.trim(),
      });

      // Create guard application
      await _firestore.collection('guard_applications').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _email,
        'username': username,
        'profilePic': _profilePic ?? '',
        'staffId': _staffIdController.text.trim(),
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guard application submitted!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _staffIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Guard')),
      body: _email == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickProfilePicture,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_profilePic != null && _profilePic!.isNotEmpty)
                              ? NetworkImage(_profilePic!)
                              : null,
                      child: (_profilePic == null || _profilePic!.isEmpty) && _pickedImage == null
                          ? const Icon(Icons.camera_alt, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username', prefixText: '@', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _staffIdController,
                    decoration: const InputDecoration(labelText: 'Staff ID', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Reason for applying', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitApplication,
                      child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
