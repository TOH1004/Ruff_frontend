// Updated google_map_widget.dart with legend integration

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_info.dart';
import 'map_legend.dart'; // Add this import

class GoogleMapWidget extends StatefulWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final RouteInfo? routeInfo;
  final bool isLoadingRoute;
  final String? destination;
  final bool isSOSActive; // Add this parameter
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onDestinationPressed;
  final VoidCallback onRecenterPressed;

  const GoogleMapWidget({
    super.key,
    required this.currentPosition,
    required this.markers,
    required this.polylines,
    required this.routeInfo,
    required this.isLoadingRoute,
    required this.destination,
    required this.isSOSActive, // Add this parameter
    required this.onMapCreated,
    required this.onDestinationPressed,
    required this.onRecenterPressed,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  bool _showLegend = false;

  @override
  Widget build(BuildContext context) {
    if (widget.currentPosition == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: widget.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
                zoom: 15.0,
              ),
              markers: widget.markers,
              polylines: widget.polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // Map Legend
            MapLegend(
              isSOSActive: widget.isSOSActive,
              showLegend: _showLegend,
              onToggleLegend: () {
                setState(() {
                  _showLegend = !_showLegend;
                });
              },
            ),

            // Route info overlay
            if (widget.routeInfo != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.routeInfo!.duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.routeInfo!.distance,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Loading overlay
            if (widget.isLoadingRoute)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Getting route...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),

            // Destination button
            Positioned(
              bottom: 16,
              left: 16,
              child: ElevatedButton.icon(
                onPressed: widget.onDestinationPressed,
                icon: const Icon(Icons.place, size: 16),
                label: Text(
                  widget.destination ?? 'Set Destination',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),

            // Recenter button
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                onPressed: widget.onRecenterPressed,
                child: const Icon(Icons.my_location, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}