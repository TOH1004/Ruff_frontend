import 'package:flutter/material.dart';
import 'report_data.dart';

class EditReportPage extends StatefulWidget {
  final Report report;
  final int index;

  const EditReportPage({super.key, required this.report, required this.index});

  @override
  State<EditReportPage> createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  late TextEditingController _issueController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _issueController = TextEditingController(text: widget.report.issueText);
    _locationController = TextEditingController(text: widget.report.location);
  }

  void _saveChanges() {
    final updatedReport = Report(
      issueText: _issueController.text,
      location: _locationController.text,
      imagePaths: widget.report.imagePaths, // keep old images for now
    );

    final newList = List<Report>.from(reportHistory.value);
    newList[widget.index] = updatedReport;
    reportHistory.value = newList;

    Navigator.pop(context); // back to history
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _issueController,
              decoration: const InputDecoration(labelText: "Issue"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
