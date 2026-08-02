import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api_constants.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  _TakeAttendanceScreenState createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  bool _isLoading = false;
  List<dynamic> _availableClasses = [];
  String? _selectedCourseCode;
  
  // We use ImagePicker to easily open the native camera
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchClasses(); // Get the classes as soon as the screen opens!
  }

  // 1. Grab the classes from Django for the Dropdown
  Future<void> _fetchClasses() async {
    try {
      // 1. Get the Teacher ID from memory
      final prefs = await SharedPreferences.getInstance();
      final int? teacherId = prefs.getInt('teacher_id');

      if (teacherId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Not logged in. Please log out and log in again.')),
        );
        return;
      }

      String url = '${ApiConstants.baseUrl}/get_classes/$teacherId/';
      
      var response = await Dio().get(url);
      
      // Check if classes exist and list is not empty
      if (response.statusCode == 200 && response.data['classes'] != null) {
        setState(() {
          _availableClasses = response.data['classes'];
          if (_availableClasses.isNotEmpty) {
            _selectedCourseCode = _availableClasses[0]['course_code']; 
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading classes.')),
      );
    }
  }
  // 2. Open Camera, Capture Image, and Send to Django
  Future<void> _openCameraAndScan() async {
    if (_selectedCourseCode == null) return;

    // Open the camera to take a picture (You can change this to pickVideo if you prefer)
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    
    if (photo == null) return; // The teacher cancelled the camera

    setState(() { _isLoading = true; });

    try {
      String url = '${ApiConstants.baseUrl}/mark_attendance/';

      // 🌟 THIS IS THE MAGIC: We package the File AND the Course Code together!
      FormData formData = FormData.fromMap({
        "course_code": _selectedCourseCode, // Sent as text
        "classroom_media": await MultipartFile.fromFile(photo.path, filename: photo.name), // Sent as a file
      });

      var response = await Dio().post(url, data: formData);

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // Success! Show how many students were marked.
        int count = response.data['recognized_count'];
        List<dynamic> names = response.data['present_students'];
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Scan Complete!'),
            content: Text('Marked $count students present:\n\n${names.join(", ")}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Awesome', style: TextStyle(color: Colors.teal))
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image with AI.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('AI Attendance Scanner'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.document_scanner_rounded, size: 100, color: Colors.teal),
            const SizedBox(height: 32),
            
            const Text(
              'Select a class to scan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // THE DROPDOWN MENU
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal, width: 2),
              ),
              child: _availableClasses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text("Loading classes...")),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCourseCode,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.teal),
                      style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
                      onChanged: (String? newValue) {
                        setState(() { _selectedCourseCode = newValue!; });
                      },
                      items: _availableClasses.map<DropdownMenuItem<String>>((dynamic classItem) {
                        return DropdownMenuItem<String>(
                          value: classItem['course_code'],
                          child: Text("${classItem['name']} (${classItem['course_code']})"),
                        );
                      }).toList(),
                    ),
                  ),
            ),
            
            const SizedBox(height: 48),

            // THE CAMERA BUTTON
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                icon: _isLoading 
                  ? const SizedBox() 
                  : const Icon(Icons.camera_alt_rounded, size: 28, color: Colors.white),
                label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Open Camera & Scan', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                // Disable button if loading or if no classes exist
                onPressed: (_isLoading || _availableClasses.isEmpty) ? null : _openCameraAndScan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}