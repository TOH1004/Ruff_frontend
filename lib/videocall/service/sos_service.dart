import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SOSService {
  void triggerSOS(Position? currentPosition) {
    print('SOS TRIGGERED!');
    
    // Add your SOS emergency logic here:
    // - Send emergency signals
    // - Notify emergency contacts
    // - Call emergency services
    // - Start recording
    // - Send location to authorities
    
    if (currentPosition != null) {
      _notifyEmergencyContacts(currentPosition);
      _sendLocationToAuthorities(currentPosition);
      _startEmergencyRecording();
    }
  }

  void _notifyEmergencyContacts(Position position) {
    // Implement emergency contact notification
    print('Notifying emergency contacts...');
    print('Location: ${position.latitude}, ${position.longitude}');
  }

  void _sendLocationToAuthorities(Position position) {
    // Implement location sharing with authorities
    print('Sending location to authorities...');
    print('Coordinates: ${position.latitude}, ${position.longitude}');
  }

  void _startEmergencyRecording() {
    // Implement emergency recording
    print('Starting emergency recording...');
  }

  Set<Marker> getNearbyEmergencyLocations(Position currentPosition) {
    Set<Marker> emergencyMarkers = {};

    // Sample guardhouse locations (replace with actual data)
    List<Map<String, dynamic>> guardhouses = [
      {
        'name': 'Security Guardhouse A',
        'lat': currentPosition.latitude + 0.005,
        'lng': currentPosition.longitude + 0.005,
      },
      {
        'name': 'Main Gate Guardhouse',
        'lat': currentPosition.latitude - 0.003,
        'lng': currentPosition.longitude + 0.007,
      },
    ];

    // Sample store locations (replace with actual data)
    List<Map<String, dynamic>> stores = [
      {
        'name': '7-Eleven Store',
        'lat': currentPosition.latitude + 0.008,
        'lng': currentPosition.longitude - 0.004,
      },
      {
        'name': 'KK Mart',
        'lat': currentPosition.latitude - 0.006,
        'lng': currentPosition.longitude - 0.008,
      },
      {
        'name': 'Pharmacy Plus',
        'lat': currentPosition.latitude + 0.004,
        'lng': currentPosition.longitude + 0.009,
      },
    ];

    // Add guardhouse markers
    for (int i = 0; i < guardhouses.length; i++) {
      final guardhouse = guardhouses[i];
      emergencyMarkers.add(
        Marker(
          markerId: MarkerId('guardhouse_$i'),
          position: LatLng(guardhouse['lat'], guardhouse['lng']),
          infoWindow: InfoWindow(
            title: guardhouse['name'],
            snippet: 'Emergency Security - Available 24/7',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    // Add store markers
    for (int i = 0; i < stores.length; i++) {
      final store = stores[i];
      emergencyMarkers.add(
        Marker(
          markerId: MarkerId('store_$i'),
          position: LatLng(store['lat'], store['lng']),
          infoWindow: InfoWindow(
            title: store['name'],
            snippet: 'Safe Public Place - Help Available',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return emergencyMarkers;
  }
}