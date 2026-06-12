import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_dashboard.dart';
import '../api_constants.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_rollNoController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Roll Number and Password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String url = '${ApiConstants.baseUrl}/student_login/'; // Using your uppercase constant!

    try {
      var response = await Dio().post(url, data: {
        'rollNo': _rollNoController.text.trim(),
        'password': _passwordController.text.trim(),
      });

      // 🔥 1. PRINT THE RAW DATA TO SEE THE HIDDEN DJANGO ERROR
      print("====== RAW RESPONSE DATA: ${response.data} ======");

      // 🔥 2. SAFETY NET: Convert String to JSON if Django messes up
      var responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Server returned HTML text. Check the VS Code Terminal!"), 
              backgroundColor: Colors.red
            ),
          );
          setState(() => _isLoading = false);
          return; // Stop the crash!
        }
      }

      if (response.statusCode == 200) {
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();
        
        // 🔥 3. Safely extract data using the parsed responseData
        await prefs.setString('rollNo', responseData['rollNo'].toString()); 
        await prefs.setString('student_name', responseData['student_name'].toString());
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentDashboard()),
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Failed to connect to server.";
      
      // 🔥 4. Safe Error Catching
      if (e.response != null && e.response?.data != null) {
        var errorData = e.response?.data;
        if (errorData is String) {
          errorMessage = "Server Error (Missing trailing slash in Django urls.py?)";
        } else {
          errorMessage = errorData['error'] ?? errorMessage;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Student Login'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_person_rounded, size: 80, color: Colors.indigo),
              const SizedBox(height: 32),
              TextField(
                controller: _rollNoController,
                decoration: InputDecoration(
                  labelText: 'Roll Number',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}