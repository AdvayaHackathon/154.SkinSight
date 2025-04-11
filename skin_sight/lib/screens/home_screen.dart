import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'doctor/doctor_dashboard.dart';
import 'patient/patient_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirect to the appropriate dashboard based on user type
    if (user.userType == 'doctor') {
      return DoctorDashboard(user: user);
    } else {
      return PatientDashboard(user: user);
    }
  }
} 