import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras
  final cameras = await availableCameras();
  
  runApp(TikTokFilterApp(cameras: cameras));
}

class TikTokFilterApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const TikTokFilterApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Aura Filter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PermissionWrapper(),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (status[Permission.camera]!.isGranted &&
        status[Permission.microphone]!.isGranted) {
      if (mounted) setState(() => _granted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_granted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const CameraScreen();
  }
}
