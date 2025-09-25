import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_info.dart';

class GoogleMapWidget extends StatelessWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final RouteInfo? routeInfo;
  final bool isLoadingRoute;
  final String? destination;
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
    required this.onMapCreated,
    required this.onDestinationPressed,
    required this.onRecenterPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
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
              onMapCreated: onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                zoom: 15.0,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // Route info overlay
            if (routeInfo != null)
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
                            routeInfo!.duration,
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
                            routeInfo!.distance,
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
            if (isLoadingRoute)
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
                onPressed: onDestinationPressed,
                icon: const Icon(Icons.place, size: 16),
                label: Text(
                  destination ?? 'Set Destination',
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
                onPressed: onRecenterPressed,
                child: const Icon(Icons.my_location, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}