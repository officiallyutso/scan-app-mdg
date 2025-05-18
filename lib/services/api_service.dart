import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // HARD CODED API URL (change krlena)
  final String _baseUrl = 'https://example.com/api';

  //multipart request (upload keliye)
  Future<http.Response> uploadImage(File image, String documentType) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload'), /////maine consider kiya (example) ki /upload endpoint hai
    );
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        image.path,
      ),
    );

    //request documenttype
    request.fields['documentType'] = documentType;

    request.headers.addAll({
      'Content-Type': 'multipart/form-data', ///incase koi token lagega
    });

    // request sendiong
    final streamedResponse = await request.send();

    // status code checking snackbar meh zaroori hoga
    return await http.Response.fromStream(streamedResponse);
  }
}