import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final CollectionReference _usersCollection = _firestore.collection('users');

  // Register new user
  static Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? phoneNumber,
  }) async {
    try {
      // Create new user with email and password
      UserCredential userCredential = await FirebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user model
        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          userType: userType,
          phoneNumber: phoneNumber,
        );

        // Save user to Firestore
        await _usersCollection.doc(userCredential.user!.uid).set(userModel.toJson());
        
        return userModel;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Login user
  static Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await FirebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc = await _usersCollection.doc(userCredential.user!.uid).get();
        
        if (userDoc.exists) {
          return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user data
  static Future<UserModel?> getCurrentUser() async {
    User? user = FirebaseService.currentUser;
    
    if (user != null) {
      DocumentSnapshot userDoc = await _usersCollection.doc(user.uid).get();
      
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }

  // Sign out
  static Future<void> signOut() async {
    await FirebaseService.signOut();
  }
} 