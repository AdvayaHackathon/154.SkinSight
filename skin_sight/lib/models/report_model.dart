import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String patientId; // Patient's UID
  final String doctorId; // Doctor's UID
  final String pid; // Patient ID
  final String? imageUrl;
  final String? diagnosis;
  final String severity; // e.g., "Mild", "Moderate", "Severe"
  final DateTime timestamp;
  final String? notes;
  final String bodyLocation; // Body location where the image was taken
  final Map<String, dynamic>? additionalData;

  ReportModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.pid,
    required this.severity,
    required this.timestamp,
    this.imageUrl,
    this.diagnosis,
    this.notes,
    this.bodyLocation = 'Skin', // Default to 'Skin' if not specified
    this.additionalData,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      pid: json['pid'] ?? '',
      imageUrl: json['imageUrl'],
      diagnosis: json['diagnosis'],
      severity: json['severity'] ?? 'Unknown',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      notes: json['notes'],
      bodyLocation: json['bodyLocation'] ?? 'Skin',
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'pid': pid,
      'imageUrl': imageUrl,
      'diagnosis': diagnosis,
      'severity': severity,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'bodyLocation': bodyLocation,
      'additionalData': additionalData,
    };
  }
} 