// File: lib/destination_dialog.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service/maps_service.dart';

class DestinationDialog extends StatefulWidget {
  final Function(String, LatLng?) onDestinationSelected;

  const DestinationDialog({super.key, required this.onDestinationSelected});

  @override
  State<DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<DestinationDialog> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<String> _quickDestinations = [
    'Home',
    'Campus Main Gate',
    'Library',
    'Dormitory',
    'Student Center',
    'Hospital',
    'Police Station',
  ];
  bool _isSearching = false;

  Future<void> _searchAndSetDestination(String query) async {
    setState(() => _isSearching = true);

    try {
      List<Location> locations = await GoogleMapsService.searchPlaces(query);
      if (locations.isNotEmpty) {
        if (locations.length > 1) {
          _showLocationSelectionDialog(query, locations);
        } else {
          Location location = locations.first;
          LatLng destination = LatLng(location.latitude, location.longitude);
          _showSaveDialog(query, destination);
        }
      } else {
        _showError('Location not found. Please try a different search.');
      }
    } catch (e) {
      _showError('Error searching for location: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showLocationSelectionDialog(String query, List<Location> locations) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Select a location for "$query"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: locations.map((location) {
                String address = 'Lat: ${location.latitude}, Lng: ${location.longitude}';
                return ListTile(
                  title: Text(address),
                  onTap: () async {
                    LatLng destination = LatLng(location.latitude, location.longitude);
                    Navigator.pop(ctx);
                    _showSaveDialog(address, destination);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSaveDialog(String address, LatLng destination) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save Destination?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Would you like to save this destination?'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Destination Name (optional)',
                  hintText: 'e.g., Friend\'s House',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.onDestinationSelected(address, destination);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('No, Just Use'),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = _nameController.text.trim();
                await FirebaseFirestore.instance.collection('destinations').add({
                  'name': name.isNotEmpty ? name : address,
                  'address': address,
                  'lat': destination.latitude,
                  'lng': destination.longitude,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                widget.onDestinationSelected(
                    name.isNotEmpty ? name : address, destination);

                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Yes, Save'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set Destination',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Enter destination',
                hintText: 'e.g., 123 Main St, City or Place Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchAndSetDestination(value);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSearching
                  ? null
                  : () {
                      if (_destinationController.text.isNotEmpty) {
                        _searchAndSetDestination(_destinationController.text);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                  _isSearching ? 'Searching...' : 'Set Custom Destination'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Destinations:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickDestinations.map((destination) {
                return OutlinedButton(
                  onPressed: _isSearching
                      ? null
                      : () {
                          _searchAndSetDestination(destination);
                        },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(destination),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}