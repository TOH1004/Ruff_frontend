// report_data.dart
import 'package:flutter/material.dart';

// Model class
class Report {
  final String issueText;
  final List<String> imagePaths;
  final String location;

  Report({
    required this.issueText,
    required this.imagePaths,
    required this.location,
  });
}

// Global history store
ValueNotifier<List<Report>> reportHistory = ValueNotifier<List<Report>>([]);
