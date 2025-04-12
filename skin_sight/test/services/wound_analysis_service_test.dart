import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:skin_sight/services/wound_analysis_service.dart';
import 'package:skin_sight/models/roboflow_prediction.dart';

import 'wound_analysis_service_test.mocks.dart';

@GenerateMocks([http.Client, XFile])
void main() {
  // Create sample response data that mimics Roboflow API response
  final sampleRoboflowResponse = {
    'predictions': {
      'inference_id': 'test-inference-123',
      'predictions': {
        'image': {
          'width': 1456,
          'height': 793
        },
        'predictions': [
          {
            'width': 610,
            'height': 354,
            'x': 529,
            'y': 536,
            'confidence': 0.96,
            'class_id': 1,
            'points': [
              {'x': 445, 'y': 359},
              {'x': 444, 'y': 360},
              {'x': 441, 'y': 360},
              {'x': 440, 'y': 361},
              {'x': 434, 'y': 361},
              {'x': 433, 'y': 362},
              {'x': 445, 'y': 400},
              {'x': 500, 'y': 400},
              {'x': 500, 'y': 360}
            ]
          },
          {
            'width': 300,
            'height': 200,
            'x': 200,
            'y': 200,
            'confidence': 0.85,
            'class_id': 1,
            'points': [
              {'x': 100, 'y': 100},
              {'x': 300, 'y': 100},
              {'x': 300, 'y': 300},
              {'x': 100, 'y': 300}
            ]
          }
        ]
      }
    }
  };

  // Test RoboflowPredictionResponse parsing directly
  test('RoboflowPredictionResponse parses Roboflow data correctly', () {
    final response = RoboflowPredictionResponse.fromJson(sampleRoboflowResponse);
    
    expect(response.inferenceId, 'test-inference-123');
    expect(response.imageDimensions.width, 1456);
    expect(response.imageDimensions.height, 793);
    expect(response.predictions.length, 2);
    
    // Verify areas were calculated
    expect(response.totalAffectedArea, isPositive);
    expect(response.totalAffectedPercentage, isPositive);
    
    final structuredResult = response.toStructuredResult();
    expect(structuredResult['area_analysis'], isNotNull);
    expect(structuredResult['area_analysis']['total_affected_area_pixels'], isPositive);
    expect(structuredResult['area_analysis']['detailed_areas'].length, 2);
  });
  
  group('WoundAnalysisService', () {
    late MockClient mockClient;
    late MockXFile mockImageFile;
    
    setUp(() {
      mockClient = MockClient();
      mockImageFile = MockXFile();
      
      // Setup mock behavior
      when(mockImageFile.path).thenReturn('test_image.jpg');
    });
    
    test('Successfully processes Roboflow prediction data', () async {
      // This is a more comprehensive test that would normally use HTTP mocking
      // Here we're directly testing the prediction model processing
      
      // Create a response with our sample data
      final response = RoboflowPredictionResponse.fromJson(sampleRoboflowResponse);
      
      // Verify both lesions are detected and have areas calculated
      expect(response.predictions.length, 2);
      expect(response.predictions[0].area, isNotNull);
      expect(response.predictions[1].area, isNotNull);
      
      // Second lesion should be a square with area of 40,000 (200×200)
      final secondLesion = response.predictions[1];
      expect(secondLesion.area!.pixelArea, 40000);
      
      // Calculate expected percentage (40000 / (1456 * 793) * 100)
      final totalImageArea = 1456 * 793;
      final expectedPercentage = (40000 / totalImageArea) * 100;
      
      expect(secondLesion.area!.percentageOfTotal, moreOrLessEquals(expectedPercentage));
    });
  });
} 