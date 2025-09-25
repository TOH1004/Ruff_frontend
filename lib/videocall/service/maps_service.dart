// File: lib/maps_service.dart

import 'package:flutter/material.dart';
import '../wrapper.dart';
import '../videocall.dart';
import '../destination_dialog.dart';
import 'maps_service.dart';
import '../videomain.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/route_info.dart';
const String GOOGLE_MAPS_API_KEY = 'AIzaSyBImHrrt1GuCrZJHHxLV5m6R7nkz-Ahc7Q';

// Google Maps service for directions
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

          // Decode polyline points
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
      List<Location> locations = await locationFromAddress(query);
      return locations;
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  // Decode Google polyline algorithm
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
}