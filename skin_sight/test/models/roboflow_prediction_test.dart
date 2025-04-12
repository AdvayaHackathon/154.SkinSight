import 'package:flutter_test/flutter_test.dart';
import 'package:skin_sight/models/roboflow_prediction.dart';

void main() {
  group('Polygon Area Calculation Tests', () {
    test('Calculate area of a square', () {
      // Create a simple square with sides of length 10
      final List<Point> square = [
        Point(x: 0, y: 0),
        Point(x: 10, y: 0),
        Point(x: 10, y: 10),
        Point(x: 0, y: 10),
      ];
      
      final area = PsoriasisPrediction.calculatePolygonArea(square);
      expect(area, 100.0); // 10 x 10 = 100 square units
    });
    
    test('Calculate area of a triangle', () {
      // Create a right triangle
      final List<Point> triangle = [
        Point(x: 0, y: 0),
        Point(x: 10, y: 0),
        Point(x: 0, y: 10),
      ];
      
      final area = PsoriasisPrediction.calculatePolygonArea(triangle);
      expect(area, 50.0); // (10 * 10) / 2 = 50 square units
    });
    
    test('Calculate area of an irregular polygon', () {
      // Create an irregular polygon
      final List<Point> polygon = [
        Point(x: 0, y: 0),
        Point(x: 10, y: 2),
        Point(x: 8, y: 8),
        Point(x: 3, y: 10),
        Point(x: 0, y: 5),
      ];
      
      final area = PsoriasisPrediction.calculatePolygonArea(polygon);
      // The expected area is calculated using the shoelace formula
      expect(area.toStringAsFixed(2), '67.50');
    });
    
    test('Calculate area with less than 3 points returns 0', () {
      final List<Point> twoPoints = [
        Point(x: 0, y: 0),
        Point(x: 10, y: 10),
      ];
      
      final area = PsoriasisPrediction.calculatePolygonArea(twoPoints);
      expect(area, 0.0);
    });
    
    test('Empty points list returns 0', () {
      final List<Point> emptyList = [];
      
      final area = PsoriasisPrediction.calculatePolygonArea(emptyList);
      expect(area, 0.0);
    });
  });
  
  group('RoboflowPredictionResponse Parsing', () {
    test('Parse valid Roboflow prediction and calculate areas', () {
      // Sample Roboflow prediction response format
      final Map<String, dynamic> sampleResponse = {
        'predictions': {
          'inference_id': 'test-id-123',
          'predictions': {
            'image': {
              'width': 100,
              'height': 100
            },
            'predictions': [
              {
                'width': 30,
                'height': 30,
                'x': 50,
                'y': 50,
                'confidence': 0.95,
                'class_id': 1,
                'points': [
                  {'x': 35, 'y': 35},
                  {'x': 65, 'y': 35},
                  {'x': 65, 'y': 65},
                  {'x': 35, 'y': 65}
                ]
              }
            ]
          }
        }
      };
      
      final result = RoboflowPredictionResponse.fromJson(sampleResponse);
      
      // Check basic properties
      expect(result.inferenceId, 'test-id-123');
      expect(result.imageDimensions.width, 100);
      expect(result.imageDimensions.height, 100);
      expect(result.imageDimensions.totalArea, 10000); // 100 * 100
      expect(result.predictions.length, 1);
      
      // Check the prediction
      final prediction = result.predictions.first;
      expect(prediction.width, 30);
      expect(prediction.height, 30);
      expect(prediction.confidence, 0.95);
      expect(prediction.points.length, 4);
      
      // Check area calculation
      expect(prediction.area, isNotNull);
      expect(prediction.area!.pixelArea, 900); // 30 * 30
      expect(prediction.area!.percentageOfTotal, 9.0); // 900 / 10000 * 100
      
      // Check total area calculations
      expect(result.totalAffectedArea, 900);
      expect(result.totalAffectedPercentage, 9.0);
      
      // Test structured result format
      final structuredResult = result.toStructuredResult();
      expect(structuredResult['area_analysis']['total_affected_area_pixels'], 900);
      expect(structuredResult['area_analysis']['total_affected_percentage'], 9.0);
    });
  });
} 