import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String _baseUrl = 'http://10.0.2.2:8000';

  Future<Map<String, dynamic>> uploadImage(File image, String documentType) async {
    final bool isDigital = documentType == 'Digilocker';
    
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/registerUser'),
      );
      
      /////reading fileas bytes
      final bytes = await image.readAsBytes();      
      // Use a simpler filename to avoid path issues
      final originalFilename = image.path.split('/').last;
      final extension = originalFilename.split('.').last;
      final simpleFilename = 'aadhar_image.$extension';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: simpleFilename,
          contentType: _getContentType(simpleFilename),
        ),
      );

      //form-field - isdifital
      request.fields['isDigital'] = isDigital.toString().toLowerCase();

      /////console prints
      print('Sending request to: ${request.url}');
      print('Original file name: $originalFilename');
      print('Simplified file name: $simpleFilename');
      print('File size: ${bytes.length} bytes');
      print('isDigital: ${isDigital.toString().toLowerCase()}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ///parsing response.text from the backend
        try {
          final dynamic responseData = jsonDecode(response.body);
          if (responseData is List && responseData.length >= 1) {
            final String aadharNumber = responseData[0].toString();
            final String name = responseData.length > 1 ? responseData[1].toString() : 'Not available';
            
            return {
              'success': true,
              'aadharNumber': aadharNumber,
              'name': name,
              'dob': 'Not available',  /////phoenix these are dump details for now, may add if you want
              'gender': 'Not available',
            };
          // } else if (responseData is Map) {
          //   return {
          //     'success': true,
          //     'aadharNumber': responseData['aadhar'] ?? responseData['aadhar_number'] ?? 'Not available',
          //     'name': responseData['name'] ?? responseData['full_name'] ?? 'Not available',
          //     'dob': responseData['dob'] ?? 'Not available',
          //     'gender': responseData['gender'] ?? responseData['sex'] ?? 'Not available',
          //   };
          } 
          else {
            return {
              'success': true,
              'aadharNumber': responseData.toString(),
              'name': 'Not available',
              'dob': 'Not available',
              'gender': 'Not available',
            };
          }
        } catch (e) {
          final String responseText = response.body;
          final RegExp aadharRegex = RegExp(r'\d{12}'); //kyuki response text has both num and string looh for 12-digit number
          final match = aadharRegex.firstMatch(responseText);
          
          if (match != null) {
            return {
              'success': true,
              'aadharNumber': match.group(0) ?? responseText,
            };
          }
          
          return {
            'success': true,
            'aadharNumber': responseText,
          };
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        
        //phoenix please add endpoint for the error details
        if (response.body.contains("Person already exists")) {
          return {
            'success': false,
            'message': 'Person already exists in the system',
          };
        }
        
        return {
          'success': false,
          'message': 'Failed with status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Exception during upload: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  ////file extension helper fucntion
  MediaType _getContentType(String filename) {
    if (filename.toLowerCase().endsWith('.jpg') || 
        filename.toLowerCase().endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    } else if (filename.toLowerCase().endsWith('.png')) {
      return MediaType('image', 'png');
    } else {
      return MediaType('application', 'octet-stream');
    }
  }
  
  // Future<http.Response> getPeople() async {
  //   return await http.get(Uri.parse('$_baseUrl/getPeopleIn'));
  // }
  
  // Future<http.Response> getPeople() async {
  //   return await http.get(Uri.parse('$_baseUrl/getPeopleOut'));
  // }

  Future<http.Response> logPersonMovement(int aadhar, bool isEntering) async {
    return await http.post(
      Uri.parse('$_baseUrl/log_movement'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'aadhar': aadhar,
        'is_in': isEntering,
      }),
    );
  }

  // Get person details after successful registration
  Future<Map<String, dynamic>> getPersonDetails(String aadharNumber) async {
    try {
      return {
        'aadharNumber': aadharNumber, ///other details keliye pelase add in endpoint
      };
    } catch (e) {
      print('Error getting person details: $e');
      throw Exception('Failed to get person details');
    }
  }
}