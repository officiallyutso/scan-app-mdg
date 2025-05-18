import 'package:flutter/material.dart';

class ImageRotationControls extends StatelessWidget {
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;

  const ImageRotationControls({
    Key? key,
    required this.onRotateLeft,
    required this.onRotateRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.rotate_left),
          onPressed: onRotateLeft,
          tooltip: 'Rotate Left',
          iconSize: 32,
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.rotate_right),
          onPressed: onRotateRight,
          tooltip: 'Rotate Right',
          iconSize: 32,
        ),
      ],
    );
  }
}