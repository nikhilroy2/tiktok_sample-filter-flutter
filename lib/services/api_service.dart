import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:camera/camera.dart'; // for XFile

class ApiService {
  static const String baseUrl = 'http://192.168.0.100:8000/api';

  Future<bool> uploadVideo(XFile videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload.php'),
      );

      // Compatible with both Web and Mobile
      final bytes = await videoFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: videoFile.name,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }
}
