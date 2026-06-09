import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'teacher_dashboard.dart'; 
import 'teacher_registration_screen.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({Key? key}) : super(key: key);

  @override
  _TeacherLoginScreenState createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 CHANGE THIS TO YOUR EXACT IP ADDRESS
      String url = 'http://10.121.30.235:8000/api/teacher_login/'; 

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));

      var response = await dio.post(url, data: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // 🔥 STEP 1: SAVE THE ID TO THE PHONE'S MEMORY 🔥
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('teacher_id', response.data['teacher_id']); 

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${response.data['teacher_name']}!'),
            backgroundColor: Colors.green,
          ),
        );

        /// THE FIX: Navigate to your existing Command Centre!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboard()), 
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Network Error";
      
      if (e.response != null) {
        if (e.response?.statusCode == 404) {
          errorMessage = "404 Error: Django cannot find this URL path.";
        } else if (e.response?.data is Map && e.response?.data['error'] != null) {
          errorMessage = e.response?.data['error']; // This will show "Invalid email or password"
        } else {
          errorMessage = "Server error (Status ${e.response?.statusCode}). Check Django terminal.";
        }
      } else {
        errorMessage = "Could not reach server. Check IP address and Wi-Fi.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded, size: 80, color: Colors.indigo),
                      const SizedBox(height: 16),
                      const Text(
                        'Teacher Portal',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to manage your classes',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                      ),
                      const SizedBox(height: 32),
                      
                      // 1. The Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      // 2. The Spacing between the buttons
                      const SizedBox(height: 16),
                      
                      // 3. The Registration Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TeacherRegistrationScreen()),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Request one.",
                          style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}