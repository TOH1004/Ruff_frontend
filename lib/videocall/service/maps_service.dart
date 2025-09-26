
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

  /// Updated: Fetch guardhouses with geocoding support
  static Future<List<Guardhouse>> getGuardhouses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('guardhouses').get();
      List<Guardhouse> guardhouses = [];
      
      for (var doc in snapshot.docs) {
        try {
          // Use the geocoding method if coordinates are missing
          final data = doc.data() as Map<String, dynamic>;
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          
          if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
            // Use existing coordinates
            guardhouses.add(Guardhouse.fromDoc(doc));
          } else {
            // Try geocoding
            guardhouses.add(await Guardhouse.fromDocWithGeocoding(doc));
          }
        } catch (e) {
          print('Error processing guardhouse ${doc.id}: $e');
          // Add with default coordinates if geocoding fails
          guardhouses.add(Guardhouse.fromDoc(doc));
        }
      }
      
      // Filter out guardhouses with invalid coordinates (0,0)
      return guardhouses.where((g) => g.location.latitude != 0.0 || g.location.longitude != 0.0).toList();
    } catch (e) {
      print('Error fetching guardhouses: $e');
      return [];
    }
  }
  
  /// Helper method to geocode an address
  static Future<LatLng?> geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print('Geocoding failed for $address: $e');
    }
    return null;
  }
}