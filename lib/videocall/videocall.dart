import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
// Import separate files
import 'models/participant.dart';
import 'models/route_info.dart';
import 'service/location_service.dart';
import 'service/webrtc_service.dart';
import 'service/maps_service.dart';
import 'service/sos_service.dart';
import 'widgets/participant_grid.dart';
import 'widgets/google_map_widget.dart';
import 'widgets/sos_button.dart';
import 'widgets/control_bar.dart';
import 'destination_dialog.dart';
import 'models/guardhouse.dart';
import 'widgets/map_legend.dart';

const SIGNALING_SERVER_URL = 'wss://ruff-ox2a.onrender.com';
const ROOM_ID = 'test-room';
RouteType _currentRouteType = RouteType.custom;
bool _showGuardhouseRoutes = false;

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final _localRenderer = RTCVideoRenderer();
  final List<Participant> _remoteParticipants = [];
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  IOWebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  String _connectionStatus = 'Disconnected';
  Position? _currentPosition;
  String _currentAddress = 'Getting location...';
  String? _destination;
  LatLng? _destinationLatLng;
  bool _isLoadingLocation = true;


Future<void> _testFirebaseConnection() async {
  print('🔥 [TEST] Testing Firebase connection...');
  try {
    // Test basic Firebase connection
    final testSnapshot = await FirebaseFirestore.instance
        .collection('guardhouses')
        .limit(1)
        .get()
        .timeout(Duration(seconds: 10));
    
    print('🔥 [TEST] Firebase connection successful!');
    print('🔥 [TEST] Can access guardhouses collection: ${testSnapshot.docs.isNotEmpty}');
    
    if (testSnapshot.docs.isNotEmpty) {
      final firstDoc = testSnapshot.docs.first;
      print('🔥 [TEST] First document ID: ${firstDoc.id}');
      print('🔥 [TEST] First document data: ${firstDoc.data()}');
    }
    
    // Test full collection access
    final fullSnapshot = await FirebaseFirestore.instance
        .collection('guardhouses')
        .get()
        .timeout(Duration(seconds: 15));
    
    print('🔥 [TEST] Total documents in guardhouses: ${fullSnapshot.docs.length}');
    
    // List all document IDs and basic info
    for (int i = 0; i < fullSnapshot.docs.length; i++) {
      final doc = fullSnapshot.docs[i];
      final data = doc.data() as Map<String, dynamic>;
      print('🔥 [TEST] Doc ${i+1}: ${doc.id}');
      print('🔥 [TEST]   Name: ${data['name']}');
      print('🔥 [TEST]   Address: ${data['address']}');
      print('🔥 [TEST]   Has lat: ${data.containsKey('lat')}');
      print('🔥 [TEST]   Has lng: ${data.containsKey('lng')}');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Firebase Test: Found ${fullSnapshot.docs.length} guardhouses'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
    
  } catch (e, stackTrace) {
    print('🔥 [TEST] Firebase connection failed: $e');
    print('🔥 [TEST] Stack trace: $stackTrace');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Firebase Test Failed: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}


  // Google Maps related
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;

  // Countdown and SOS functionality
  Timer? _countdownTimer;
  int _countdownSeconds = 60;
  bool _isCountdownActive = true;
  bool _isSOSTriggered = false;

  // Services
  late LocationService _locationService;
  late WebRTCService _webrtcService;
  late SOSService _sosService;

List<Guardhouse> _guardhouses = [];
  bool _isLoadingGuardhouses = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeCall();
    _getCurrentLocation();
    _loadGuardhouses(); 
    _startCountdown();
  }

Future<void> _loadGuardhouses() async {
  print('📍 [DEBUG] _loadGuardhouses() called');
  
  setState(() {
    _isLoadingGuardhouses = true;
  });
  
  try {
    print('📍 [DEBUG] Calling GoogleMapsService.getGuardhouses()');
    final guardhouses = await GoogleMapsService.getGuardhouses();
    print('📍 [DEBUG] Received ${guardhouses.length} guardhouses from service');
    
    // Print details of each guardhouse
    for (int i = 0; i < guardhouses.length; i++) {
      var gh = guardhouses[i];
      print('📍 [DEBUG] Guardhouse $i: ${gh.name}');
      print('📍 [DEBUG]   Address: ${gh.address}');
      print('📍 [DEBUG]   Location: ${gh.location.latitude}, ${gh.location.longitude}');
      print('📍 [DEBUG]   ID: ${gh.id}');
    }
    
    if (mounted) {
      setState(() {
        _guardhouses = guardhouses;
        _isLoadingGuardhouses = false;
      });
      
      print('📍 [DEBUG] State updated, calling _addGuardhouseMarkers()');
      _addGuardhouseMarkers();
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug: Loaded ${guardhouses.length} guardhouses'),
          backgroundColor: guardhouses.isEmpty ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      print('📍 [DEBUG] Widget not mounted, skipping state update');
    }
  } catch (e, stackTrace) {
    print('📍 [DEBUG] Error in _loadGuardhouses: $e');
    print('📍 [DEBUG] Stack trace: $stackTrace');
    
    if (mounted) {
      setState(() {
        _isLoadingGuardhouses = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug: Failed to load guardhouses - $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

void _addGuardhouseMarkers() {
  print('📍 [DEBUG] _addGuardhouseMarkers() called');
  print('📍 [DEBUG] Current markers count before adding: ${_markers.length}');
  print('📍 [DEBUG] Guardhouses to add: ${_guardhouses.length}');
  
  int markersAdded = 0;
  int markersSkipped = 0;
  
  for (var guardhouse in _guardhouses) {
    if (guardhouse.location.latitude != 0.0 || guardhouse.location.longitude != 0.0) {
      print('📍 [DEBUG] Adding marker for: ${guardhouse.name} at ${guardhouse.location}');
      
      final marker = Marker(
        markerId: MarkerId('guardhouse_${guardhouse.id}'),
        position: guardhouse.location,
        infoWindow: InfoWindow(
          title: guardhouse.name,
          snippet: guardhouse.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen, // Green color for guardhouses
        ),
        onTap: () {
          print('📍 [DEBUG] Guardhouse marker tapped: ${guardhouse.name}');
          _onGuardhouseMarkerTap(guardhouse);
        },
      );
      
      _markers.add(marker);
      markersAdded++;
    } else {
      print('📍 [DEBUG] Skipping ${guardhouse.name} - invalid coordinates (0,0)');
      markersSkipped++;
    }
  }
  
  print('📍 [DEBUG] Markers added: $markersAdded');
  print('📍 [DEBUG] Markers skipped: $markersSkipped');
  print('📍 [DEBUG] Total markers now: ${_markers.length}');
  
  setState(() {}); // Force UI refresh
  print('📍 [DEBUG] UI state updated');
  
  // Additional debug: Check if map controller is available
  if (_mapController != null) {
    print('📍 [DEBUG] Map controller is available');
    
    // Try to move camera to show guardhouses
    if (_guardhouses.isNotEmpty && _currentPosition != null) {
      print('📍 [DEBUG] Attempting to fit map bounds to show guardhouses');
      _fitMapToShowGuardhouses();
    }
  } else {
    print('📍 [DEBUG] Map controller is null');
  }
}

// Add this helper method to fit the map to show guardhouses
void _fitMapToShowGuardhouses() {
  if (_mapController == null || _guardhouses.isEmpty) return;
  
  print('📍 [DEBUG] Calculating bounds for ${_guardhouses.length} guardhouses');
  
  double minLat = _guardhouses.first.location.latitude;
  double maxLat = _guardhouses.first.location.latitude;
  double minLng = _guardhouses.first.location.longitude;
  double maxLng = _guardhouses.first.location.longitude;
  
  // Include current position if available
  if (_currentPosition != null) {
    minLat = minLat < _currentPosition!.latitude ? minLat : _currentPosition!.latitude;
    maxLat = maxLat > _currentPosition!.latitude ? maxLat : _currentPosition!.latitude;
    minLng = minLng < _currentPosition!.longitude ? minLng : _currentPosition!.longitude;
    maxLng = maxLng > _currentPosition!.longitude ? maxLng : _currentPosition!.longitude;
  }
  
  // Include all guardhouses
  for (var guardhouse in _guardhouses) {
    if (guardhouse.location.latitude != 0.0 || guardhouse.location.longitude != 0.0) {
      minLat = minLat < guardhouse.location.latitude ? minLat : guardhouse.location.latitude;
      maxLat = maxLat > guardhouse.location.latitude ? maxLat : guardhouse.location.latitude;
      minLng = minLng < guardhouse.location.longitude ? minLng : guardhouse.location.longitude;
      maxLng = maxLng > guardhouse.location.longitude ? maxLng : guardhouse.location.longitude;
    }
  }
  
  print('📍 [DEBUG] Bounds: minLat=$minLat, maxLat=$maxLat, minLng=$minLng, maxLng=$maxLng');
  
  // Add some padding
  double padding = 0.01;
  minLat -= padding;
  maxLat += padding;
  minLng -= padding;
  maxLng += padding;
  
  try {
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding in pixels
      ),
    );
    print('📍 [DEBUG] Camera animation started');
  } catch (e) {
    print('📍 [DEBUG] Failed to animate camera: $e');
  }
}
  // Add this method to handle guardhouse marker taps
  void _onGuardhouseMarkerTap(Guardhouse guardhouse) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(guardhouse.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Address: ${guardhouse.address}'),
              const SizedBox(height: 8),
              if (_currentPosition != null)
                Text(
                  'Distance: ${_calculateDistance(
                    _currentPosition!,
                    guardhouse.location,
                  )} km',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setDestinationToGuardhouse(guardhouse);
              },
              child: const Text('Set as Destination'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to calculate distance between two points
  String _calculateDistance(Position currentPos, LatLng destination) {
    double distanceInMeters = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      destination.latitude,
      destination.longitude,
    );
    double distanceInKm = distanceInMeters / 1000;
    return distanceInKm.toStringAsFixed(2);
  }

  // Add this method to set guardhouse as destination
  void _setDestinationToGuardhouse(Guardhouse guardhouse) {
    setState(() {
      _destination = guardhouse.name;
      _destinationLatLng = guardhouse.location;

      // Remove existing destination marker and add new one
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'destination',
      );
      
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: guardhouse.location,
          infoWindow: InfoWindow(
            title: 'Destination: ${guardhouse.name}',
            snippet: guardhouse.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );

      // Get directions to guardhouse
      _getDirectionsToDestination();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Destination set to: ${guardhouse.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }


  // Add this method to highlight nearest guardhouses during SOS
  void _highlightNearestGuardhouses() {
    if (_currentPosition == null || _guardhouses.isEmpty) return;

    // Calculate distances and sort guardhouses by proximity
    List<MapEntry<Guardhouse, double>> guardhousesWithDistance = 
        _guardhouses.map((guardhouse) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        guardhouse.location.latitude,
        guardhouse.location.longitude,
      );
      return MapEntry(guardhouse, distance);
    }).toList();

    // Sort by distance (closest first)
    guardhousesWithDistance.sort((a, b) => a.value.compareTo(b.value));

    // Take only the 3 nearest guardhouses
    List<Guardhouse> nearestGuardhouses = guardhousesWithDistance
        .take(3)
        .map((entry) => entry.key)
        .toList();

    // Remove existing guardhouse markers and add highlighted ones
    _markers.removeWhere(
      (marker) => marker.markerId.value.startsWith('guardhouse_'),
    );

    // Add highlighted markers for nearest guardhouses
    for (int i = 0; i < nearestGuardhouses.length; i++) {
      var guardhouse = nearestGuardhouses[i];
      double distanceKm = guardhousesWithDistance
          .firstWhere((entry) => entry.key.id == guardhouse.id)
          .value / 1000;

      _markers.add(
        Marker(
          markerId: MarkerId('emergency_guardhouse_${guardhouse.id}'),
          position: guardhouse.location,
          infoWindow: InfoWindow(
            title: '🚨 ${guardhouse.name}',
            snippet: '${guardhouse.address}\n${distanceKm.toStringAsFixed(2)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange, // Orange for emergency guardhouses
          ),
          onTap: () => _onEmergencyGuardhouseTap(guardhouse, distanceKm),
        ),
      );
    }
  }

  // Add this method to handle emergency guardhouse marker taps
  void _onEmergencyGuardhouseTap(Guardhouse guardhouse, double distanceKm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(guardhouse.name)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Emergency Guardhouse'),
              const SizedBox(height: 8),
              Text('Address: ${guardhouse.address}'),
              Text('Distance: ${distanceKm.toStringAsFixed(2)} km'),
              const SizedBox(height: 8),
              const Text(
                'This guardhouse has been automatically identified as one of the nearest emergency points.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _setDestinationToGuardhouse(guardhouse);
              },
              child: const Text('Navigate Here', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _initializeServices() {
    _locationService = LocationService();
    _webrtcService = WebRTCService();
    _sosService = SOSService(); // Changed from SOSService to EnhancedSOSService
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    _countdownTimer?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localRenderer.dispose();

    // Cleanup remote participants
    for (var participant in _remoteParticipants) {
      await participant.renderer.dispose();
      await participant.peerConnection?.close();
    }

    await _peerConnection?.close();
    _channel?.sink.close(status.goingAway);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 60;
      _isCountdownActive = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _isCountdownActive = false;
          timer.cancel();
          // Only trigger SOS if not already triggered
          if (!_isSOSTriggered) {
            _triggerSOS();
          }
        }
      });
    });
  }

  void _resetCountdown() {
    if (_isCountdownActive && !_isSOSTriggered) {
      _startCountdown();
    }
  }

  // In your videocall.dart, update the _triggerSOS method:

  void _triggerSOS() async {
    if (_isSOSTriggered) return;

    setState(() {
      _isSOSTriggered = true;
      _isCountdownActive = false;
    });

    _countdownTimer?.cancel();
    _showSOSAlert();
    _addEmergencyLocations();

    // Trigger SOS without files
    String? sosRequestId = await _sosService.triggerSOS(
      _currentPosition,
      additionalInfo: "Emergency triggered during video call",
    );

    if (sosRequestId != null) {
      print('✅ SOS triggered successfully: $sosRequestId');

      // Create backup
      await _sosService.createSOSBackup(sosRequestId);
    }
  }

void _manualSOSTrigger() {
  if (_isSOSTriggered) return; // Prevent multiple triggers

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'Emergency SOS',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to trigger SOS emergency alert?',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
            TextButton(
            child: const Text(
              'Trigger SOS',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              _triggerSOS(); // ✅ Call the same method as countdown
            },
          ),
        ],
      );
    },
  );
}



  void _fitMapToEmergencyLocations() {
    if (_mapController != null && _currentPosition != null) {
      // Calculate bounds to include current location and emergency locations
      double minLat = _currentPosition!.latitude;
      double maxLat = _currentPosition!.latitude;
      double minLng = _currentPosition!.longitude;
      double maxLng = _currentPosition!.longitude;

      // Expand bounds to include emergency locations (approximate nearby locations)
      minLat -= 0.01;
      maxLat += 0.01;
      minLng -= 0.01;
      maxLng += 0.01;

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    }
  }

  void _showSOSAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.red, size: 32),
              SizedBox(width: 8),
              Text(
                'SOS ACTIVATED',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency protocol has been activated!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('• Emergency contacts have been notified'),
              const Text('• Your location is being shared'),
              const Text('• Nearby guardhouse and stores are shown'),
              const Text('• Call recording has started'),
              const SizedBox(height: 12),
              const Text(
                'Stay calm. Help is on the way.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatCountdown(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initializeCall() async {
    try {
      await _initRenderers();
      await _getUserMedia();
      await _connectToServer();
    } catch (e) {
      _showError('Failed to initialize call: $e');
    }
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> _getUserMedia() async {
    try {
      _localStream = await _webrtcService.getUserMedia(_isFrontCamera);
      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      _showError('Failed to access camera/microphone: $e');
      rethrow;
    }
  }

  Future<void> _switchCamera() async {
    try {
      final newStream = await _webrtcService.switchCamera(
        !_isFrontCamera,
        _peerConnection,
      );

      // Stop current video tracks
      final oldVideoTracks = _localStream?.getVideoTracks();
      oldVideoTracks?.forEach((track) => track.stop());

      // Update local stream and renderer
      _localStream = newStream;
      _localRenderer.srcObject = _localStream;

      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    } catch (e) {
      _showError('Failed to switch camera: $e');
    }
  }

  Future<void> _connectToServer() async {
    try {
      setState(() {
        _connectionStatus = 'Connecting...';
      });

      _channel = IOWebSocketChannel.connect(
        SIGNALING_SERVER_URL,
        pingInterval: const Duration(seconds: 30),
      );

      _channel!.stream.listen(
        (message) async {
          try {
            Map<String, dynamic> data = jsonDecode(message);
            await _handleSignalingMessage(data);
          } catch (e) {
            print('Error parsing message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _connectionStatus = 'Connection Error';
            _isConnected = false;
          });
        },
        onDone: () {
          print('WebSocket connection closed');
          setState(() {
            _connectionStatus = 'Disconnected';
            _isConnected = false;
          });
        },
      );

      await _createPeerConnection();

      setState(() {
        _connectionStatus = 'Connected';
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection Failed';
      });
      _showError('Failed to connect to server: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await _webrtcService.createPeerConnection();

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    _peerConnection!.onIceCandidate = (candidate) {
      if (_channel != null && _isConnected) {
        _sendMessage({
          'type': 'candidate',
          'candidate': candidate.toMap(),
          'room': ROOM_ID,
        });
      }
    };

    _peerConnection!.onTrack = (event) async {
      if (event.streams.isNotEmpty) {
        final participantId = 'participant_${_remoteParticipants.length + 1}';
        final renderer = RTCVideoRenderer();
        await renderer.initialize();

        final participant = Participant(
          id: participantId,
          name: 'Participant ${_remoteParticipants.length + 1}',
          renderer: renderer,
          peerConnection: _peerConnection,
        );

        participant.renderer.srcObject = event.streams[0];

        setState(() {
          _remoteParticipants.add(participant);
          _isCallActive = true;
        });
      }
    };

    _peerConnection!.onConnectionState = (state) {
      print('Connection state: $state');
      setState(() {
        _connectionStatus = state.toString();
      });
    };
  }

  Future<void> _getCurrentLocation() async {
    try {
      final result = await _locationService.getCurrentLocation();

      if (result != null && mounted) {
        setState(() {
          _currentPosition = result['position'];
          _currentAddress = result['address'];
          _isLoadingLocation = false;
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(
                result['position'].latitude,
                result['position'].longitude,
              ),
              infoWindow: InfoWindow(
                title: 'Your Location',
                snippet: result['address'],
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          );
        });

        // Move camera to current location when available
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  result['position'].latitude,
                  result['position'].longitude,
                ),
                zoom: 15.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Unable to get location';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getDirectionsToDestination() async {
    if (_currentPosition == null || _destinationLatLng == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      LatLng origin = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      RouteInfo? routeInfo = await GoogleMapsService.getDirections(
        origin,
        _destinationLatLng!,
      );

      if (routeInfo != null) {
        setState(() {
          _routeInfo = routeInfo;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: routeInfo.polylinePoints,
            ),
          };
        });

        // Fit map to show both origin and destination
        _fitMapToRoute(origin, _destinationLatLng!);
      }
    } catch (e) {
      _showError('Failed to get directions: $e');
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _fitMapToRoute(LatLng origin, LatLng destination) {
    if (_mapController != null) {
      double minLat = origin.latitude < destination.latitude
          ? origin.latitude
          : destination.latitude;
      double maxLat = origin.latitude > destination.latitude
          ? origin.latitude
          : destination.latitude;
      double minLng = origin.longitude < destination.longitude
          ? origin.longitude
          : destination.longitude;
      double maxLng = origin.longitude > destination.longitude
          ? origin.longitude
          : destination.longitude;

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - 0.01, minLng - 0.01),
            northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
          ),
          100.0, // padding
        ),
      );
    }
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> data) async {
    switch (data['type']) {
      case 'offer':
        await _handleOffer(data);
        break;
      case 'answer':
        await _handleAnswer(data);
        break;
      case 'candidate':
        await _handleCandidate(data);
        break;
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp'], 'offer'),
      );
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _sendMessage({'type': 'answer', 'sdp': answer.sdp, 'room': ROOM_ID});
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp'], 'answer'),
      );
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  Future<void> _handleCandidate(Map<String, dynamic> data) async {
    try {
      dynamic candidate = data['candidate'];
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        ),
      );
    } catch (e) {
      print('Error handling candidate: $e');
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  Future<void> _startCall() async {
    try {
      if (_peerConnection != null) {
        RTCSessionDescription offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        _sendMessage({'type': 'offer', 'sdp': offer.sdp, 'room': ROOM_ID});
      }
    } catch (e) {
      _showError('Failed to start call: $e');
    }
  }

  void _toggleMute() {
    if (_localStream != null) {
      bool enabled = _isMuted; // If currently muted, enable audio
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
      setState(() {
        _isMuted = !enabled; // Update mute state
      });

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMuted ? 'Microphone muted' : 'Microphone unmuted'),
          duration: const Duration(seconds: 1),
          backgroundColor: _isMuted ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _toggleVideo() {
    if (_localStream != null) {
      bool enabled = !_isVideoEnabled;
      _localStream!.getVideoTracks().forEach((track) {
        track.enabled = enabled;
      });
      setState(() {
        _isVideoEnabled = enabled;
      });
    }
  }

  void _endCall() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Call'),
          content: const Text('Are you sure you want to end the call?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'End Call',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          ],
        );
      },
    );
  }

 void _showDestinationDialog() {
  showDialog(
    context: context,
    builder: (context) => DestinationDialog(
      currentPosition: _currentPosition,
      guardhouses: _guardhouses,
      onDestinationSelected: (destination, latLng, routeType) {
        _handleDestinationSelection(destination, latLng, routeType);
      },
    ),
  );
}

// Add this new method to handle destination selection:
void _handleDestinationSelection(String destination, LatLng? latLng, RouteType routeType) {
  setState(() {
    _destination = destination;
    _destinationLatLng = latLng;
    _currentRouteType = routeType;
  });

  if (latLng != null) {
    // Clear existing destination and route markers
    _markers.removeWhere(
      (marker) => marker.markerId.value == 'destination' || 
                  marker.markerId.value.startsWith('route_'),
    );
    
    // Add destination marker with appropriate styling based on route type
    Color markerColor;
    String markerTitle;
    
    switch (routeType) {
      case RouteType.nearestGuardhouse:
        markerColor = Colors.green[700]!;
        markerTitle = 'Nearest Guardhouse';
        break;
      case RouteType.specificGuardhouse:
        markerColor = Colors.blue[700]!;
        markerTitle = 'Selected Guardhouse';
        break;
      case RouteType.custom:
      default:
        markerColor = Colors.red;
        markerTitle = 'Destination';
        break;
    }
    
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: latLng,
        infoWindow: InfoWindow(
          title: markerTitle,
          snippet: destination,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getHueFromColor(markerColor),
        ),
      ),
    );

    // Get directions
    _getDirectionsToDestination();
    
    // Show appropriate success message
    String message;
    Color snackBarColor;
    
    switch (routeType) {
      case RouteType.nearestGuardhouse:
        message = 'Route set to nearest guardhouse: $destination';
        snackBarColor = Colors.green;
        break;
      case RouteType.specificGuardhouse:
        message = 'Route set to guardhouse: $destination';
        snackBarColor = Colors.blue;
        break;
      case RouteType.custom:
      default:
        message = 'Destination set to: $destination';
        snackBarColor = Colors.orange;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForRouteType(routeType),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: snackBarColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Add helper methods:
double _getHueFromColor(Color color) {
  if (color == Colors.red) return BitmapDescriptor.hueRed;
  if (color == Colors.green[700]) return BitmapDescriptor.hueGreen;
  if (color == Colors.blue[700]) return BitmapDescriptor.hueBlue;
  return BitmapDescriptor.hueRed;
}

IconData _getIconForRouteType(RouteType routeType) {
  switch (routeType) {
    case RouteType.nearestGuardhouse:
      return Icons.near_me;
    case RouteType.specificGuardhouse:
      return Icons.security;
    case RouteType.custom:
    default:
      return Icons.place;
  }
}

// Add a route selection widget to your build method:
Widget _buildRouteSelectionWidget() {
  if (_guardhouses.isEmpty) return const SizedBox.shrink();
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.alt_route,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Quick Route Options:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _routeToNearestGuardhouse(),
          icon: const Icon(Icons.security, size: 16),
          label: const Text('Nearest Guard', style: TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ),
  );
}

// Add method to quickly route to nearest guardhouse:
void _routeToNearestGuardhouse() {
  if (_guardhouses.isEmpty || _currentPosition == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No guardhouses available or location not found'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Find nearest guardhouse
  Guardhouse? nearest;
  double minDistance = double.infinity;

  for (var guardhouse in _guardhouses) {
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      guardhouse.location.latitude,
      guardhouse.location.longitude,
    );

    if (distance < minDistance) {
      minDistance = distance;
      nearest = guardhouse;
    }
  }

  if (nearest != null) {
    _handleDestinationSelection(
      'Nearest Guardhouse: ${nearest.name}',
      nearest.location,
      RouteType.nearestGuardhouse,
    );
  }
}

// Update the SOS emergency locations method to show route selection:
void _addEmergencyLocations() {
  if (_currentPosition == null) return;

  setState(() {
    // Clear existing markers except current location
    _markers.removeWhere(
      (marker) => marker.markerId.value != 'current_location',
    );

    // Re-add current location with SOS styling
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Your Location (SOS ACTIVE)',
          snippet: _currentAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Show nearest guardhouses during SOS
    _highlightNearestGuardhouses();
    
    // Auto-route to nearest guardhouse during SOS
    _routeToNearestGuardhouse();
  });

  _fitMapToEmergencyLocations();
}

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetCountdown,
      child: Scaffold(
        backgroundColor: _isSOSTriggered
            ? Colors.red[900]
            : Colors.black, // Changed background color
        body: SafeArea(
          child: Column(
            children: [
              // Top control bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isSOSTriggered
                            ? Colors.white
                            : _isCountdownActive
                            ? (_countdownSeconds <= 10
                                  ? Colors.red
                                  : Colors.white.withOpacity(0.9))
                            : Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _isSOSTriggered
                            ? 'SOS ACTIVE!'
                            : _isCountdownActive
                            ? _formatCountdown(_countdownSeconds)
                            : 'SOS!',
                        style: TextStyle(
                          color: _isSOSTriggered
                              ? Colors.red
                              : _isCountdownActive
                              ? (_countdownSeconds <= 10
                                    ? Colors.white
                                    : Colors.black)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${_remoteParticipants.length + 1} participants',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Warning message
              if (!_isSOSTriggered)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap anywhere to reset timer or SOS will step in to keep you safe',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // SOS Status message when triggered
              if (_isSOSTriggered)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.emergency, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SOS EMERGENCY ACTIVATED - Emergency locations shown on map',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Google Maps section (at the top)
             Expanded(
  flex: 2,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GoogleMapWidget(
      currentPosition: _currentPosition,
      markers: _markers,
      polylines: _polylines,
      routeInfo: _routeInfo,
      isLoadingRoute: _isLoadingRoute,
      destination: _destination,
      isSOSActive: _isSOSTriggered, // Add this line
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      onDestinationPressed: _showDestinationDialog,
      onRecenterPressed: () {
        if (_mapController != null && _currentPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15.0,
              ),
            ),
          );
        }
      },
    ),
  ),
),

              const SizedBox(height: 8),

              // Participant grid (camera section in middle)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ParticipantGrid(
                    localRenderer: _localRenderer,
                    remoteParticipants: _remoteParticipants,
                    isFrontCamera: _isFrontCamera,
                    isVideoEnabled: _isVideoEnabled,
                    isMuted: _isMuted,
                  ),
                ),
              ),

              // SOS Button - positioned below camera section
              SOSButton(
                isSOSTriggered: _isSOSTriggered,
                onSOSPressed: _manualSOSTrigger,
              ),
            ],
          ),
        ),
        // Add the control bar at the bottom
        bottomNavigationBar: ControlBar(
          isMuted: _isMuted,
          isVideoEnabled: _isVideoEnabled,
          onMutePressed: _toggleMute,
          onVideoPressed: _toggleVideo,
          onSwitchCameraPressed: _switchCamera,
          onEndCallPressed: _endCall,
        ),
      ),
    );
    
  }
}


