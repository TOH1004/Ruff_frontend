import 'package:flutter/material.dart';
import 'ruff_home_page.dart'; // Import the file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: RuffHomePage(), // Start with RuffHomePage
    );
  }
}
