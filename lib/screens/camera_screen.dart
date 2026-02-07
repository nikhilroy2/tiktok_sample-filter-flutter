import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/ml_service.dart';
import '../services/api_service.dart';
import '../ui/vfx_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final MLService _mlService = MLService();
  bool _isProcessing = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    
    // Start ML processing
    _controller!.startImageStream((image) {
      if (_isProcessing) return;
      _isProcessing = true;
      _processImage(image);
    });

    if (mounted) setState(() {});
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      _showUploadDialog(File(file.path));
    } else {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  void _showUploadDialog(File videoFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recording Saved"),
        content: const Text("Do you want to upload this clip to the server?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Dismiss"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ApiService().uploadVideo(videoFile);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? "Upload successful!" : "Upload failed")),
                );
              }
            },
            child: const Text("Upload"),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(CameraImage image) async {

    try {
      await _mlService.processImage(image);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),
          
          // AR Overlay
          RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: VFXPainter(
                poseLandmarks: _mlService.poseLandmarks,
                faceLandmarks: _mlService.faceLandmarks,
                intensity: _mlService.movementIntensity,
                isMoving: _mlService.isMoving,
              ),
            ),
          ),

          // UI Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.flash_off, color: Colors.white, size: 30),
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
              ],
            ),
          ),
          
          if (_isRecording)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "REC 00:01",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
