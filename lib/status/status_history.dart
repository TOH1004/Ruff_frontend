import 'dart:io';
import 'package:flutter/material.dart';
import 'status_data.dart';
import 'statuspage.dart';
import 'status.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Status History"),
        backgroundColor: const Color(0xFF3075FF),
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<Status>>(
        valueListenable: statusHistory, // must be defined in status_data.dart
        builder: (context, historyList, _) {
          if (historyList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No status yet.", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    "Create your first status using the form.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final status = historyList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    status.issueText.isNotEmpty
                        ? status.issueText
                        : "No description",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                 
subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text("📍 ${status.location.isNotEmpty ? status.location : 'Unknown'}"),
  ],
),


                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.shade50,
                    ),
                    child: status.imagePaths.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(status.imagePaths[0]),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.report, color: Colors.blue),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "edit") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StatusPage(),
                          ),
                        );
                      } else if (value == "delete") {
                        _showDeleteDialog(context, index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StatusPage(),
            ),
          );
        },
        backgroundColor: const Color(0xFF3075FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Status'),
          content: const Text(
            'Are you sure you want to delete this status? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                List<Status> updatedList = List.from(statusHistory.value);
                updatedList.removeAt(index);
                statusHistory.value = updatedList;

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Status deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
