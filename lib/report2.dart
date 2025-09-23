import 'dart:io';
import 'package:flutter/material.dart';

// Example model - adjust based on your actual Report class
class Report {
  final String issueText;
  final String location;
  final List<String> imagePaths;

  Report({
    required this.issueText,
    required this.location,
    required this.imagePaths,
  });
}

// New HistoryPage
class HistoryPage extends StatelessWidget {
  final ValueNotifier<List<Report>> reportHistory;

  const HistoryPage({super.key, required this.reportHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.blue,
      ),
      body: ValueListenableBuilder<List<Report>>(
        valueListenable: reportHistory,
        builder: (context, historyList, _) {
          if (historyList.isEmpty) {
            return const Center(
              child: Text(
                "No history available",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final report = historyList[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Issue description
                      Text(
                        report.issueText.isNotEmpty
                            ? report.issueText
                            : "No description provided",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.location.isNotEmpty
                                  ? report.location
                                  : "No location",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Attached images
                      if (report.imagePaths.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: report.imagePaths.length,
                            itemBuilder: (context, imgIndex) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(report.imagePaths[imgIndex]),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
