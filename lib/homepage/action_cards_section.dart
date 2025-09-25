// File: lib/home_sections/action_cards_section.dart

import 'package:flutter/material.dart';
import '../aibuddy_mode/aibuddy.dart';
import '../report/report.dart';
import '../status/status.dart';

class ActionCardsSection extends StatelessWidget {
  const ActionCardsSection({super.key});

  Widget _buildActionCardAsset({
    required String assetPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 110,
        height: 100,
        margin: const EdgeInsets.only(top: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath.isNotEmpty)
              Image.asset(
                assetPath,
                width: 77,
                height: 77,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Transform.translate(
        offset: const Offset(0, -50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionCardAsset(
                assetPath: 'assets/status.png',
                label: 'Status',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatusHistoryPage(),
                    ),
                  );
                },
              ),
              _buildActionCardAsset(
                assetPath: 'assets/aibuddy.png',
                label: 'AI Buddy',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIBuddyPage(),
                    ),
                  );
                },
              ),
              _buildActionCardAsset(
                assetPath: 'assets/report.png',
                label: 'Reports',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}