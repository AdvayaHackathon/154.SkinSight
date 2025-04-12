class AiAnalysisModel {
  final bool success;
  final AreaAnalysis areaAnalysis;
  final AreaCalculation areaCalculation;
  final ColorAnalysis colorAnalysis;
  final PasiAssessment pasiAssessment;
  final Diagnosis diagnosis;
  final String? note;

  AiAnalysisModel({
    required this.success,
    required this.areaAnalysis,
    required this.areaCalculation,
    required this.colorAnalysis,
    required this.pasiAssessment,
    required this.diagnosis,
    this.note,
  });

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AiAnalysisModel(
      success: json['success'] ?? false,
      areaAnalysis: AreaAnalysis.fromJson(json['area_analysis'] ?? {}),
      areaCalculation: AreaCalculation.fromJson(json['area_calculation'] ?? {}),
      colorAnalysis: ColorAnalysis.fromJson(json['color_analysis'] ?? {}),
      pasiAssessment: PasiAssessment.fromJson(json['pasi_assessment'] ?? {}),
      diagnosis: Diagnosis.fromJson(json['diagnosis'] ?? {}),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'area_analysis': areaAnalysis.toJson(),
      'area_calculation': areaCalculation.toJson(),
      'color_analysis': colorAnalysis.toJson(),
      'pasi_assessment': pasiAssessment.toJson(),
      'diagnosis': diagnosis.toJson(),
      'note': note,
    };
  }
}

class AreaAnalysis {
  final int affectedPixels;
  final int totalPixels;
  final double areaPercentage;
  final int areaScore;
  final List<LesionDetail> lesionDetails;

  AreaAnalysis({
    required this.affectedPixels,
    required this.totalPixels,
    required this.areaPercentage,
    required this.areaScore,
    required this.lesionDetails,
  });

  factory AreaAnalysis.fromJson(Map<String, dynamic> json) {
    List<LesionDetail> details = [];
    if (json['lesion_details'] != null) {
      details = List<LesionDetail>.from(
        (json['lesion_details'] as List).map((x) => LesionDetail.fromJson(x))
      );
    }

    return AreaAnalysis(
      affectedPixels: json['affected_pixels'] ?? 0,
      totalPixels: json['total_pixels'] ?? 0,
      areaPercentage: (json['area_percentage'] ?? 0).toDouble(),
      areaScore: json['area_score'] ?? 0,
      lesionDetails: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'affected_pixels': affectedPixels,
      'total_pixels': totalPixels,
      'area_percentage': areaPercentage,
      'area_score': areaScore,
      'lesion_details': lesionDetails.map((detail) => detail.toJson()).toList(),
    };
  }
}

class LesionDetail {
  final String region;
  final double avgDepth;
  final int areaPixels;

  LesionDetail({
    required this.region,
    required this.avgDepth,
    required this.areaPixels,
  });

  factory LesionDetail.fromJson(Map<String, dynamic> json) {
    return LesionDetail(
      region: json['region'] ?? '',
      avgDepth: (json['avg_depth'] ?? 0).toDouble(),
      areaPixels: json['area_pixels'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'avg_depth': avgDepth,
      'area_pixels': areaPixels,
    };
  }
}

class AreaCalculation {
  final bool stickerFound;
  final List<int>? stickerCenter;
  final int stickerRadiusPixels;
  final int stickerAreaPixels;
  final double stickerAreaMm2;
  final double scaleFactor;
  final double psoriasisAreaPixels;
  final double psoriasisAreaMm2;
  final double psoriasisAreaCm2;
  final double affectedAreaCm2;
  final double percentageOfRegion;
  final int lesionCount;
  final double largestLesionCm2;

  AreaCalculation({
    required this.stickerFound,
    this.stickerCenter,
    required this.stickerRadiusPixels,
    required this.stickerAreaPixels,
    required this.stickerAreaMm2,
    required this.scaleFactor,
    required this.psoriasisAreaPixels,
    required this.psoriasisAreaMm2,
    required this.psoriasisAreaCm2,
    required this.affectedAreaCm2,
    required this.percentageOfRegion,
    required this.lesionCount,
    required this.largestLesionCm2,
  });

  factory AreaCalculation.fromJson(Map<String, dynamic> json) {
    List<int>? center;
    if (json['sticker_center'] != null) {
      // Handle the case where sticker_center might contain doubles
      center = (json['sticker_center'] as List).map<int>((item) {
        if (item is int) return item;
        if (item is double) return item.round();
        return 0; // fallback
      }).toList();
    }

    return AreaCalculation(
      stickerFound: json['sticker_found'] ?? false,
      stickerCenter: center,
      stickerRadiusPixels: json['sticker_radius_pixels'] != null ? (json['sticker_radius_pixels'] is int ? json['sticker_radius_pixels'] : (json['sticker_radius_pixels'] as double).round()) : 0,
      stickerAreaPixels: json['sticker_area_pixels'] != null ? (json['sticker_area_pixels'] is int ? json['sticker_area_pixels'] : (json['sticker_area_pixels'] as double).round()) : 0,
      stickerAreaMm2: (json['sticker_area_mm2'] ?? 0).toDouble(),
      scaleFactor: (json['scale_factor'] ?? 0).toDouble(),
      psoriasisAreaPixels: (json['psoriasis_area_pixels'] ?? 0).toDouble(),
      psoriasisAreaMm2: (json['psoriasis_area_mm2'] ?? 0).toDouble(),
      psoriasisAreaCm2: (json['psoriasis_area_cm2'] ?? 0).toDouble(),
      affectedAreaCm2: (json['affected_area_cm2'] ?? json['psoriasis_area_cm2'] ?? 0).toDouble(),
      percentageOfRegion: (json['percentage_of_region'] ?? 0).toDouble(),
      lesionCount: json['lesion_count'] != null ? (json['lesion_count'] is int ? json['lesion_count'] : (json['lesion_count'] as double).round()) : 0,
      largestLesionCm2: (json['largest_lesion_cm2'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sticker_found': stickerFound,
      'sticker_center': stickerCenter,
      'sticker_radius_pixels': stickerRadiusPixels,
      'sticker_area_pixels': stickerAreaPixels,
      'sticker_area_mm2': stickerAreaMm2,
      'scale_factor': scaleFactor,
      'psoriasis_area_pixels': psoriasisAreaPixels,
      'psoriasis_area_mm2': psoriasisAreaMm2,
      'psoriasis_area_cm2': psoriasisAreaCm2,
      'affected_area_cm2': affectedAreaCm2,
      'percentage_of_region': percentageOfRegion,
      'lesion_count': lesionCount,
      'largest_lesion_cm2': largestLesionCm2,
    };
  }
}

class ColorAnalysis {
  final double averageRednessPercentage;
  final int erythemaScore;
  final List<RednessDetail> rednessDetails;
  final int scalingScore;
  final int indurationScore;
  final List<String> dominantColors;

  ColorAnalysis({
    required this.averageRednessPercentage,
    required this.erythemaScore,
    required this.rednessDetails,
    required this.scalingScore,
    required this.indurationScore,
    required this.dominantColors,
  });

  factory ColorAnalysis.fromJson(Map<String, dynamic> json) {
    List<RednessDetail> details = [];
    if (json['redness_details'] != null) {
      details = List<RednessDetail>.from(
        (json['redness_details'] as List).map((x) => RednessDetail.fromJson(x))
      );
    }
    
    List<String> colors = [];
    if (json['dominant_colors'] != null) {
      colors = List<String>.from(json['dominant_colors']);
    }

    return ColorAnalysis(
      averageRednessPercentage: (json['average_redness_percentage'] ?? 0).toDouble(),
      erythemaScore: json['erythema_score'] ?? 0,
      rednessDetails: details,
      scalingScore: json['scaling_score'] ?? 0,
      indurationScore: json['induration_score'] ?? 0,
      dominantColors: colors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_redness_percentage': averageRednessPercentage,
      'erythema_score': erythemaScore,
      'redness_details': rednessDetails.map((detail) => detail.toJson()).toList(),
      'scaling_score': scalingScore,
      'induration_score': indurationScore,
      'dominant_colors': dominantColors,
    };
  }
}

class RednessDetail {
  final String region;
  final double redPercentage;
  final double redIntensity;

  RednessDetail({
    required this.region,
    required this.redPercentage,
    required this.redIntensity,
  });

  factory RednessDetail.fromJson(Map<String, dynamic> json) {
    return RednessDetail(
      region: json['region'] ?? '',
      redPercentage: (json['red_percentage'] ?? 0).toDouble(),
      redIntensity: (json['red_intensity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'red_percentage': redPercentage,
      'red_intensity': redIntensity,
    };
  }
}

class PasiAssessment {
  final String bodyRegion;
  final double regionWeight;
  final int areaScore;
  final int erythemaScore;
  final int indurationScore;
  final int desquamationScore;
  final double regionalPasi;
  final double pasiScore;
  final String pasiSeverity;
  final List<String> recommendations;
  final double regionalScore;
  final double estimatedTotalPasi;

  PasiAssessment({
    required this.bodyRegion,
    required this.regionWeight,
    required this.areaScore,
    required this.erythemaScore,
    required this.indurationScore,
    required this.desquamationScore,
    required this.regionalPasi,
    required this.pasiScore,
    required this.pasiSeverity,
    required this.recommendations,
    required this.regionalScore,
    required this.estimatedTotalPasi,
  });

  factory PasiAssessment.fromJson(Map<String, dynamic> json) {
    List<String> recs = [];
    if (json['recommendations'] != null) {
      recs = List<String>.from(json['recommendations']);
    }

    return PasiAssessment(
      bodyRegion: json['body_region'] ?? '',
      regionWeight: (json['region_weight'] ?? 0).toDouble(),
      areaScore: json['area_score'] ?? 0,
      erythemaScore: json['erythema_score'] ?? 0,
      indurationScore: json['induration_score'] ?? 0,
      desquamationScore: json['desquamation_score'] ?? 0,
      regionalPasi: (json['regional_pasi'] ?? 0).toDouble(),
      pasiScore: (json['pasi_score'] ?? 0).toDouble(),
      pasiSeverity: json['pasi_severity'] ?? 'Unknown',
      recommendations: recs,
      regionalScore: (json['regional_score'] ?? json['regional_pasi'] ?? 0).toDouble(),
      estimatedTotalPasi: (json['estimated_total_pasi'] ?? json['pasi_score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'body_region': bodyRegion,
      'region_weight': regionWeight,
      'area_score': areaScore,
      'erythema_score': erythemaScore,
      'induration_score': indurationScore,
      'desquamation_score': desquamationScore,
      'regional_pasi': regionalPasi,
      'pasi_score': pasiScore,
      'pasi_severity': pasiSeverity,
      'recommendations': recommendations,
      'regional_score': regionalScore,
      'estimated_total_pasi': estimatedTotalPasi,
    };
  }
}

class Diagnosis {
  final String severity;
  final String description;
  final List<String> recommendations;
  final String condition;
  final double confidence;
  final List<String> differentialDiagnosis;

  Diagnosis({
    required this.severity,
    required this.description,
    required this.recommendations,
    required this.condition,
    required this.confidence,
    required this.differentialDiagnosis,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    List<String> recs = [];
    if (json['recommendations'] != null) {
      recs = List<String>.from(json['recommendations']);
    }
    
    List<String> diffDiagnosis = [];
    if (json['differential_diagnosis'] != null) {
      diffDiagnosis = List<String>.from(json['differential_diagnosis']);
    }

    return Diagnosis(
      severity: json['severity'] ?? 'Unknown',
      description: json['description'] ?? '',
      recommendations: recs,
      condition: json['condition'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      differentialDiagnosis: diffDiagnosis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'severity': severity,
      'description': description,
      'recommendations': recommendations,
      'condition': condition,
      'confidence': confidence,
      'differential_diagnosis': differentialDiagnosis,
    };
  }
}
