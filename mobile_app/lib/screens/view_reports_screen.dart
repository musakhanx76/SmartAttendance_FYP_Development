import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  _ViewReportsScreenState createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<dynamic> _attendanceRecords = [];
  String _message = "Select a class and date to view attendance.";
  
  // 🌟 FIX 1: Add these missing variables
  List<dynamic> _availableClasses = [];
  String? _selectedCourseCode;

  @override
  void initState() {
    super.initState();
    _fetchClasses(); // Need to fetch the list of classes first
  }

  // 🌟 FIX 2: Add this to get the classes for the dropdown
  Future<void> _fetchClasses() async {
    try {
      // 1. Get the Teacher ID from memory
      final prefs = await SharedPreferences.getInstance();
      final int? teacherId = prefs.getInt('teacher_id');

      if (teacherId == null) {
        setState(() => _message = "Error: Please log out and log back in.");
        return;
      }

      // 2. Inject the ID into the URL (Make sure this matches your Django urls.py)
      String url = 'http://10.121.30.235:8000/api/get_classes/$teacherId/';
      
      var response = await Dio().get(url);
      if (response.statusCode == 200) {
        setState(() {
          _availableClasses = response.data['classes'] ?? [];
          if (_availableClasses.isNotEmpty) {
            _selectedCourseCode = _availableClasses[0]['course_code'];
          } else {
            _message = "No classes found for this account.";
          }
        });
        // Only fetch reports if we actually have a class selected
        if (_selectedCourseCode != null) {
          _fetchReports();
        }
      }
    } catch (e) {
      print("Error fetching classes: $e");
      setState(() => _message = "Failed to load classes. Check server connection.");
    }
  }
  Future<void> _fetchReports() async {
    if (_selectedCourseCode == null) return;
    setState(() { _isLoading = true; _attendanceRecords = []; });

    String dateStr = _formatDateForApi(_selectedDate);
    String url = 'http://10.121.30.235:8000/api/get_report/$_selectedCourseCode/$dateStr/';

    try {
      var response = await Dio().get(url);
      if (response.statusCode == 200) {
        setState(() {
          _attendanceRecords = response.data['records'] ?? [];
          _message = response.data['message'] ?? "No records found.";
        });
      }
    } catch (e) {
      setState(() => _message = "Error fetching data.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🌟 FIX 3: Your download function (Cleaned up)
  Future<void> _downloadReport() async {
    if (_selectedCourseCode == null) return;

    String dateStr = _formatDateForApi(_selectedDate);
    final String urlString = 'http://10.121.30.235:8000/api/export_csv/$_selectedCourseCode/$dateStr/';
    final Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
  
  // ... rest of your _selectDate and build method ...
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orangeAccent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; });
      _fetchReports(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // THE NEW FILTERS BAR (Class Dropdown + Date Picker)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Class Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Select Class:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                    if (_availableClasses.isNotEmpty)
                      DropdownButton<String>(
                        value: _selectedCourseCode,
                        icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.orangeAccent),
                        elevation: 4,
                        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        underline: Container(height: 2, color: Colors.orangeAccent),
                        onChanged: (String? newValue) {
                          setState(() { _selectedCourseCode = newValue!; });
                          _fetchReports(); // Fetch new data when class changes!
                        },
                        items: _availableClasses.map<DropdownMenuItem<String>>((dynamic classItem) {
                          return DropdownMenuItem<String>(
                            value: classItem['course_code'],
                            child: Text("${classItem['name']} (${classItem['course_code']})"),
                          );
                        }).toList(),
                      )
                    else
                      const Text("Loading classes...", style: TextStyle(color: Colors.orange)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Date Picker (Your original code, slightly adjusted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.orangeAccent, size: 28),
                        const SizedBox(width: 12),
                        Text(displayDate, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[50],
                        foregroundColor: Colors.orange[900],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _selectDate(context),
                      child: const Text('Change Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),

          // THE EXPORT BUTTON (Only shows if there is data)
          if (!_isLoading && _attendanceRecords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text('Download CSV Spreadsheet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _downloadReport,
                ),
              ),
            ),

          // THE DATA LIST
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
              : _attendanceRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(_message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _attendanceRecords.length,
                    itemBuilder: (context, index) {
                      var record = _attendanceRecords[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[50],
                            child: const Icon(Icons.check_circle_rounded, color: Colors.green),
                          ),
                          title: Text(record['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text('Roll No: ${record['rollNo']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(record['status'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(record['time'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
