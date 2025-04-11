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
      // Ensure Firestore is initialized
      if (_firestore == null) {
        throw Exception('Firestore is not initialized properly');
      }
      
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
        diagnosis: diagnosis ?? 'Pending diagnosis',
        notes: notes,
      );
      
      // Save to Firestore with explicit error handling
      await docRef.set(report.toJson())
          .timeout(const Duration(seconds: 10), 
              onTimeout: () => throw Exception('Connection timeout. Please check your internet connection.'));
      
      // Verify the document was created
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Failed to create report. Please try again.');
      }
      
      return report;
    } catch (e) {
      print('Error in addReport: $e');
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception('Permission denied: You don\'t have access to add reports');
        } else if (e.code == 'unavailable') {
          throw Exception('Service unavailable. Please check your internet connection and try again.');
        }
      }
      throw Exception('Failed to add report: ${e.toString()}');
    }
  }
  
  // Get reports for a specific patient
  static Future<List<ReportModel>> getPatientReports(String patientId) async {
    try {
      // First try with the compound query (requires index)
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
        // If index error occurs, fallback to simple query without ordering
        if (e.toString().contains('failed-precondition') || 
            e.toString().contains('requires an index')) {
          print('Index error in getPatientReports, using fallback query: $e');
          
          // Fallback query without ordering (no index needed)
          final QuerySnapshot snapshot = await _reportsCollection
              .where('patientId', isEqualTo: patientId)
              .get();
          
          // Manual sorting after fetching
          final reports = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ReportModel.fromJson(data);
          }).toList();
          
          // Sort manually by timestamp (descending)
          reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return reports;
        } else {
          // For other errors, rethrow
          rethrow;
        }
      }
    } catch (e) {
      print('Error in getPatientReports: $e');
      throw Exception('Failed to load patient reports: ${e.toString()}');
    }
  }
  
  // Get reports for a specific doctor (all their patients)
  static Future<List<ReportModel>> getDoctorReports(String doctorId) async {
    try {
      // First try with the compound query (requires index)
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
        // If index error occurs, fallback to simple query without ordering
        if (e.toString().contains('failed-precondition') || 
            e.toString().contains('requires an index')) {
          print('Index error in getDoctorReports, using fallback query: $e');
          
          // Fallback query without ordering (no index needed)
          final QuerySnapshot snapshot = await _reportsCollection
              .where('doctorId', isEqualTo: doctorId)
              .get();
          
          // Manual sorting after fetching
          final reports = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ReportModel.fromJson(data);
          }).toList();
          
          // Sort manually by timestamp (descending)
          reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return reports;
        } else {
          // For other errors, rethrow
          rethrow;
        }
      }
    } catch (e) {
      print('Error in getDoctorReports: $e');
      throw Exception('Failed to load doctor reports: ${e.toString()}');
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