import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Guardhouse {
  final String id;
  final String name;
  final String address;
  final LatLng location;

  Guardhouse({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });

  factory Guardhouse.fromDoc(DocumentSnapshot doc) {
    print('🏗️ [DEBUG] Creating Guardhouse from document: ${doc.id}');
    
    final data = doc.data() as Map<String, dynamic>;
    print('🏗️ [DEBUG] Document data: $data');
    
    final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
    final name = data['name'] ?? 'Guardhouse';
    final address = data['address'] ?? '';
    
    print('🏗️ [DEBUG] Extracted values:');
    print('🏗️ [DEBUG]   ID: ${doc.id}');
    print('🏗️ [DEBUG]   Name: $name');
    print('🏗️ [DEBUG]   Address: $address');
    print('🏗️ [DEBUG]   Lat: $lat');
    print('🏗️ [DEBUG]   Lng: $lng');

    final guardhouse = Guardhouse(
      id: doc.id,
      name: name,
      address: address,
      location: LatLng(lat, lng),
    );
    
    print('🏗️ [DEBUG] Created guardhouse: ${guardhouse.name} at ${guardhouse.location}');
    return guardhouse;
  }
  
  @override
  String toString() {
    return 'Guardhouse{id: $id, name: $name, address: $address, location: $location}';
  }
}