// Enhanced destination_dialog.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'service/maps_service.dart';
import 'models/guardhouse.dart';

enum RouteType {
  custom,
  nearestGuardhouse,
  specificGuardhouse,
}

class DestinationDialog extends StatefulWidget {
  final Function(String, LatLng?, RouteType) onDestinationSelected;
  final Position? currentPosition;
  final List<Guardhouse> guardhouses;

  const DestinationDialog({
    super.key,
    required this.onDestinationSelected,
    this.currentPosition,
    required this.guardhouses,
  });

  @override
  State<DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<DestinationDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  late TabController _tabController;
  
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
  List<Guardhouse> _nearbyGuardhouses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateNearbyGuardhouses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateNearbyGuardhouses() {
    if (widget.currentPosition == null || widget.guardhouses.isEmpty) return;

    // Calculate distances and sort guardhouses by proximity
    List<MapEntry<Guardhouse, double>> guardhousesWithDistance =
        widget.guardhouses.map((guardhouse) {
      double distance = Geolocator.distanceBetween(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
        guardhouse.location.latitude,
        guardhouse.location.longitude,
      );
      return MapEntry(guardhouse, distance);
    }).toList();

    // Sort by distance (closest first)
    guardhousesWithDistance.sort((a, b) => a.value.compareTo(b.value));

    setState(() {
      _nearbyGuardhouses = guardhousesWithDistance
          .map((entry) => entry.key)
          .toList();
    });
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  double _calculateDistance(Guardhouse guardhouse) {
    if (widget.currentPosition == null) return 0;
    return Geolocator.distanceBetween(
      widget.currentPosition!.latitude,
      widget.currentPosition!.longitude,
      guardhouse.location.latitude,
      guardhouse.location.longitude,
    );
  }

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
                widget.onDestinationSelected(address, destination, RouteType.custom);
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
                    name.isNotEmpty ? name : address, destination, RouteType.custom);

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

  void _selectNearestGuardhouse() {
    if (_nearbyGuardhouses.isNotEmpty) {
      final nearest = _nearbyGuardhouses.first;
      widget.onDestinationSelected(
        'Nearest Guardhouse: ${nearest.name}',
        nearest.location,
        RouteType.nearestGuardhouse,
      );
      Navigator.pop(context);
    }
  }

  void _selectSpecificGuardhouse(Guardhouse guardhouse) {
    widget.onDestinationSelected(
      guardhouse.name,
      guardhouse.location,
      RouteType.specificGuardhouse,
    );
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildCustomDestinationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: Text(_isSearching ? 'Searching...' : 'Set Custom Destination'),
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
    );
  }

  Widget _buildNearestGuardhouseTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_nearbyGuardhouses.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No guardhouses found nearby'),
                ],
              ),
            )
          else ...[
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security, color: Colors.white),
                ),
                title: Text(_nearbyGuardhouses.first.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nearbyGuardhouses.first.address),
                    const SizedBox(height: 4),
                    Text(
                      'Distance: ${_formatDistance(_calculateDistance(_nearbyGuardhouses.first))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectNearestGuardhouse,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectNearestGuardhouse,
              icon: const Icon(Icons.navigation),
              label: const Text('Navigate to Nearest Guardhouse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllGuardhousesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_nearbyGuardhouses.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.security, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No guardhouses available'),
                ],
              ),
            )
          else ...[
            const Text(
              'Select a specific guardhouse:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _nearbyGuardhouses.length,
                itemBuilder: (context, index) {
                  final guardhouse = _nearbyGuardhouses[index];
                  final distance = _calculateDistance(guardhouse);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: index == 0 ? Colors.green : Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.security, color: Colors.white),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(guardhouse.name)),
                          if (index == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEAREST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(guardhouse.address),
                          const SizedBox(height: 4),
                          Text(
                            'Distance: ${_formatDistance(distance)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0 ? Colors.green : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _selectSpecificGuardhouse(guardhouse),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
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
            ),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(
                  icon: Icon(Icons.search),
                  text: 'Custom',
                ),
                Tab(
                  icon: Icon(Icons.near_me),
                  text: 'Nearest',
                ),
                Tab(
                  icon: Icon(Icons.security),
                  text: 'All Guards',
                ),
              ],
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCustomDestinationTab(),
                  _buildNearestGuardhouseTab(),
                  _buildAllGuardhousesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}