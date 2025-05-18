import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../services/image_rotation_service.dart';
import '../widgets/image_rotation_controls.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late String _currentImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _rotateImage(int angleDegrees) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String rotatedImagePath = await ImageRotationService.rotateImage(
        _currentImagePath, 
        angleDegrees
      );
      
      setState(() {
        _currentImagePath = rotatedImagePath;
        _isLoading = false;
      });
      
      // Return the updated image path when popping the screen
      Navigator.pop(context, _currentImagePath);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rotate image: $e')),
      );
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Preview'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _currentImagePath);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Image.file(
                      File(_currentImagePath),
                      fit: BoxFit.contain,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ImageRotationControls(
                onRotateLeft: () => _rotateImage(-90),
                onRotateRight: () => _rotateImage(90),
              ),
            ),
          ],
        ),
      ),
    );
  }
}