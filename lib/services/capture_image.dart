import 'dart:io';
import 'package:camera/camera.dart';
import 'package:docify/services/camera_macos_photo_capture.dart';
import 'package:flutter/material.dart';
import 'package:camera_macos/camera_macos.dart'
    if (dart.library.html) 'package:camera/camera.dart';

class ImagePickerService {
  static Future<File?> pickImage(BuildContext context) async {
    if (Platform.isMacOS) {
      print("capturing image in macos");
      return _pickImageMacOS(context);
    } else if (Platform.isWindows) {
      print("capturing image in windows");
      return _pickImageWindows(context);
    } else {
      _showErrorDialog(context, 'Platform not supported for camera capture');
      return null;
    }
  }

  /// Pick image using camera_macos package on macOS
  static Future<File?> _pickImageMacOS(BuildContext context) async {
    try {
      return await MacOSPhotoCaptureDialog.show(
        context,
        resolution: PictureResolution.low,
        format: PictureFormat.jpg,
      );
    } catch (e) {
      _showErrorDialog(context, 'Error capturing image: $e');
      return null;
    }
  }

  /// Pick image using camera package on Windows
  static Future<File?> _pickImageWindows(BuildContext context) async {
    try {
      // Import the camera package
      // Note: This requires 'camera: ^0.11.0' in your pubspec.yaml
      // and import 'package:camera/camera.dart' at the top of the file

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorDialog(context, 'No cameras found');
        return null;
      }

      // Use the first camera (usually front camera)
      final firstCamera = cameras.first;

      // Show camera preview dialog for Windows
      final XFile? imageFile = await showDialog<XFile>(
        context: context,
        builder: (context) => WindowsCameraDialog(camera: firstCamera),
      );

      if (imageFile == null) {
        return null;
      }

      return File(imageFile.path);
    } catch (e) {
      _showErrorDialog(context, 'Error capturing image: $e');
      return null;
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Windows camera preview dialog using the camera package
class WindowsCameraDialog extends StatefulWidget {
  final CameraDescription camera;

  const WindowsCameraDialog({super.key, required this.camera});

  @override
  State<WindowsCameraDialog> createState() => _WindowsCameraDialogState();
}

class _WindowsCameraDialogState extends State<WindowsCameraDialog> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();

    // Initialize the camera controller
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;

      final XFile image = await _controller.takePicture();

      if (!mounted) return;

      Navigator.of(context).pop(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 640,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Take a Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller);
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _takePicture,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_isCapturing ? 'Processing...' : 'Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
