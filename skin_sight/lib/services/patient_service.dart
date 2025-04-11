import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'dart:math';

class PatientService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  
  // Collection references
  static final CollectionReference _usersCollection = _firestore.collection('users');
  
  // Generate a unique Patient ID (PID)
  static String generatePID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final result = StringBuffer();
    
    // Generate a 8-character alphanumeric code
    for (var i = 0; i < 8; i++) {
      result.write(chars[random.nextInt(chars.length)]);
    }
    
    return result.toString();
  }
  
  // Add a patient to a doctor
  static Future<UserModel?> addPatientToDoctor({
    required String doctorId, 
    required String patientEmail,
    required String patientPid,
    String? patientPhone,
  }) async {
    try {
      // First check if patient already exists with this PID
      final patientByPidQuery = await _usersCollection
          .where('pid', isEqualTo: patientPid)
          .limit(1)
          .get();
      
      UserModel? patient;
      
      if (patientByPidQuery.docs.isNotEmpty) {
        // Patient already exists with this PID
        final patientDoc = patientByPidQuery.docs.first;
        final patientData = patientDoc.data() as Map<String, dynamic>;
        
        patient = UserModel.fromJson(patientData);
        
        // Update the patient's doctor if needed
        if (patient.doctorId != doctorId) {
          await _usersCollection.doc(patient.uid).update({
            'doctorId': doctorId,
            'email': patientEmail, // Update email in case it changed
            'phoneNumber': patientPhone, // Update phone if provided
          });
        }
      } else {
        // Check if patient exists with this email
        final patientByEmailQuery = await _usersCollection
            .where('email', isEqualTo: patientEmail)
            .where('userType', isEqualTo: 'patient')
            .get();
        
        if (patientByEmailQuery.docs.isNotEmpty) {
          // Patient exists with this email but different PID
          final patientDoc = patientByEmailQuery.docs.first;
          final patientData = patientDoc.data() as Map<String, dynamic>;
          
          // Update the patient with the new PID
          await _usersCollection.doc(patientDoc.id).update({
            'pid': patientPid,
            'doctorId': doctorId,
            'phoneNumber': patientPhone,
          });
          
          // Get the updated patient data
          final updatedPatientDoc = await _usersCollection.doc(patientDoc.id).get();
          final updatedPatientData = updatedPatientDoc.data() as Map<String, dynamic>;
          patient = UserModel.fromJson(updatedPatientData);
        } else {
          // Create a new patient with the provided PID
          final patientDocRef = _usersCollection.doc();
          patient = UserModel(
            uid: patientDocRef.id,
            email: patientEmail,
            name: "Patient " + patientPid, // Default name using PID
            userType: 'patient',
            phoneNumber: patientPhone,
            doctorId: doctorId,
            pid: patientPid,
          );
          
          await patientDocRef.set(patient.toJson());
        }
      }
      
      // Add patient to doctor's patient list
      final doctorDoc = await _usersCollection.doc(doctorId).get();
      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data() as Map<String, dynamic>;
        List<String> patientIds = [];
        
        if (doctorData.containsKey('patientIds') && doctorData['patientIds'] != null) {
          patientIds = List<String>.from(doctorData['patientIds']);
        }
        
        if (!patientIds.contains(patient.pid)) {
          patientIds.add(patient.pid!);
          await _usersCollection.doc(doctorId).update({
            'patientIds': patientIds,
          });
        }
      }
      
      return patient;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get all patients for a doctor
  static Future<List<UserModel>> getDoctorPatients(String doctorId) async {
    try {
      final QuerySnapshot snapshot = await _usersCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('userType', isEqualTo: 'patient')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Find a patient by PID
  static Future<UserModel?> findPatientByPID(String pid) async {
    try {
      final QuerySnapshot snapshot = await _usersCollection
          .where('pid', isEqualTo: pid)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Remove a patient from a doctor
  static Future<void> removePatientFromDoctor({
    required String doctorId,
    required String pid,
  }) async {
    try {
      // Find the patient with this PID
      final patient = await findPatientByPID(pid);
      
      if (patient != null && patient.doctorId == doctorId) {
        // Update patient to remove doctor
        await _usersCollection.doc(patient.uid).update({
          'doctorId': null,
        });
        
        // Update doctor's patient list
        final doctorDoc = await _usersCollection.doc(doctorId).get();
        if (doctorDoc.exists) {
          final doctorData = doctorDoc.data() as Map<String, dynamic>;
          
          if (doctorData.containsKey('patientIds') && doctorData['patientIds'] != null) {
            List<String> patientIds = List<String>.from(doctorData['patientIds']);
            
            if (patientIds.contains(pid)) {
              patientIds.remove(pid);
              await _usersCollection.doc(doctorId).update({
                'patientIds': patientIds,
              });
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}