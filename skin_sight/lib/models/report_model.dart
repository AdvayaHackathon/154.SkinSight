import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String patientId; // Patient's UID
  final String doctorId; // Doctor's UID
  final String pid; // Patient ID
  final String? imageUrl;
  final String? diagnosis;
  final String? severity; // Now optional, for backward compatibility
  final DateTime timestamp;
  final String? notes;
  final String bodyLocation; // Required: head, upper_limbs, trunk, lower_limbs
  final Map<String, dynamic>? additionalData;

  ReportModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.pid,
    required this.timestamp,
    required this.bodyLocation, // Now required
    this.severity, // Now optional
    this.imageUrl,
    this.diagnosis,
    this.notes,
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
      severity: json['severity'], // May be null
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      notes: json['notes'],
      bodyLocation: json['bodyLocation'] ?? 'trunk', // Default to 'trunk' if not specified
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
      'severity': severity, // May be null
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'bodyLocation': bodyLocation,
      'additionalData': additionalData,
    };
  }
} 