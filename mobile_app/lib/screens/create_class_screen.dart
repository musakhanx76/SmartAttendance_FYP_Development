import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({Key? key}) : super(key: key);

  @override
  _CreateClassScreenState createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _generatedClassCode; 

  Future<void> _submitClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedClassCode = null;
    });

    try {
      // 🔥 CHANGE THIS TO YOUR EXACT IP ADDRESS (e.g., 192.168.1.45)
      // DO NOT remove the trailing slash / at the end of the URL!
      String url = 'http://192.168.100.5:8000/api/create_class/'; 

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));

      var response = await dio.post(url, data: {
        'name': _courseNameController.text.trim(),
        'course_code': _courseCodeController.text.trim(),
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _generatedClassCode = response.data['join_code']; 
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Network Error";
      
      if (e.response != null) {
        if (e.response?.statusCode == 404) {
          errorMessage = "404 Error: Django cannot find this URL path.";
        } else if (e.response?.data is Map && e.response?.data['error'] != null) {
          errorMessage = e.response?.data['error'];
        } else {
          errorMessage = "Server crashed (Status ${e.response?.statusCode}). Check Django terminal.";
        }
      } else {
        errorMessage = "Could not reach server. Check IP address and Wi-Fi.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
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
    _courseNameController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Create New Class'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _courseNameController,
                        decoration: InputDecoration(
                          labelText: 'Course Name (e.g., Software Engineering)',
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter a course name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _courseCodeController,
                        decoration: InputDecoration(
                          labelText: 'Course Code (e.g., CS401)',
                          prefixIcon: const Icon(Icons.code_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter a course code' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _submitClass,
                          child: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Generate Class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_generatedClassCode != null)
              Card(
                color: Colors.green[50],
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green.shade200, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                      const SizedBox(height: 12),
                      const Text('Share this code with your students:', style: TextStyle(fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 12),
                      SelectableText(
                        _generatedClassCode!,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}