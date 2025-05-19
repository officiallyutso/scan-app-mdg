import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scan/services/api_service.dart';
import 'image_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// homescreene class stf extending
class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  String? _selectedDocType;
  Map<String, dynamic>? _personDetails;

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _selectedDocType = null;
      });
    }
  }
  
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _image = File(image.path);
        _selectedDocType = null;
      });
    }
  }
  
  /// Navigate to image preview screen for rotation
  void _openImagePreview() {
    if (_image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(
            imagePath: _image!.path,
          ),
        ),
      ).then((updatedImagePath) {
        if (updatedImagePath != null) {
          setState(() {
            _image = File(updatedImagePath);
          });
        }
      });
    }
  }
  
  /// Removing the image selected
  void _removeImage() {
    setState(() {
      _image = null;
      _selectedDocType = null;
      _personDetails = null;
    });
  }

  // Select document type
  void _selectDocType(String type) {
    setState(() {
      _selectedDocType = type;
    });
  }

  //idts aisa situation ayega but incase error ata hai
  Future<void> _sendImage() async {
    if (_image == null) {
      _showSnackBar('Please take a picture first', isSuccess: false);
      return;
    }

    if (_selectedDocType == null) {
      _showSnackBar('Please select document type', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
      _personDetails = null;
    });

    try {
      final response = await _apiService.uploadImage(_image!, _selectedDocType!);
      
      if (response['success']) {
        _showSnackBar(
          'Registration successful!', 
          isSuccess: true
        );
        
        // Get person details from the backend
        try {
          final detailsResponse = await _apiService.getPersonDetails(response['aadharNumber']);
          setState(() {
            _personDetails = detailsResponse;
          });
        } catch (e) {
          print('Error fetching person details: $e');
          setState(() {
            _personDetails = {
              'aadharNumber': response['aadharNumber'],
              'name': 'Not available',
              'dob': 'Not available',
              'gender': 'Not available',
            };
          });
        }
        
      } else {
        _showSnackBar('Failed to upload image: ${response['message']}', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isSuccess: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ////snackbar error/success message showing
  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5), ///please edit as per your preference phoenix
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Image'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _image == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_search,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No image selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _takePicture,
                                    icon: const Icon(Icons.camera_alt, size: 28, color: Color.fromRGBO(242, 241, 241, 1)),
                                    label: const Text(
                                      'Take Picture',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromRGBO(255, 255, 255, 1),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 3,
                                      minimumSize: const Size(240, 56),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _pickImageFromGallery,
                                    icon: const Icon(Icons.photo_library, size: 28),
                                    label: const Text(
                                      'Upload from Gallery',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                      side: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      minimumSize: const Size(240, 56),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Material(
                                color: Colors.white.withOpacity(0.8),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _removeImage,
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ////rotate button
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Material(
                                color: Colors.white.withOpacity(0.8),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _openImagePreview,
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.rotate_right,
                                      color: Color(0xFF4A6572),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              // Person details section - show after successful scan
              if (_personDetails != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Person Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A6572),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildDetailRow('Aadhar Number', _personDetails!['aadharNumber'] ?? 'Not available'),
                      
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            label: const Text('Scan New', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              // Document type selection section
              if (_image != null && _personDetails == null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Select Document Type:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDocTypeOption(
                              'Digilocker',
                              Icons.folder_shared,
                              _selectedDocType == 'Digilocker',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDocTypeOption(
                              'Card',
                              Icons.document_scanner,
                              _selectedDocType == 'Card',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              // Send button
              const SizedBox(height: 24),
              if (_image != null && _personDetails == null)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendImage,
                  icon: _isLoading
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? 'Sending...' : 'Send Image',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  ///documenttype widget
  Widget _buildDocTypeOption(String title, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () => _selectDocType(title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  ///widegte for person details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}