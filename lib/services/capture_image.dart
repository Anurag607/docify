import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:docify/services/camera_macos_photo_capture.dart';
import 'package:flutter/material.dart';

import 'package:camera_macos/camera_macos.dart' as camera_macos;
import 'package:flutter/rendering.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';

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
        resolution: camera_macos.PictureResolution.low,
        format: camera_macos.PictureFormat.jpg,
      );
    } catch (e) {
      _showErrorDialog(context, 'Error capturing image: $e');
      return null;
    }
  }

  /// Pick image using camera package on Windows
  static Future<File?> _pickImageWindows(BuildContext context) async {
    return await showDialog<File>(
      context: context,
      builder: (ctx) => _WindowsCameraDialog(),
    );
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

class _WindowsCameraDialog extends StatefulWidget {
  @override
  State<_WindowsCameraDialog> createState() => _WindowsCameraDialogState();
}

class _WindowsCameraDialogState extends State<_WindowsCameraDialog> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final GlobalKey _previewContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _renderer.initialize();

    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
        'width': 640,
        'height': 480,
        'frameRate': 30,
      }
    };

    try {
      final stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      setState(() {
        _renderer.srcObject = stream;
      });
    } catch (e) {
      print("Camera initialization failed: $e");
    }
  }

  Future<File?> _captureImage() async {
    try {
      RenderRepaintBoundary boundary = _previewContainerKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 0.5);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/captured_photo.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      print("Error capturing image: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _renderer.srcObject?.getTracks().forEach((t) => t.stop());
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Camera'),
      content: RepaintBoundary(
        key: _previewContainerKey,
        child: SizedBox(
          width: 500,
          height: 400,
          child: Container(
            width: 500,
            height: 400,
            color: Colors.black,
            child: RTCVideoView(
              _renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final file = await _captureImage();
            Navigator.of(context).pop(file);
          },
          child: const Text('Capture'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
