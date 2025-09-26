// Create this as a new file: widgets/map_legend.dart

import 'package:flutter/material.dart';
import '../videocall.dart';

class MapLegend extends StatelessWidget {
  final bool isSOSActive;
  final bool showLegend;
  final VoidCallback onToggleLegend;

  const MapLegend({
    super.key,
    required this.isSOSActive,
    required this.showLegend,
    required this.onToggleLegend,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend toggle button
          GestureDetector(
            onTap: onToggleLegend,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map, size: 16),
                  const SizedBox(width: 4),
                  const Text('Legend', style: TextStyle(fontSize: 12)),
                  Icon(
                    showLegend ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Legend content
          if (showLegend)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(
                    color: Colors.blue,
                    label: 'Your Location',
                    icon: Icons.person_pin_circle,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    color: Colors.green,
                    label: 'Guardhouse',
                    icon: Icons.security,
                  ),
                  if (isSOSActive) ...[
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      color: Colors.orange,
                      label: 'Emergency Guardhouse',
                      icon: Icons.emergency,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    color: Colors.red,
                    label: 'Destination',
                    icon: Icons.place,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}