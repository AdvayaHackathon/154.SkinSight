import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.userType == 'doctor' 
            ? 'Doctor Dashboard' 
            : 'Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/welcome');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child: Icon(
                  user.userType == 'doctor' 
                      ? Icons.medical_services 
                      : Icons.person,
                  size: 50,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Name: ${user.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Email: ${user.email}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    if (user.phoneNumber != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Phone: ${user.phoneNumber}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'User Type: ${user.userType.toUpperCase()}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                user.userType == 'doctor' 
                    ? 'Welcome to your Doctor Dashboard!' 
                    : 'Welcome to your Patient Dashboard!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'You are logged in as ${user.userType}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 