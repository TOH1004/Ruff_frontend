import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../guard/applyguard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _email;
  String? _userId; // This is the permanent Firebase UID
  String? _profileUrl;
  String? _currentUsername; // NEW: To store the current username for comparison

  // MODIFIED: Added a controller for the new username field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController(); // NEW
  final TextEditingController _bioController = TextEditingController();
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false; // NEW: To handle loading state during save

  final List<String> _defaultPics = [
    'https://ik.imagekit.io/hquou6lekg/ruff/5.jpg?updatedAt=1758809449070',
    'https://ik.imagekit.io/hquou6lekg/ruff/6.jpg?updatedAt=1758809449083',
    'https://ik.imagekit.io/hquou6lekg/ruff/3.jpg?updatedAt=1758809449034',
    'https://ik.imagekit.io/hquou6lekg/ruff/4.jpg?updatedAt=1758809448986',
    'https://ik.imagekit.io/hquou6lekg/ruff/1.jpg?updatedAt=1758809448960',
    'https://ik.imagekit.io/hquou6lekg/ruff/2.jpg?updatedAt=1758809448927',
    'https://ik.imagekit.io/hquou6lekg/ruff/7.jpg?updatedAt=1758809448878',
    'https://ik.imagekit.io/hquou6lekg/ruff/8.jpg?updatedAt=1758809448645',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // MODIFIED: Clean up all controllers
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      _email = user.email ?? 'No email';

      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();

      // Create document if it doesn't exist, now with a 'username' field
      if (!snapshot.exists) {
        await docRef.set({
          'name': 'User',
          'email': _email,
          'username': '', // NEW: Initialize username field
          'profilePic': '',
          'bio': '',
        });
      }

      final data = await docRef.get();
      setState(() {
        _nameController.text = data.get('name') ?? '';
        _bioController.text = data.get('bio') ?? '';
        _profileUrl = data.get('profilePic');
        // NEW: Load username data
        _currentUsername = data.get('username') ?? '';
        _usernameController.text = _currentUsername!;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _pickedImage = File(pickedFile.path));
        final downloadUrl = await _uploadToStorage(_pickedImage!);
        await _updateProfilePicture(downloadUrl);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<String> _uploadToStorage(File file) async {
    final ref = FirebaseStorage.instance.ref().child('profile_pics/$_userId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // NEW: Created a separate function just for updating the profile picture URL
  Future<void> _updateProfilePicture(String url) async {
    if (_userId != null) {
      await _firestore.collection('users').doc(_userId).update({'profilePic': url});
      setState(() {
        _profileUrl = url;
        _pickedImage = null; // Clear picked image after upload
      });
    }
  }

  // MODIFIED: Major changes to handle username uniqueness check before saving
  Future<void> _saveProfileData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final newUsername = _usernameController.text.trim();
      final newName = _nameController.text.trim();
      final newBio = _bioController.text.trim();

      // Step 1: Check if the username has been changed
      if (newUsername != _currentUsername) {
        // Step 2: If changed, check if the new username is already taken
        final query = await _firestore.collection('users').where('username', isEqualTo: newUsername).limit(1).get();

        if (query.docs.isNotEmpty) {
          // Username is taken, show error and stop
          _showError('Username "$newUsername" is already taken.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Step 3: If username is available (or unchanged), proceed to save
      await _firestore.collection('users').doc(_userId).update({
        'name': newName,
        'username': newUsername,
        'bio': newBio,
      });

      // Update local state to reflect changes
      setState(() {
        _currentUsername = newUsername;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      _showError('Failed to save profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDefaultPic(String url) async {
    await _updateProfilePicture(url);
  }

  Future<void> _logOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3075FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture
            GestureDetector(
              onTap: _pickFromGallery,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : _profileUrl != null && _profileUrl!.isNotEmpty
                        ? NetworkImage(_profileUrl!) as ImageProvider
                        : null,
                child: (_pickedImage == null && (_profileUrl == null || _profileUrl!.isEmpty))
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Predefined profile pictures
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _defaultPics.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _selectDefaultPic(_defaultPics[index]),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: CircleAvatar(radius: 35, backgroundImage: NetworkImage(_defaultPics[index])),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // NEW: Username field
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Bio field
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfileData,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Profile'),
              ),
            ),
            const SizedBox(height: 16),

            // Email & UID display
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(_email ?? 'Loading...'),
            ),
            // Apply for Guard button
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApplyGuardPage()),
      );
    },
    icon: const Icon(Icons.security),
    label: const Text('Apply for Guard'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
),
const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logOut,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}