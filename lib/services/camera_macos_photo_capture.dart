import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraMacOSPhotoCapture extends StatefulWidget {
  final Function(File imageFile, Uint8List imageBytes) onPhotoTaken;
  final double? width;
  final double? height;
  final PictureResolution resolution;
  final PictureFormat format;
  final bool isVideoMirrored;

  const CameraMacOSPhotoCapture({
    super.key,
    required this.onPhotoTaken,
    this.width,
    this.height,
    this.resolution = PictureResolution.max,
    this.format = PictureFormat.jpeg,
    this.isVideoMirrored = true,
  });

  @override
  State<CameraMacOSPhotoCapture> createState() =>
      _CameraMacOSPhotoCaptureState();
}

class _CameraMacOSPhotoCaptureState extends State<CameraMacOSPhotoCapture> {
  CameraMacOSController? _controller;
  List<CameraMacOSDevice> videoDevices = [];
  String? _selectedVideoDevice;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _destroyCamera();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devices = await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );

      setState(() {
        videoDevices = devices;
        if (devices.isNotEmpty) {
          _selectedVideoDevice = devices.first.deviceId;
          _isInitialized = true;
        }
      });
    } catch (e) {
      _showErrorDialog('Failed to initialize camera: ${e.toString()}',
          message: '');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _destroyCamera() async {
    try {
      if (_controller != null) {
        await _controller!.destroy();
        _controller = null;
      }
    } catch (e) {
      print('Error destroying camera: $e');
    }
  }

  Future<void> capturePhoto() async {
    if (_controller == null) {
      _showErrorDialog('Camera not initialized', message: '');
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final CameraMacOSFile? imageData = await _controller!.takePicture();

      if (imageData == null || imageData.bytes == null) {
        throw Exception('Failed to capture image');
      }

      final String filePath = await _getImageFilePath();
      final File imageFile = File(filePath);

      if (imageFile.existsSync()) {
        await imageFile.delete();
      }

      await imageFile.create(recursive: true);
      await imageFile.writeAsBytes(imageData.bytes!);

      widget.onPhotoTaken(imageFile, imageData.bytes!);
    } catch (e) {
      _showErrorDialog('Failed to capture photo: ${e.toString()}', message: '');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getImageFilePath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = widget.format.name.toLowerCase();
    return path.join(documentsDir.path, 'photo_$timestamp.$extension');
  }

  void _showErrorDialog(String s, {required String message}) {
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isInitialized && _selectedVideoDevice != null)
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: CameraMacOSView(
                    deviceId: _selectedVideoDevice,
                    cameraMode: CameraMacOSMode.photo,
                    resolution: widget.resolution,
                    pictureFormat: widget.format,
                    isVideoMirrored: widget.isVideoMirrored,
                    enableAudio: false,
                    onCameraInizialized: (controller) {
                      setState(() {
                        _controller = controller;
                      });
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : capturePhoto,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_isLoading ? 'Processing...' : 'Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_isLoading)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing camera...'),
              ],
            ),
          )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No camera available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeCamera,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class MacOSPhotoCaptureDialog extends StatelessWidget {
  final PictureResolution resolution;
  final PictureFormat format;
  final bool isVideoMirrored;

  const MacOSPhotoCaptureDialog({
    super.key,
    this.resolution = PictureResolution.max,
    this.format = PictureFormat.jpeg,
    this.isVideoMirrored = true,
  });

  static Future<File?> show(
    BuildContext context, {
    PictureResolution resolution = PictureResolution.max,
    PictureFormat format = PictureFormat.jpeg,
    bool isVideoMirrored = true,
  }) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => MacOSPhotoCaptureDialog(
        resolution: resolution,
        format: format,
        isVideoMirrored: isVideoMirrored,
      ),
    );
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CameraMacOSPhotoCapture(
                  resolution: resolution,
                  format: format,
                  isVideoMirrored: isVideoMirrored,
                  onPhotoTaken: (file, _) {
                    Navigator.of(context).pop(file);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A utility class for working with camera_macos
class CameraMacOSUtils {
  /// Gets a list of available video devices
  static Future<List<CameraMacOSDevice>> getVideoDevices() async {
    try {
      return await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );
    } catch (e) {
      print('Error getting video devices: $e');
      return [];
    }
  }

  /// Takes a photo with the specified device ID
  /// Takes a photo with the specified device ID
  static Future<File?> takePhoto({
    required String deviceId,
    PictureResolution resolution = PictureResolution.max,
    PictureFormat format = PictureFormat.jpeg,
    bool isVideoMirrored = true,
  }) async {
    CameraMacOSController? controller;
    Completer<CameraMacOSController> controllerCompleter = Completer();

    try {
      // Create a temporary widget to get the controller
      // final tempWidget = CameraMacOSView(
      //   deviceId: deviceId,
      //   cameraMode: CameraMacOSMode.photo,
      //   resolution: resolution,
      //   pictureFormat: format,
      //   isVideoMirrored: isVideoMirrored,
      //   enableAudio: false,
      //   onCameraInizialized: (initializedController) {
      //     controller = initializedController;
      //     controllerCompleter.complete(initializedController);
      //   },
      // );

      // You might need to insert this widget temporarily into your widget tree
      // or use a more direct method provided by the camera_macos package

      // Wait for the controller to be initialized
      controller = await controllerCompleter.future;

      final CameraMacOSFile? imageData = await controller.takePicture();
      if (imageData == null || imageData.bytes == null) {
        return null;
      }

      // Save the image to a file
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = format.name.toLowerCase();
      final filePath =
          path.join(documentsDir.path, 'photo_$timestamp.$extension');

      final file = File(filePath);
      await file.writeAsBytes(imageData.bytes!);

      return file;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    } finally {
      try {
        if (controller != null) {
          await controller.destroy();
        }
      } catch (e) {
        print('Error destroying camera controller: $e');
      }
    }
  }
}
