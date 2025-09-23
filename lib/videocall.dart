import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Permission helper classes for video call
class PermissionsHelper {
  static Future<bool> requestVideoCallPermissions() async {
    try {
      return true; 
    } catch (e) { 
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs access to your camera and microphone to make video calls. '
            'Please grant these permissions to continue.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Grant Permissions'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
}

class VideoCallPermissionWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPermissionDenied;

  const VideoCallPermissionWrapper({
    super.key,
    required this.child,
    this.onPermissionDenied,
  });

  @override
  State<VideoCallPermissionWrapper> createState() => _VideoCallPermissionWrapperState();
}

class _VideoCallPermissionWrapperState extends State<VideoCallPermissionWrapper> {
  bool _isCheckingPermissions = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      bool userAccepted = await PermissionsHelper.showPermissionDialog(context);
      
      bool hasPermissions = false;
      if (userAccepted) {
        hasPermissions = await PermissionsHelper.requestVideoCallPermissions();
      }

      setState(() {
        _hasPermissions = hasPermissions;
        _isCheckingPermissions = false;
      });

      if (!hasPermissions && widget.onPermissionDenied != null) {
        widget.onPermissionDenied!();
      }
    } catch (e) {
      print('Permission check error: $e');
      setState(() {
        _hasPermissions = false;
        _isCheckingPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Checking permissions...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (!_hasPermissions) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Permissions Required'),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera and microphone permissions are required for video calls.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkAndRequestPermissions,
                child: const Text('Grant Permissions'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

// Destination Selection Dialog
class DestinationDialog extends StatefulWidget {
  final Function(String) onDestinationSelected;

  const DestinationDialog({super.key, required this.onDestinationSelected});

  @override
  State<DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<DestinationDialog> {
  final TextEditingController _destinationController = TextEditingController();
  final List<String> _quickDestinations = [
    'Home',
    'Campus Main Gate',
    'Library',
    'Dormitory',
    'Student Center',
    'Hospital',
    'Police Station',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set Destination',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Custom destination input
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Enter destination',
                hintText: 'e.g., 123 Main St, City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {
                if (_destinationController.text.isNotEmpty) {
                  widget.onDestinationSelected(_destinationController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Set Custom Destination'),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Quick Destinations:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Quick destination buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickDestinations.map((destination) {
                return OutlinedButton(
                  onPressed: () {
                    widget.onDestinationSelected(destination);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(destination),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Participant model for video call
class Participant {
  final String id;
  final String name;
  final RTCVideoRenderer renderer;
  final RTCPeerConnection? peerConnection;
  bool isAudioMuted;
  bool isVideoEnabled;

  Participant({
    required this.id,
    required this.name,
    required this.renderer,
    this.peerConnection,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
  });
}

const SIGNALING_SERVER_URL = 'wss://ruff-ox2a.onrender.com';
const ROOM_ID = 'test-room';

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
  bool _isLoadingLocation = true;
  
  // Countdown functionality
  Timer? _countdownTimer;
  int _countdownSeconds = 60;
  bool _isCountdownActive = true;

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _getCurrentLocation();
    _startCountdown();
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
          _triggerSOS();
        }
      });
    });
  }

  void _resetCountdown() {
    if (_isCountdownActive) {
      _startCountdown();
    }
  }

  void _triggerSOS() {
    _showError('SOS EMERGENCY ACTIVATED - No response detected!');
    // Add SOS emergency logic here
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
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'width': 640,
          'height': 480,
          'facingMode': _isFrontCamera ? 'user' : 'environment',
        },
      });

      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      _showError('Failed to access camera/microphone: $e');
      rethrow;
    }
  }

Future<void> _switchCamera() async {
  try {
    // 1. Get new media with the opposite camera first
    final newStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'width': 640,
        'height': 480,
        'facingMode': !_isFrontCamera ? 'user' : 'environment', // opposite of current
      },
    });

    // 2. Replace video track in peer connection
    if (_peerConnection != null) {
      final senders = await _peerConnection!.getSenders();
      final videoSender = senders.firstWhere(
        (s) => s.track?.kind == 'video',
        orElse: () => throw Exception('Video sender not found'),
      );
      await videoSender.replaceTrack(newStream.getVideoTracks().first);
    }

    // 3. Stop current video tracks after new stream is ready
    final oldVideoTracks = _localStream?.getVideoTracks();
    oldVideoTracks?.forEach((track) => track.stop());

    // 4. Update local stream and renderer
    _localStream = newStream;
    _localRenderer.srcObject = _localStream;

    // 5. Finally, update the camera flag
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

  } catch (e) {
    _showError('Failed to switch camera: $e');
    print('Camera switch error: $e');
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
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject'
        },
      ],
      'iceCandidatePoolSize': 10,
    };

    _peerConnection = await createPeerConnection(configuration);

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Location services disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;
        String address = '${place.street}, ${place.locality}';

        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Unable to get location';
        _isLoadingLocation = false;
      });
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
      _sendMessage({
        'type': 'answer',
        'sdp': answer.sdp,
        'room': ROOM_ID,
      });
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
        _sendMessage({
          'type': 'offer',
          'sdp': offer.sdp,
          'room': ROOM_ID,
        });
      }
    } catch (e) {
      _showError('Failed to start call: $e');
    }
  }

  void _toggleMute() {
    if (_localStream != null) {
      bool enabled = !_isMuted;
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
      setState(() {
        _isMuted = !enabled;
      });
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
              child: const Text('End Call', style: TextStyle(color: Colors.red)),
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
        onDestinationSelected: (destination) {
          setState(() {
            _destination = destination;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Destination set to: $destination'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildParticipantGrid() {
    // Calculate grid dimensions based on number of participants
    int totalParticipants = _remoteParticipants.length + 1; // +1 for local
    int crossAxisCount = totalParticipants <= 2 ? 1 : 2;
    
    List<Widget> participantWidgets = [];
    
    // Add local participant (self)
    participantWidgets.add(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              RTCVideoView(_localRenderer, mirror: _isFrontCamera),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              if (!_isVideoEnabled)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Icon(Icons.videocam_off, color: Colors.white, size: 32),
                  ),
                ),
              if (_isMuted)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.mic_off, color: Colors.red, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
    
    // Add remote participants
    for (var participant in _remoteParticipants) {
      participantWidgets.add(
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                RTCVideoView(participant.renderer),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      participant.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                if (participant.isAudioMuted)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.mic_off, color: Colors.red, size: 20),
                  ),
                if (!participant.isVideoEnabled)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(Icons.videocam_off, color: Colors.white, size: 32),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: participantWidgets,
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute button
            GestureDetector(
              onTap: _toggleMute,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isMuted ? Colors.red : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Video on/off button
            GestureDetector(
              onTap: _toggleVideo,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: !_isVideoEnabled ? Colors.red : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Switch camera button
            GestureDetector(
              onTap: _switchCamera,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // End call button
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetCountdown,
      child: Scaffold(
        backgroundColor: Colors.black,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCountdownActive
                            ? (_countdownSeconds <= 10 ? Colors.red : Colors.white.withOpacity(0.9))
                            : Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _isCountdownActive ? _formatCountdown(_countdownSeconds) : 'SOS!',
                        style: TextStyle(
                          color: _isCountdownActive
                              ? (_countdownSeconds <= 10 ? Colors.white : Colors.black)
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

              const SizedBox(height: 16),

              // Map section
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                  ),
                  child: Stack(
                    children: [
                      // Map placeholder
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.blue[100]!, Colors.green[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: const [
                            // Current location marker
                            Positioned(
                              top: 80,
                              left: 120,
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            // Route indicator
                            Positioned(
                              top: 120,
                              right: 80,
                              child: Icon(
                                Icons.flag,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ETA info
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ETA: 8 min',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Destination button
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: ElevatedButton.icon(
                          onPressed: _showDestinationDialog,
                          icon: const Icon(Icons.place, size: 16),
                          label: Text(_destination ?? 'Set Destination'),
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
                    ],
                  ),
                ),
              ),

              // Participant grid
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildParticipantGrid(),
                ),
              ),
            ],
          ),
        ),
        // Add the control bar at the bottom
        bottomNavigationBar: _buildControlBar(),
      ),
    );
  }
}