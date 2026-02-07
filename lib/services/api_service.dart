import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://192.168.0.100:8000/api';

  Future<bool> uploadVideo(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload.php'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('video', videoFile.path),
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
