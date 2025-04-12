import 'dart:math' as math;

/// Class to represent a point with x and y coordinates
class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  String toString() => 'Point(x: $x, y: $y)';
}

/// Class to represent the area calculation result
class AreaCalculation {
  final double pixelArea;
  final double percentageOfTotal;

  AreaCalculation({
    required this.pixelArea,
    required this.percentageOfTotal,
  });

  Map<String, dynamic> toJson() => {
    'pixels': pixelArea,
    'percentage': percentageOfTotal,
  };

  @override
  String toString() => 'Area: $pixelArea px² ($percentageOfTotal%)';
}

/// Class to represent image dimensions
class ImageDimensions {
  final double width;
  final double height;
  final double totalArea;

  ImageDimensions({
    required this.width,
    required this.height,
  }) : totalArea = width * height;

  factory ImageDimensions.fromJson(Map<String, dynamic> json) {
    return ImageDimensions(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'total_area': totalArea,
  };

  @override
  String toString() => '$width×$height px (${totalArea.toStringAsFixed(0)} px²)';
}

/// Class to represent a single psoriasis prediction from Roboflow
class PsoriasisPrediction {
  final double width;
  final double height;
  final double x;
  final double y;
  final double confidence;
  final int classId;
  final String? className;
  final String? detectionId;
  final List<Point> points;
  AreaCalculation? area;

  PsoriasisPrediction({
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.confidence,
    required this.classId,
    this.className,
    this.detectionId,
    required this.points,
    this.area,
  });

  factory PsoriasisPrediction.fromJson(Map<String, dynamic> json) {
    final List<Point> pointsList = [];
    
    if (json.containsKey('points') && json['points'] is List) {
      pointsList.addAll(
        (json['points'] as List).map((point) => Point.fromJson(point))
      );
    }

    return PsoriasisPrediction(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      classId: json['class_id'] is num ? (json['class_id'] as num).toInt() : 1,
      className: json['class'] as String?,
      detectionId: json['detection_id'] as String?,
      points: pointsList,
    );
  }

  /// Calculates the area of this psoriasis prediction using the polygon points
  void calculateArea(ImageDimensions imageDimensions) {
    if (points.length < 3) {
      area = AreaCalculation(pixelArea: 0, percentageOfTotal: 0);
      return;
    }

    double calculatedArea = calculatePolygonArea(points);
    double percentage = (calculatedArea / imageDimensions.totalArea) * 100;
    
    area = AreaCalculation(
      pixelArea: calculatedArea,
      percentageOfTotal: percentage,
    );
  }

  /// Calculates the area of a polygon using the Shoelace formula
  static double calculatePolygonArea(List<Point> vertices) {
    if (vertices.length < 3) return 0;
    
    double area = 0;
    int j = vertices.length - 1;
    
    for (int i = 0; i < vertices.length; i++) {
      area += (vertices[j].x + vertices[i].x) * 
              (vertices[j].y - vertices[i].y);
      j = i;
    }
    
    // Return absolute value of half the sum
    return (area / 2).abs();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'width': width,
      'height': height,
      'x': x,
      'y': y,
      'confidence': confidence,
      'class_id': classId,
      'points': points.map((p) => p.toJson()).toList(),
    };

    // Include optional fields only if they have values
    if (className != null) {
      json['class'] = className;
    }
    
    if (detectionId != null) {
      json['detection_id'] = detectionId;
    }

    if (area != null) {
      json['area'] = area!.toJson();
    }

    return json;
  }
}

/// Class to represent the full Roboflow prediction response
class RoboflowPredictionResponse {
  final String inferenceId;
  final ImageDimensions imageDimensions;
  final List<PsoriasisPrediction> predictions;
  final double totalAffectedArea;
  final double totalAffectedPercentage;

  RoboflowPredictionResponse({
    required this.inferenceId,
    required this.imageDimensions,
    required this.predictions,
    required this.totalAffectedArea,
    required this.totalAffectedPercentage,
  });

  factory RoboflowPredictionResponse.fromJson(Map<String, dynamic> json) {
    // Extract the nested predictions data
    final predictionsData = json['predictions'];
    final inferenceId = predictionsData['inference_id'] as String;
    
    final imageData = predictionsData['predictions']['image'];
    final imageDimensions = ImageDimensions.fromJson(imageData);
    
    final predictionsListData = predictionsData['predictions']['predictions'] as List;
    final predictions = predictionsListData
        .map((pred) => PsoriasisPrediction.fromJson(pred))
        .toList();
    
    // Calculate areas for each prediction
    double totalArea = 0;
    for (final prediction in predictions) {
      prediction.calculateArea(imageDimensions);
      totalArea += prediction.area?.pixelArea ?? 0;
    }
    
    final totalPercentage = (totalArea / imageDimensions.totalArea) * 100;
    
    return RoboflowPredictionResponse(
      inferenceId: inferenceId,
      imageDimensions: imageDimensions,
      predictions: predictions,
      totalAffectedArea: totalArea,
      totalAffectedPercentage: totalPercentage,
    );
  }

  /// Creates a structured result with area analysis
  Map<String, dynamic> toStructuredResult() {
    final detailedAreas = predictions.asMap().entries.map((entry) {
      final index = entry.key;
      final prediction = entry.value;
      
      return {
        'index': index,
        'confidence': prediction.confidence,
        'area_pixels': prediction.area?.pixelArea ?? 0,
        'area_percentage': prediction.area?.percentageOfTotal ?? 0,
      };
    }).toList();

    return {
      'predictions': {
        'inference_id': inferenceId,
        'predictions': {
          'image': imageDimensions.toJson(),
          'predictions': predictions.map((p) => p.toJson()).toList(),
        },
      },
      'area_analysis': {
        'total_affected_area_pixels': totalAffectedArea,
        'total_affected_percentage': totalAffectedPercentage,
        'image_dimensions': imageDimensions.toJson(),
        'detailed_areas': detailedAreas,
      },
    };
  }
}