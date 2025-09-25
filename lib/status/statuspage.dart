import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bottom_navigation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'status_data.dart';
import 'status.dart';
import '../services/firebase_service.dart'; // Add this import

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  int _selectedIndex = 2;
  final List<bool> _checkboxValues = [false, false, false, false, false, false];
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingLocation = false;
  bool _useGpsLocation = false;
  List<String> _selectedFriends = [];
  List<bool> _selectedGroups = [true, false, false]; // default: Friends
  bool _isUploading = false; // Add loading state for upload

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadFriendsList(); // Load friends list
  }

  Future<void> _loadFriendsList() async {
    try {
      List<String> friends = await FirebaseService.getFriendsList();
      setState(() {
        // You can use this friends list in your friend picker
        print('Loaded ${friends.length} friends');
      });
    } catch (e) {
      print('Error loading friends: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationController.text = 'Getting your location...';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationController.text = 'Location services are disabled. Please enable them.';
          _isLoadingLocation = false;
        });
        _showLocationError('Location services are disabled. Please enable location services in your device settings.');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationController.text = 'Location permission denied. Please enter manually.';
            _isLoadingLocation = false;
          });
          _showLocationError('Location permissions are denied. Please grant permission or enter location manually.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationController.text = 'Location permission permanently denied. Please enter manually.';
          _isLoadingLocation = false;
        });
        _showLocationError('Location permissions are permanently denied. Please enable them in app settings or enter location manually.');
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Convert coordinates to address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          Placemark place = placemarks.first;
          String address = _formatAddress(place);

          setState(() {
            _locationController.text = address;
            _isLoadingLocation = false;
          });
        } else {
          throw Exception('No address found');
        }
      } catch (geocodingError) {
        // Fallback to coordinates if geocoding fails
        setState(() {
          _locationController.text = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
          _isLoadingLocation = false;
        });
        print('Geocoding error: $geocodingError');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationController.text = 'Unable to get location. Please enter manually.';
          _isLoadingLocation = false;
        });
        _showLocationError('Error getting location: ${e.toString()}');
      }
      print("Error getting location: $e");
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown location';
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _getCurrentLocation,
          ),
        ),
      );
    }
  }

  void _pickFriends() async {
    // TODO: Implement proper friend picker dialog
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelectedFriends = List.from(_selectedFriends);
        List<String> availableFriends = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve']; // Replace with actual friends from Firebase

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Mention Friends'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableFriends.length,
                  itemBuilder: (context, index) {
                    String friend = availableFriends[index];
                    bool isSelected = tempSelectedFriends.contains(friend);
                    return CheckboxListTile(
                      title: Text(friend),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedFriends.add(friend);
                          } else {
                            tempSelectedFriends.remove(friend);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedFriends = tempSelectedFriends;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getSelectedVisibility() {
    for (int i = 0; i < _selectedGroups.length; i++) {
      if (_selectedGroups[i]) {
        switch (i) {
          case 0:
            return 'Friends';
          case 1:
            return 'Community';
          case 2:
            return 'Public';
        }
      }
    }
    return 'Friends'; // Default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: const Color(0xFF3075FF),
        elevation: 0,
        title: const Text(
          'Create A Status',
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Blue header card sticks to AppBar
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3075FF),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/writingdog.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Drop a little status',
                                style: TextStyle(
                                  fontFamily: 'tiltWarp',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Let your friends join your journey~',
                                style: TextStyle(
                                  fontFamily: 'SF Pro',
                                  fontSize: 14,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Picture upload box (above issue text)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPictureBox(),
                ),

                const SizedBox(height: 16),

                // Issue text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTextField(
                    controller: _issueController,
                    hintText: 'Say Something...',
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 16),

                // Address Section
                Divider(thickness: 1, color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Address", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Text("Use GPS"),
                                Switch(
                                  value: _useGpsLocation,
                                  onChanged: (value) {
                                    setState(() {
                                      _useGpsLocation = value;
                                      if (_useGpsLocation) {
                                        _getCurrentLocation();
                                      } else {
                                        _locationController.clear();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!_useGpsLocation)
                        _buildTextField(
                          controller: _locationController,
                          hintText: 'Enter address manually...',
                          maxLines: 1,
                        ),
                      if (_useGpsLocation)
                        Row(
                          children: [
                            _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Expanded(
                                    child: Text(
                                      _locationController.text.isNotEmpty
                                          ? _locationController.text
                                          : "Fetching location...",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                            IconButton(
                              icon: const Icon(Icons.my_location, color: Colors.blue),
                              onPressed: _getCurrentLocation,
                              tooltip: 'Refresh location',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Mention Section
                Divider(thickness: 1, color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedFriends.isNotEmpty
                              ? "Mentioned: ${_selectedFriends.join(', ')}"
                              : "No friends mentioned",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickFriends,
                        icon: const Icon(Icons.alternate_email, size: 18),
                        label: const Text("Mention"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Group Visibility Section
                Divider(thickness: 1, color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Share with", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ToggleButtons(
                        isSelected: _selectedGroups,
                        onPressed: (index) {
                          setState(() {
                            for (int i = 0; i < _selectedGroups.length; i++) {
                              _selectedGroups[i] = i == index;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("Friends"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("Community"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("Public"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitStatus, // Disable when uploading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUploading ? Colors.grey : const Color(0xFF3075FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Uploading...'),
                              ],
                            )
                          : const Text(
                              'Post',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Uploading your status...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPictureBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickMultipleImages,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: _selectedImages.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.grey,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _submitStatus() async {
    if (_isUploading) return;

    final String issue = _issueController.text.trim();
    final String location = _locationController.text.trim();
    
    if (issue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text for your status'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload to Firebase
      bool success = await FirebaseService.uploadStatus(
        issueText: issue,
        images: _selectedImages,
        location: location,
        selectedFriends: _selectedFriends,
        visibility: _getSelectedVisibility(),
      );

      if (success) {
        // Also add to local storage for immediate UI update
        final newStatus = Status(
          issueText: issue,
          imagePaths: _selectedImages.map((file) => file.path).toList(),
          location: location,
        );

        List<Status> updatedList = List.from(statusHistory.value);
        updatedList.add(newStatus);
        statusHistory.value = updatedList;

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to upload status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }

    // Clear form after successful upload
    _issueController.clear();
    _locationController.clear();
    _selectedImages.clear();
    _selectedFriends.clear();
    setState(() {
      for (int i = 0; i < _checkboxValues.length; i++) {
        _checkboxValues[i] = false;
      }
      _selectedGroups = [true, false, false]; // Reset to Friends
    });
  }

  @override
  void dispose() {
    _issueController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}