import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bottom_navigation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'report_data.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _selectedIndex = 2;
  final List<bool> _checkboxValues = [false, false, false, false, false, false];
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: const Color(0xFF3075FF),
        elevation: 0,
        title: const Text(
          'Report Issue',
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
      body: SingleChildScrollView(
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
                            'Share what you are facing',
                            style: TextStyle(
                              fontFamily: 'tiltWarp',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Drop your reports here and let us assist you!',
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
                hintText: 'Drop your issue here...',
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 16),

            // Location field with loading indicator and refresh button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _locationController,
                      hintText: 'Enter your location...',
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isLoadingLocation 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    tooltip: 'Get current location',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Checkboxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildCheckbox('Harassment', 0, isBold: true),
                  _buildCheckbox('Stalk', 1, isBold: true),
                  _buildCheckbox('Robbery', 2, isBold: true),
                  _buildCheckbox('Accidents', 3, isBold: true),
                  _buildCheckbox('Vehicle-related Danger', 4, isBold: true),
                  _buildCheckbox('Others', 5, isBold: true),
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
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3075FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
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

  Widget _buildCheckbox(String label, int index, {bool isBold = false}) {
    return CheckboxListTile(
      title: Text(
        label,
        style: isBold
            ? const TextStyle(fontWeight: FontWeight.bold)
            : const TextStyle(),
      ),
      value: index < _checkboxValues.length ? _checkboxValues[index] : false,
      onChanged: (value) {
        setState(() {
          _checkboxValues[index] = value!;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
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

  void _submitReport() {
    final String issue = _issueController.text;
    final String location = _locationController.text;

    // Collect selected options
    final List<String> selectedOptions = [];
    for (int i = 0; i < _checkboxValues.length; i++) {
      if (_checkboxValues[i]) {
        switch (i) {
          case 0:
            selectedOptions.add('Harassment');
            break;
          case 1:
            selectedOptions.add('Stalk');
            break;
          case 2:
            selectedOptions.add('Robbery');
            break;
          case 3:
            selectedOptions.add('Accidents');
            break;
          case 4:
            selectedOptions.add('Vehicle-related Danger');
            break;
          case 5:
            selectedOptions.add('Others');
            break;
        }
      }
    }

    final newReport = Report(
      issueText: issue,
      imagePaths: _selectedImages.map((file) => file.path).toList(),
      location: location,
    );

    List<Report> updatedList = List.from(reportHistory.value);
    updatedList.add(newReport);
    reportHistory.value = updatedList;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Submitted'),
        content: Text(
          'Issue: $issue\n'
          'Location: $location\n'
          'Selected options: ${selectedOptions.join(", ")}\n'
          'Images: ${_selectedImages.length} attached',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Clear form after submit
    _issueController.clear();
    _locationController.clear();
    _selectedImages.clear();
    setState(() {
      for (int i = 0; i < _checkboxValues.length; i++) {
        _checkboxValues[i] = false;
      }
    });
  }

  @override
  void dispose() {
    _issueController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}