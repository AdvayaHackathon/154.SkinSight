import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import 'firebase_service.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  
  // Collection references
  static final CollectionReference _usersCollection = _firestore.collection('users');
  static final CollectionReference _reportsCollection = _firestore.collection('reports');
  
  // Add a new report
  static Future<ReportModel> addReport({
    required String patientId,
    required String doctorId,
    required String pid,
    required String severity,
    String? imageUrl,
    String? diagnosis,
    String? notes,
  }) async {
    try {
      // Create a new document reference
      final docRef = _reportsCollection.doc();
      
      // Create report model
      final report = ReportModel(
        id: docRef.id,
        patientId: patientId,
        doctorId: doctorId,
        pid: pid,
        severity: severity,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        diagnosis: diagnosis,
        notes: notes,
      );
      
      // Save to Firestore
      await docRef.set(report.toJson());
      
      return report;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get reports for a specific patient
  static Future<List<ReportModel>> getPatientReports(String patientId) async {
    try {
      final QuerySnapshot snapshot = await _reportsCollection
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ReportModel.fromJson(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get reports for a specific doctor (all their patients)
  static Future<List<ReportModel>> getDoctorReports(String doctorId) async {
    try {
      final QuerySnapshot snapshot = await _reportsCollection
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ReportModel.fromJson(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get a specific report by ID
  static Future<ReportModel?> getReportById(String reportId) async {
    try {
      final DocumentSnapshot doc = await _reportsCollection.doc(reportId).get();
      
      if (doc.exists) {
        return ReportModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update a report
  static Future<void> updateReport(ReportModel report) async {
    try {
      await _reportsCollection.doc(report.id).update(report.toJson());
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete a report
  static Future<void> deleteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).delete();
    } catch (e) {
      rethrow;
    }
  }
} 