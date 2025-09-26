import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class Guardhouse {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final LatLng location;

  Guardhouse({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    required this.location,
  });

  factory Guardhouse.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Try to get coordinates from lat/lng fields first
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();

    return Guardhouse(
      id: doc.id,
      name: data['name'] ?? 'Guardhouse',
      address: data['address'] ?? '',
      phone: data['phone'],
      location: (lat != null && lng != null) 
        ? LatLng(lat, lng)
        : const LatLng(0.0, 0.0), // Default coordinates if missing
    );
  }

  // Static method to create Guardhouse with geocoding
  static Future<Guardhouse> fromDocWithGeocoding(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    // Try to get coordinates from lat/lng fields first
    double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    double lng = (data['lng'] as num?)?.toDouble() ?? 0.0;

    // If coordinates are missing or zero, try geocoding the address
    if (lat == 0.0 && lng == 0.0) {
      final address = data['address'] as String?;
      if (address != null && address.isNotEmpty) {
        try {
          List<Location> locations = await locationFromAddress(address);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        } catch (e) {
          print('Geocoding failed for $address: $e');
          // Keep default coordinates (0,0)
        }
      }
    }

    return Guardhouse(
      id: doc.id,
      name: data['name'] ?? 'Guardhouse',
      address: data['address'] ?? '',
      phone: data['phone'],
      location: LatLng(lat, lng),
    );
  }
}