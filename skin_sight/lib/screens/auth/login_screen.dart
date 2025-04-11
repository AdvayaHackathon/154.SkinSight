import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isDoctor;
  const LoginScreen({Key? key, this.isDoctor = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = await AuthService.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (user != null) {
          // Check if user type matches
          if ((widget.isDoctor && user.userType == 'doctor') || 
              (!widget.isDoctor && user.userType == 'patient')) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
            );
          } else {
            setState(() {
              _errorMessage = widget.isDoctor 
                  ? 'This account is not registered as a doctor.' 
                  : 'This account is not registered as a patient.';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to sign in. Please try again.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().contains('user-not-found') 
              ? 'No user found with this email.' 
              : e.toString().contains('wrong-password') 
                  ? 'Wrong password provided.' 
                  : 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDoctor ? 'Doctor Login' : 'Patient Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or App Name
                Icon(
                  widget.isDoctor ? Icons.medical_services : Icons.person,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isDoctor ? 'Doctor Login' : 'Patient Login',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => Validators.validateEmail(value),
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => Validators.validatePassword(value),
                ),
                const SizedBox(height: 30),
                
                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                
                // Register Link
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context, 
                      widget.isDoctor ? '/doctor/register' : '/patient/register'
                    );
                  },
                  child: Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                
                // Switch User Type Link
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context, 
                      widget.isDoctor ? '/patient/login' : '/doctor/login'
                    );
                  },
                  child: Text(
                    widget.isDoctor 
                        ? "Login as Patient instead" 
                        : "Login as Doctor instead",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 