// File: lib/permissions_wrapper.dart

import 'package:flutter/material.dart';
import 'wrapper.dart';
import 'videocall.dart';
import 'destination_dialog.dart';
import 'service/maps_service.dart';
import 'videomain.dart';

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
