import 'package:flutter/material.dart';

class SOSButton extends StatelessWidget {
  final bool isSOSTriggered;
  final VoidCallback onSOSPressed;

  const SOSButton({
    super.key,
    required this.isSOSTriggered,
    required this.onSOSPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSOSTriggered ? null : onSOSPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSOSTriggered ? Colors.grey[600] : Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isSOSTriggered ? 0 : 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSOSTriggered ? Icons.check_circle : Icons.emergency,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isSOSTriggered ? 'SOS ACTIVATED' : 'EMERGENCY SOS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}