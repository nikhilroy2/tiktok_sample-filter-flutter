import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class VFXPainter extends CustomPainter {
  final List<PoseLandmark>? poseLandmarks;
  final List<Face>? faceLandmarks;
  final double intensity;
  final bool isMoving;

  VFXPainter({
    this.poseLandmarks,
    this.faceLandmarks,
    required this.intensity,
    required this.isMoving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isMoving) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw Infinity Symbol around user when moving
    if (poseLandmarks != null) {
      _drawInfinitySymbol(canvas, size, paint);
    }

    // Gradient Glow around Face
    if (faceLandmarks != null && faceLandmarks!.isNotEmpty) {
      _drawFaceAura(canvas, faceLandmarks!.first, paint);
    }
  }

  void _drawInfinitySymbol(Canvas canvas, Size size, Paint paint) {
    // Basic infinity curve (lemniscate of Bernoulli)
    // Centered roughly on the torso if available
    final path = Path();
    double centerX = size.width / 2;
    double centerY = size.height * 0.4;
    double width = size.width * 0.4 * (0.8 + intensity * 0.5);

    for (double i = 0; i <= 2 * math.pi; i += 0.1) {
      double t = i;
      double x = (width * math.cos(t)) / (1 + math.pow(math.sin(t), 2));
      double y = (width * math.sin(t) * math.cos(t)) / (1 + math.pow(math.sin(t), 2));
      
      if (i == 0) {
        path.moveTo(centerX + x, centerY + y);
      } else {
        path.lineTo(centerX + x, centerY + y);
      }
    }
    path.close();

    // Visual style: Glowing line
    paint.shader = LinearGradient(
      colors: [
        Colors.pinkAccent.withOpacity(0.8),
        Colors.blueAccent.withOpacity(0.8),
        Colors.orangeAccent.withOpacity(0.8),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, paint);
    
    // Internal bright core
    paint.strokeWidth = 2.0;
    paint.maskFilter = null;
    paint.color = Colors.white.withOpacity(0.9);
    canvas.drawPath(path, paint);
  }

  void _drawFaceAura(Canvas canvas, Face face, Paint paint) {
    final rect = face.boundingBox;
    final center = Offset(rect.left + rect.width / 2, rect.top + rect.height / 2);
    final radius = math.max(rect.width, rect.height) * 0.8;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.pinkAccent.withOpacity(0.4 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * intensity);

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(VFXPainter oldDelegate) => true;
}
