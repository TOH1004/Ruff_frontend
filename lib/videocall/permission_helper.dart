import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionsHelper {
  static const MethodChannel _channel = MethodChannel('permissions');

  /// Request camera and microphone permissions
  static Future<bool> requestVideoCallPermissions() async {
    try {
      if (Platform.isAndroid) {
        return await _requestAndroidPermissions();
      } else if (Platform.isIOS) {
        return await _requestIOSPermissions();
      }
      return true; // For web or other platforms
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<bool> _requestAndroidPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod('requestPermissions', {
        'permissions': ['CAMERA', 'RECORD_AUDIO']
      });
      return result ?? false;
    } catch (e) {
      print('Android permission error: $e');
      return false;
    }
  }

  static Future<bool> _requestIOSPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod('requestPermissions', {
        'permissions': ['camera', 'microphone']
      });
      return result ?? false;
    } catch (e) {
      print('iOS permission error: $e');
      return false;
    }
  }

  /// Show a dialog explaining why permissions are needed
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

  /// Check if all required permissions are granted
  static Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final bool? result = await _channel.invokeMethod('checkPermissions', {
          'permissions': Platform.isAndroid 
            ? ['CAMERA', 'RECORD_AUDIO']
            : ['camera', 'microphone']
        });
        return result ?? false;
      }
      return true; // For web or other platforms
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }
}

/// Widget to handle permissions before starting video call
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
      // First check if permissions are already granted
      bool hasPermissions = await PermissionsHelper.checkPermissions();
      
      if (!hasPermissions) {
        // Show explanation dialog
        bool userAccepted = await PermissionsHelper.showPermissionDialog(context);
        
        if (userAccepted) {
          // Request permissions
          hasPermissions = await PermissionsHelper.requestVideoCallPermissions();
        }
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking permissions...'),
            ],
          ),
        ),
      );
    }

    if (!_hasPermissions) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permissions Required')),
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
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkAndRequestPermissions,
                child: const Text('Grant Permissions'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}