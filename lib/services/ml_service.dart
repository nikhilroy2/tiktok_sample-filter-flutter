import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class MLService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );

  List<PoseLandmark>? poseLandmarks;
  List<Face>? faceLandmarks;
  double movementIntensity = 0.0;
  bool isMoving = false;

  // For velocity calculation
  Map<PoseLandmarkType, Point<double>> _prevLandmarks = {};
  DateTime? _lastTimestamp;

  Future<void> processImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final faces = await _faceDetector.processImage(inputImage);
    final poses = await _poseDetector.processImage(inputImage);

    faceLandmarks = faces;
    if (poses.isNotEmpty) {
      poseLandmarks = poses.first.landmarks.values.toList();
      _calculateMovement(poses.first.landmarks);
    }
  }

  void _calculateMovement(Map<PoseLandmarkType, PoseLandmark> current) {
    final now = DateTime.now();
    if (_lastTimestamp == null) {
      _lastTimestamp = now;
      current.forEach((k, v) => _prevLandmarks[k] = Point(v.x, v.y));
      return;
    }

    double totalDist = 0;
    int count = 0;

    // Track shoulders and wrists for "raise arm" movement
    final typesToTrack = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];

    for (var type in typesToTrack) {
      final cur = current[type];
      final prev = _prevLandmarks[type];
      if (cur != null && prev != null) {
        totalDist += sqrt(pow(cur.x - prev.x, 2) + pow(cur.y - prev.y, 2));
        _prevLandmarks[type] = Point(cur.x, cur.y);
        count++;
      }
    }

    final dt = now.difference(_lastTimestamp!).inMilliseconds / 1000.0;
    if (dt > 0 && count > 0) {
      double velocity = (totalDist / count) / dt;
      // Smoothing
      movementIntensity =
          movementIntensity * 0.7 + (velocity / 500.0).clamp(0.0, 1.0) * 0.3;
      isMoving = movementIntensity > 0.15;
    }

    _lastTimestamp = now;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // 1. Get the bytes
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 2. Get the image size
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    // 3. Define rotation and format (Assuming portrait + NV21/YUV for Android)
    final InputImageRotation imageRotation = InputImageRotation.rotation90deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    // 4. Create proper metadata for new ML Kit version
    // ML Kit now requires bytesPerRow for each plane in the metadata
    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: planeData.isNotEmpty ? planeData.first.bytesPerRow : 0,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageMetadata,
    );
  }

  void dispose() {
    _faceDetector.close();
    _poseDetector.close();
  }
}
