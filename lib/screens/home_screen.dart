import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scan/services/api_service.dart';

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

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
    }
  }
  /// Removing the imae selected
  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  //idts aisa situation ayega but incase error ata hai
  Future<void> _sendImage() async {
    if (_image == null) {
      _showSnackBar('Please take a picture first', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.uploadImage(_image!);
      
      if (response.statusCode == 200) {
        _showSnackBar('Image uploaded successfully', isSuccess: true);
        _removeImage(); 
      } else {
        _showSnackBar('Failed to upload image: ${response.statusCode}', isSuccess: false);
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
        duration: const Duration(seconds: 5), ///please edit as per preference
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Image'),
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
                  ),
                  ///image m
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
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _takePicture,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Take Picture'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
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
                          ],
                        ),
                ),
              ),
              ///response 
              const SizedBox(height: 24),
              if (_image != null)
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
                  label: Text(_isLoading ? 'Sending...' : 'Send Image'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
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
}