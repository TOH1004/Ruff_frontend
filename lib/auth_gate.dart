import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage/homepage_chat2.dart'; // User homepage
import 'guard/(guard)homepage_chat2.dart'; // Guard homepage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

Future<String> uploadProfilePic(File file, String uid) async {
  final ref = FirebaseStorage.instance.ref().child('profile_pics/$uid.jpg');
  await ref.putFile(file);
  String downloadUrl = await ref.getDownloadURL();
  return downloadUrl;
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _signInEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );

      // After login, check Firestore role to navigate
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = doc.data();
        final role = data?['role'] ?? 'user';

        if (role == 'guard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => GuardRuffAppScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RuffAppScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUpEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        String name = await _askUserName();

        // Save user info to Firestore (default role = user)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': user.email,
          'profilePic': '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RuffAppScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _askUserName() async {
    TextEditingController nameController = TextEditingController();
    String result = '';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter your name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                result = nameController.text.trim();
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return result.isNotEmpty ? result : 'Anonymous';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign in")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 8),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            _busy
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(onPressed: _signInEmail, child: const Text("Sign in")),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(onPressed: _signUpEmail, child: const Text("Create account")),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
