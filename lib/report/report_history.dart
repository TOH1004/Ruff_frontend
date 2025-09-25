import 'dart:io';
import 'package:flutter/material.dart';
import 'report_data.dart'; // contains reportHistory
// contains Report model


class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report History")),
      body: ValueListenableBuilder<List<Report>>(
        valueListenable: reportHistory,
        builder: (context, historyList, _) {
          if (historyList.isEmpty) {
            return const Center(
              child: Text("No reports yet."),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final report = historyList[index];
              return Card(
                child: ListTile(
                  title: Text(report.issueText.isNotEmpty
                      ? report.issueText
                      : "No description"),
                  subtitle: Text("📍 ${report.location}"),
                  leading: report.imagePaths.isNotEmpty
                      ? Image.file(
                          File(report.imagePaths[0]),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.report),
                  trailing: PopupMenuButton<String>(
                    
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "edit",
                        child: Text("Edit"),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
