import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardhouseListPage extends StatelessWidget {
  const GuardhouseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Guardhouses")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('guardhouses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Show loading while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // No data case
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No guardhouses found."));
          }

          // Data exists
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Safely cast document data
              final data = docs[index].data() as Map<String, dynamic>? ?? {};

              // Provide default values for missing fields
              final name = data['name']?.toString() ?? 'No Name';
              final address = data['address']?.toString() ?? 'No Address';
              final phone = data['phone']?.toString() ?? 'No Phone';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Address: $address\nPhone: $phone"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
