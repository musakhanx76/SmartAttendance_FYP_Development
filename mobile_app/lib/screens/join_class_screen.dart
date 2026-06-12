import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api_constants.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({Key? key}) : super(key: key);

  @override
  _JoinClassScreenState createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinClass() async {
    if (_rollNoController.text.isEmpty || _joinCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both your Roll Number and the Class Code!')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // 🔥 CHANGE THIS TO YOUR ACTUAL IP ADDRESS
    String url = '${ApiConstants.baseUrl}/join_class/';

    try {
      var response = await Dio().post(url, data: {
        'rollNo': _rollNoController.text.trim(),
        'join_code': _joinCodeController.text.trim(),
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green),
        );
        _joinCodeController.clear(); // Clear the code box after success
      }
    } on DioException catch (e) {
      String errorMessage = "Failed to connect to server.";
      if (e.response != null && e.response?.data != null) {
        // Grab the specific error message from our Django API
        errorMessage = e.response?.data['error'] ?? e.response?.data['message'] ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Join a Class'),
        backgroundColor: Colors.blueAccent, // Blue for students, Orange/Red for teachers
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.class_rounded, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'Enter the secret code provided by your teacher to request access to the classroom.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              
              // Roll Number Input
              TextField(
                controller: _rollNoController,
                decoration: InputDecoration(
                  labelText: 'Your Roll Number',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // Join Code Input
              TextField(
                controller: _joinCodeController,
                decoration: InputDecoration(
                  labelText: 'Class Join Code (e.g., X7B9WQ)',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _joinClass,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isLoading ? 'Sending Request...' : 'Request to Join',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}