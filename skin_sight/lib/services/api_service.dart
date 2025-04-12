import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String baseUrl = 'https://0cff-103-213-211-149.ngrok-free.app';

  // Analyze skin image with AI using a local file
  static Future<Map<String, dynamic>> analyzeSkinImage(File imageFile, String bodyRegion) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add the image file
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      // Add body region parameter
      request.fields['body_region'] = bodyRegion.toLowerCase();
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image: $e');
    }
  }
  
  // Analyze skin image with AI using a URL
  static Future<Map<String, dynamic>> analyzeSkinImageFromUrl(String imageUrl, String bodyRegion) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Download the image first
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image from URL: ${response.statusCode}');
      }
      
      // Create a temporary file
      final tempDir = await Directory.systemTemp.createTemp('image_analysis');
      final tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);
      
      // Add the image file
      final fileStream = http.ByteStream(tempFile.openRead());
      final fileLength = await tempFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      // Add body region
      request.fields['body_region'] = bodyRegion.toLowerCase();
      
      // Send the request
      final streamedResponse = await request.send();
      final apiResponse = await http.Response.fromStream(streamedResponse);
      
      // Clean up the temporary file
      await tempFile.delete();
      await tempDir.delete(recursive: true);
      
      if (apiResponse.statusCode == 200) {
        return json.decode(apiResponse.body);
      } else {
        throw Exception('Failed to analyze image: ${apiResponse.statusCode} - ${apiResponse.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image from URL: $e');
    }
  }
}
