import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final String duration;
  final String distance;
  final List<LatLng> polylinePoints;

  RouteInfo({
    required this.duration,
    required this.distance,
    required this.polylinePoints,
  });
}