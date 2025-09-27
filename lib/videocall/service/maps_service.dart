// File: lib/service/maps_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/route_info.dart';
import '../models/guardhouse.dart';

const String GOOGLE_MAPS_API_KEY = 'AIzaSyBImHrrt1GuCrZJHHxLV5m6R7nkz-Ahc7Q';

class GoogleMapsService {
  static Future<RouteInfo?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$GOOGLE_MAPS_API_KEY';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final String encodedPolyline = route['overview_polyline']['points'];
          final List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);

          return RouteInfo(
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            polylinePoints: polylinePoints,
          );
        }
      }
    } catch (e) {
      print('Error getting directions: $e');
    }
    return null;
  }

  static Future<List<Location>> searchPlaces(String query) async {
    try {
      return await locationFromAddress(query);
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  /// Updated: Fetch guardhouses from Firestore with geocoding and debugging
  static Future<List<Guardhouse>> getGuardhouses() async {
    print('🏠 [DEBUG] Starting getGuardhouses...');
    try {
      print('🏠 [DEBUG] Connecting to Firebase...');
      final snapshot = await FirebaseFirestore.instance
          .collection('guardhouses')
          .get()
          .timeout(Duration(seconds: 30)); // Add timeout
      print('🏠 [DEBUG] Found ${snapshot.docs.length} documents in guardhouses collection');
      
      if (snapshot.docs.isEmpty) {
        print('🏠 [DEBUG] No documents found in guardhouses collection!');
        print('🏠 [DEBUG] This could be due to:');
        print('🏠 [DEBUG] 1. Empty collection');
        print('🏠 [DEBUG] 2. Firebase security rules blocking access');
        print('🏠 [DEBUG] 3. Authentication issues');
        return [];
      }
      
      // Print all document IDs for verification
      print('🏠 [DEBUG] Document IDs found:');
      for (int i = 0; i < snapshot.docs.length; i++) {
        print('🏠 [DEBUG] ${i + 1}. ${snapshot.docs[i].id}');
      }
      
      List<Guardhouse> guardhouses = [];
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        print('🏠 [DEBUG] Processing document ${i + 1}/${snapshot.docs.length}: ${doc.id}');
        
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('🏠 [DEBUG] Document data: $data');
          
          final name = data['name'] ?? 'Guardhouse ${i + 1}';
          final address = data['address'] ?? '';
          final phone = data['phone'] ?? '';
          
          print('🏠 [DEBUG] Name: $name');
          print('🏠 [DEBUG] Address: $address');
          print('🏠 [DEBUG] Phone: $phone');
          
          // Check if lat/lng already exist
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          
          LatLng location;
          
          if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
            // Use existing coordinates
            location = LatLng(lat, lng);
            print('🏠 [DEBUG] Using existing coordinates: $lat, $lng');
          } else {
            // Geocode the address
            print('🏠 [DEBUG] No coordinates found, geocoding address: $address');
            if (address.isEmpty) {
              print('🏠 [DEBUG] Empty address, skipping guardhouse: $name');
              continue;
            }
            
            final geocodedLocation = await _geocodeAddress(address);
            if (geocodedLocation != null) {
              location = geocodedLocation;
              print('🏠 [DEBUG] Geocoded successfully: ${location.latitude}, ${location.longitude}');
              
              // Save coordinates back to Firebase
              try {
                await doc.reference.update({
                  'lat': location.latitude,
                  'lng': location.longitude,
                });
                print('🏠 [DEBUG] Saved coordinates to Firebase');
              } catch (updateError) {
                print('🏠 [DEBUG] Failed to save coordinates: $updateError');
              }
            } else {
              print('🏠 [DEBUG] Geocoding failed for: $address, skipping guardhouse');
              continue;
            }
          }
          
          final guardhouse = Guardhouse(
            id: doc.id,
            name: name,
            address: address,
            location: location,
          );
          
          guardhouses.add(guardhouse);
          print('🏠 [DEBUG] Successfully added guardhouse: $name at ${location.latitude}, ${location.longitude}');
          
        } catch (docError) {
          print('🏠 [DEBUG] Error processing document ${doc.id}: $docError');
          continue;
        }
      }
      
      print('🏠 [DEBUG] Successfully processed ${guardhouses.length} guardhouses');
      return guardhouses;
      
    } catch (e) {
      print('🏠 [DEBUG] Error fetching guardhouses: $e');
      print('🏠 [DEBUG] Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  /// Helper method to geocode an address with debugging
  static Future<LatLng?> _geocodeAddress(String address) async {
    print('🌍 [DEBUG] Starting geocoding for: $address');
    try {
      // Add "Malaysia" to improve geocoding accuracy if not already present
      String fullAddress = address.toLowerCase().contains('malaysia') 
          ? address 
          : '$address, Malaysia';
          
      print('🌍 [DEBUG] Full address for geocoding: $fullAddress');
      
      List<Location> locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        final location = locations.first;
        print('🌍 [DEBUG] Geocoding successful: ${location.latitude}, ${location.longitude}');
        return LatLng(location.latitude, location.longitude);
      } else {
        print('🌍 [DEBUG] No locations found for: $fullAddress');
      }
    } catch (e) {
      print('🌍 [DEBUG] First geocoding attempt failed: $e');
      
      // Try without "Malaysia" if the first attempt failed
      try {
        print('🌍 [DEBUG] Trying without Malaysia suffix...');
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final location = locations.first;
          print('🌍 [DEBUG] Second attempt successful: ${location.latitude}, ${location.longitude}');
          return LatLng(location.latitude, location.longitude);
        } else {
          print('🌍 [DEBUG] No locations found in second attempt');
        }
      } catch (e2) {
        print('🌍 [DEBUG] Second geocoding attempt also failed: $e2');
      }
    }
    print('🌍 [DEBUG] Geocoding completely failed for: $address');
    return null;
  }
}