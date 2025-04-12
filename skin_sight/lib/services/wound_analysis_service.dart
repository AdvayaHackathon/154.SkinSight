import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/roboflow_prediction.dart';

class WoundAnalysisService {
  // Roboflow API settings with actual API key and workspace details
  static const String _roboflowApiKey = 'CbrrMwWgSeByWhFBaz1T';
  static const String _roboflowWorkspaceName = 'skinsight-lpkik';
  static const String _roboflowWorkflowId = 'active-learning';
  
  // Modified API endpoint format for workflows
  static const String _roboflowBaseUrl = 'https://infer.roboflow.com';
  
  // API version - use empty string for workflow endpoints
  static const String _roboflowApiVersion = '';
  
  // Define multiple endpoint formats to try if the primary one fails
  static final List<String> _endpointFormats = [
    '$_roboflowBaseUrl/$_roboflowWorkspaceName/$_roboflowWorkflowId', // Primary format for workflows
    'https://infer.roboflow.com/workflow/$_roboflowWorkspaceName/$_roboflowWorkflowId', // Alternative with "workflow" path
    'https://detect.roboflow.com/workflow/$_roboflowWorkspaceName/$_roboflowWorkflowId', // Using detect subdomain
    'https://api.roboflow.com/workflows/$_roboflowWorkspaceName/$_roboflowWorkflowId', // API subdomain format
  ];

  /// Analyzes a psoriasis image by sending it directly to Roboflow workflow
  /// 
  /// [imageFile] - The image file to analyze (XFile from image_picker)
  /// [bodyRegion] - Location of the psoriasis (head, upper_limbs, trunk, lower_limbs)
  /// 
  /// Returns a Map containing the analysis results including area calculations
  static Future<Map<String, dynamic>?> analyzePsoriasis({
    required XFile imageFile,
    required String bodyRegion,
    XFile? depthMapFile, // Kept for backward compatibility but not used for Roboflow
  }) async {
    try {
      final imageBytes = await File(imageFile.path).readAsBytes();
      
      // Try all endpoint formats until one works
      return await _tryMultipleEndpoints(imageBytes, bodyRegion);
    } on SocketException {
      debugPrint('Network error - Please check your internet connection');
      throw Exception('Network error - Please check your internet connection');
    } on FormatException {
      debugPrint('Invalid response format from Roboflow');
      throw Exception('Invalid response format from Roboflow');
    } on http.ClientException catch (e) {
      debugPrint('HTTP client exception: $e');
      throw Exception('Error connecting to Roboflow: $e');
    } catch (e) {
      debugPrint('Error analyzing psoriasis: $e');
      throw Exception('Error analyzing psoriasis: $e');
    }
  }
  
  /// Try multiple endpoint formats until one succeeds
  static Future<Map<String, dynamic>?> _tryMultipleEndpoints(List<int> imageBytes, String bodyRegion) async {
    Exception? lastException;
    
    // Try each endpoint format
    for (int i = 0; i < _endpointFormats.length; i++) {
      final endpoint = _endpointFormats[i];
      final uri = Uri.parse('$endpoint?api_key=$_roboflowApiKey');
      
      debugPrint('====== TRYING ENDPOINT FORMAT #${i+1} ======');
      debugPrint('API URL: ${endpoint.replaceAll(_roboflowWorkspaceName, "[WORKSPACE]").replaceAll(_roboflowWorkflowId, "[WORKFLOW]")}?api_key=[API-KEY-HIDDEN]');
      
      try {
        // Try direct JSON/base64 format first - most common for workflows
        debugPrint('Attempting base64 JSON request...');
        var response = await _sendBase64JsonRequestWithDifferentFormats(uri, imageBytes, bodyRegion);
        
        if (response.statusCode == 200) {
          debugPrint('✅ SUCCESS: Endpoint format #${i+1} worked!');
          return _processResponse(response, bodyRegion);
        }
        
        // If we're still getting 405, try with form multipart as a last resort
        if (response.statusCode == 405 && i == _endpointFormats.length - 1) {
          debugPrint('Trying multipart form request as a last resort...');
          response = await _sendMultipartRequest(uri, imageBytes, 'image.jpg', bodyRegion);
          
          if (response.statusCode == 200) {
            debugPrint('✅ SUCCESS: Multipart format worked!');
            return _processResponse(response, bodyRegion);
          }
        }
        
        // Log failure
        debugPrint('❌ FAILED: Endpoint format #${i+1} returned status ${response.statusCode}');
        debugPrint('Response: ${response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body}');
        
      } catch (e) {
        debugPrint('❌ ERROR with endpoint format #${i+1}: $e');
        lastException = e is Exception ? e : Exception(e.toString());
      }
    }
    
    // If we've tried all endpoints and none worked
    debugPrint('❌ ALL ENDPOINT FORMATS FAILED');
    throw lastException ?? Exception('Failed to connect to Roboflow API after trying multiple endpoint formats');
  }
  
  /// Try different JSON payload formats for the base64 image
  static Future<http.Response> _sendBase64JsonRequestWithDifferentFormats(
    Uri uri, 
    List<int> imageBytes, 
    String bodyRegion
  ) async {
    // Convert image to base64
    final base64Image = base64Encode(imageBytes);
    
    // Try different payload formats
    final payloadFormats = [
      // Format 1: Standard base64 image with metadata
      {
        'image': base64Image,
        'metadata': {
          'body_region': bodyRegion,
          'client': 'mobile_app'
        },
        'params': {
          'confidence': 40,
          'overlap': 30,
          'format': 'json'
        }
      },
      
      // Format 2: Direct base64 without metadata
      {
        'image': base64Image
      },
      
      // Format 3: Using "data" key as wrapper
      {
        'data': {
          'image': base64Image,
          'body_region': bodyRegion
        }
      },
      
      // Format 4: Specific workflow input format
      {
        'input': {
          'image': base64Image,
          'body_region': bodyRegion
        }
      }
    ];
    
    // Try each payload format
    for (int i = 0; i < payloadFormats.length; i++) {
      try {
        debugPrint('Trying payload format #${i+1}...');
        
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payloadFormats[i]),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out. Please check your internet connection.');
          },
        );
        
        // If successful or if this is the last format to try, return the response
        if (response.statusCode == 200 || i == payloadFormats.length - 1) {
          return response;
        }
        
        debugPrint('Payload format #${i+1} returned status ${response.statusCode}');
        
      } catch (e) {
        debugPrint('Error with payload format #${i+1}: $e');
        // Continue to next format unless this is the last one
        if (i == payloadFormats.length - 1) {
          rethrow;
        }
      }
    }
    
    // This should never happen due to the rethrow above
    throw Exception('All payload formats failed');
  }
  
  /// Helper method to send a multipart request with the image
  static Future<http.Response> _sendMultipartRequest(
    Uri uri, 
    List<int> imageBytes, 
    String imagePath, 
    String bodyRegion
  ) async {
    // Create a multipart request
    final request = http.MultipartRequest('POST', uri);
    
    // Add the image file to the request
    final imageFileField = http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType(_getImageType(imagePath), ''),
    );
    
    request.files.add(imageFileField);
    
    // Add metadata as fields if needed
    request.fields['body_region'] = bodyRegion;
    
    // Send the request
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Request timed out. Please check your internet connection.');
      },
    );
    
    // Convert to a regular response
    return await http.Response.fromStream(streamedResponse);
  }
  
  /// Helper method to send a base64 encoded JSON request with the image
  static Future<http.Response> _sendBase64JsonRequest(
    Uri uri, 
    List<int> imageBytes, 
    String bodyRegion
  ) async {
    // Convert image to base64
    final base64Image = base64Encode(imageBytes);
    
    // Create the JSON payload - format matching workflow expectations
    // The workflow expects an image field with base64 data
    final Map<String, dynamic> payload = {
      'image': base64Image,
      'metadata': {
        'body_region': bodyRegion,
        'client': 'mobile_app'
      },
      // Optional parameters for the workflow
      'params': {
        'confidence': 40,  // Only return predictions with confidence > 40%
        'overlap': 30,     // Non-maximum suppression overlap threshold
        'format': 'json'   // Ensure JSON response format
      }
    };
    
    debugPrint('Sending base64 JSON request with metadata for body region: $bodyRegion');
    
    // Send the POST request with JSON body
    return await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Request timed out. Please check your internet connection.');
      },
    );
  }
  
  /// Process the API response
  static Future<Map<String, dynamic>?> _processResponse(http.Response response, String bodyRegion) async {
    // Response debugging
    debugPrint('Response status code: ${response.statusCode}');
    
    // Check status code
    if (response.statusCode == 200) {
      debugPrint('Analysis response received successfully from Roboflow');
      dynamic responseData;
      
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        debugPrint('Failed to decode JSON response: $e');
        throw Exception('Invalid JSON response from Roboflow API');
      }
      
      // Handle different response formats (array or object)
      Map<String, dynamic> workflowResult;
      
      if (responseData is List && responseData.isNotEmpty) {
        workflowResult = responseData[0] as Map<String, dynamic>;
        debugPrint('Detected array response format, processing first result');
      } else if (responseData is Map<String, dynamic>) {
        workflowResult = responseData;
      } else {
        debugPrint('Unexpected response format: ${responseData.runtimeType}');
        throw Exception('Unexpected response format from Roboflow API');
      }
      
      // Process Roboflow predictions
      if (workflowResult.containsKey('predictions') || workflowResult.containsKey('result') || workflowResult.containsKey('upload_message')) {
        try {
          // Adapt the Roboflow response format for our application
          final adaptedResponse = _adaptRoboflowResponse(workflowResult, bodyRegion);
          
          // Use the model to parse and process the predictions
          final predictionResponse = RoboflowPredictionResponse.fromJson(adaptedResponse);
          
          // Log the area calculations for debugging
          debugPrint('===== AREA ANALYSIS RESULTS =====');
          debugPrint('Total affected area: ${predictionResponse.totalAffectedArea.toStringAsFixed(2)} pixels');
          debugPrint('Total affected percentage: ${predictionResponse.totalAffectedPercentage.toStringAsFixed(2)}%');
          debugPrint('Image dimensions: ${predictionResponse.imageDimensions.width}x${predictionResponse.imageDimensions.height}');
          debugPrint('Number of detected lesions: ${predictionResponse.predictions.length}');
          
          // Log details for each lesion
          for (int i = 0; i < predictionResponse.predictions.length; i++) {
            final prediction = predictionResponse.predictions[i];
            debugPrint('Lesion #${i+1}:');
            debugPrint('  - Area: ${prediction.area?.pixelArea.toStringAsFixed(2)} pixels');
            debugPrint('  - Percentage: ${prediction.area?.percentageOfTotal.toStringAsFixed(2)}%');
          }
          
          // Return the structured result
          return predictionResponse.toStructuredResult();
        } catch (e) {
          debugPrint('Error processing Roboflow prediction response: $e');
          // Return raw response for debugging or fallback processing
          return _adaptRoboflowResponse(workflowResult, bodyRegion);
        }
      }
      
      return workflowResult;
    } else {
      // Print full error response for debugging
      debugPrint('Error from Roboflow: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 401) {
        debugPrint('Authentication error: Please check your API key and workspace access');
      } else if (response.statusCode == 403) {
        debugPrint('Forbidden error: Access denied. This could be due to:');
        debugPrint('1. Invalid API key format or authentication method');
        debugPrint('2. API key does not have permission for this workspace/model');
        debugPrint('3. Request format is incorrect or your account has reached its limit');
        debugPrint('4. IP address restriction is in place on Roboflow account');
      } else if (response.statusCode == 405) {
        debugPrint('Method Not Allowed: API requires a different request format');
      }
      
      throw Exception('Roboflow API returned status code ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
  
  /// Adapts the Roboflow response to match our expected format
  static Map<String, dynamic> _adaptRoboflowResponse(Map<String, dynamic> roboflowResponse, String bodyRegion) {
    // Extract image dimensions
    int width = 0;
    int height = 0;
    List<dynamic> predictions = [];
    
    // Handle the array response format if present
    if (roboflowResponse is List && roboflowResponse.isNotEmpty) {
      // If the response is a list, take the first item
      roboflowResponse = roboflowResponse[0];
    }
    
    debugPrint('Response structure: ${roboflowResponse.keys.join(', ')}');
    
    // Based on the workflow structure provided, check for specific fields
    // The workflow returns upload_message, output_image, and predictions fields directly
    if (roboflowResponse.containsKey('predictions')) {
      final predData = roboflowResponse['predictions'];
      
      // Extract predictions based on workflow format - should be direct list of predictions
      if (predData is List) {
        predictions = predData;
        debugPrint('Found direct predictions list with ${predictions.length} items');
      } else if (predData is Map) {
        // In case predictions is a map with nested predictions
        if (predData.containsKey('image')) {
          width = predData['image']['width'] ?? 0;
          height = predData['image']['height'] ?? 0;
          debugPrint('Found image dimensions in predictions map: ${width}x${height}');
        }
        
        if (predData.containsKey('predictions')) {
          predictions = predData['predictions'] is List ? predData['predictions'] : [];
          debugPrint('Found nested predictions list with ${predictions.length} items');
        }
      }
    }
    
    // If output_image contains dimensions, use those
    if (roboflowResponse.containsKey('output_image')) {
      final outputImage = roboflowResponse['output_image'];
      if (outputImage is Map && outputImage.containsKey('width') && outputImage.containsKey('height')) {
        width = outputImage['width'] ?? width;
        height = outputImage['height'] ?? height;
        debugPrint('Found image dimensions in output_image: ${width}x${height}');
      } else if (outputImage is String && outputImage.isNotEmpty) {
        // If output_image is a base64 string, we could estimate dimensions,
        // but for now we'll use default dimensions if needed
        debugPrint('output_image is a base64 string');
      }
    }
    
    // Ensure we have valid dimensions
    if (width == 0 || height == 0) {
      // If no dimensions found, try to extract from first prediction
      if (predictions.isNotEmpty && predictions[0] is Map) {
        final first = predictions[0];
        if (first.containsKey('width') && first.containsKey('height') && 
            first.containsKey('x') && first.containsKey('y')) {
          // Estimate image size based on bounding box coordinates
          // This is a rough estimate assuming coordinates are within image bounds
          width = (first['x'] + first['width']).ceil() * 2;
          height = (first['y'] + first['height']).ceil() * 2;
          debugPrint('Estimated image dimensions from prediction coordinates: ${width}x${height}');
        }
      }
      
      // If still no dimensions, use defaults
      if (width == 0 || height == 0) {
        width = 1000; // Default fallback width
        height = 1000; // Default fallback height
        debugPrint('WARNING: Could not detect image dimensions, using defaults: ${width}x${height}');
      }
    }
    
    final totalImageArea = width * height;
    double totalAffectedArea = 0;
    
    final processedPredictions = predictions.map((pred) {
      // Extract bounding box values
      final x = pred['x'] is num ? (pred['x'] as num) : 0;
      final y = pred['y'] is num ? (pred['y'] as num) : 0;
      final predWidth = pred['width'] is num ? (pred['width'] as num) : 0;
      final predHeight = pred['height'] is num ? (pred['height'] as num) : 0;
      final confidence = pred['confidence'] is num ? (pred['confidence'] as num) : 0.0;
      final classId = pred['class_id'] ?? 1;
      final className = pred['class'] ?? 'Psoriasis'; // Get class name if available
      
      // Create points from bounding box if no points are provided
      List<Map<String, dynamic>> points = [];
      if (pred.containsKey('points') && pred['points'] is List) {
        points = (pred['points'] as List).map((p) => p as Map<String, dynamic>).toList();
      } else {
        // Create rectangle points from bounding box
        final left = x - predWidth / 2;
        final right = x + predWidth / 2;
        final top = y - predHeight / 2;
        final bottom = y + predHeight / 2;
        
        points = [
          {'x': left, 'y': top},
          {'x': right, 'y': top},
          {'x': right, 'y': bottom},
          {'x': left, 'y': bottom},
        ];
      }
      
      // Calculate area for this prediction (approximate using bounding box)
      final area = predWidth * predHeight;
      totalAffectedArea += area;
      
      // Create our prediction format
      return {
        'width': predWidth,
        'height': predHeight,
        'x': x,
        'y': y,
        'confidence': confidence,
        'class_id': classId,
        'class': className,
        'detection_id': pred['detection_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'points': points,
        'area': {
          'pixels': area,
          'percentage': (area / totalImageArea) * 100,
        },
      };
    }).toList();
    
    // Calculate total affected percentage
    final totalAffectedPercentage = (totalAffectedArea / totalImageArea) * 100;
    
    // Create response in the format expected by our RoboflowPredictionResponse
    // using the structure matching the workflow response
    return {
      'predictions': {
        'inference_id': roboflowResponse['time'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'predictions': {
          'image': {
            'width': width,
            'height': height,
          },
          'predictions': processedPredictions,
        },
      },
      'area_analysis': {
        'total_affected_area_pixels': totalAffectedArea,
        'total_affected_percentage': totalAffectedPercentage,
        'image_dimensions': {
          'width': width,
          'height': height,
          'total_area': totalImageArea,
        },
        'body_region': bodyRegion,
      },
      'upload_message': roboflowResponse['upload_message'] ?? 'Processed successfully',
    };
  }
  
  /// Formats body location for better readability
  static String formatBodyLocation(String bodyLocation) {
    return bodyLocation
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  /// Gets the MIME type from the file extension
  static String _getImageType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'png';
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg'; // Default to jpeg if unknown
    }
  }
}

/// Custom exception for timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}