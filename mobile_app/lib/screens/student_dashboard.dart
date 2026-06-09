import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'join_class_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _isLoading = true;
  String _studentName = "Student";
  List<dynamic> _myClasses = [];
  Map<String, List<dynamic>> _groupedAttendance = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Grab the student's Roll Number from memory
      final prefs = await SharedPreferences.getInstance();
      final String? rollNo = prefs.getString('rollNo');
      final String? savedName = prefs.getString('student_name');

      if (rollNo == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        return;
      }

      if (savedName != null) {
        _studentName = savedName;
      }

      // 2. Fetch Classes and Attendance simultaneously 
      // 🔥 DO NOT FORGET TO KEEP YOUR IP ADDRESS UPDATED HERE
      String classesUrl = 'http://10.121.30.235:8000/api/student_classes/$rollNo/';
      String attendanceUrl = 'http://10.121.30.235:8000/api/student_attendance/$rollNo/';

      final dio = Dio();
      
      // We wait for both network requests to finish
      var results = await Future.wait([
        dio.get(classesUrl),
        dio.get(attendanceUrl),
      ]);

      if (mounted) {
        setState(() {
          _myClasses = results[0].data['classes'] ?? [];
          
          // --- THE NEW GROUPING LOGIC ---
          List<dynamic> rawAttendance = results[1].data['attendance'] ?? [];
          Map<String, List<dynamic>> grouped = {};
          
          for (var record in rawAttendance) {
            String course = record['class_name']; // Grouping by class name
            if (!grouped.containsKey(course)) {
              grouped[course] = [];
            }
            grouped[course]!.add(record);
          }
          
          _groupedAttendance = grouped;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load dashboard data. Check connection.')),
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
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      // RefreshIndicator allows the student to pull down to refresh their data
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: Colors.indigo,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome, $_studentName!',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pull down to refresh your attendance.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // --- 1. JOIN CLASS BUTTON ---
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JoinClassScreen()),
                          ).then((_) => _fetchDashboardData()); // Refresh when returning
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                                child: const Icon(Icons.add_circle_outline_rounded, size: 32, color: Colors.blueAccent),
                              ),
                              const SizedBox(width: 20),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Join a Class', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Enter a code from your teacher', style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // --- 2. MY CLASSES SECTION ---
                    const Text('My Enrollments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_myClasses.isEmpty)
                      const Text("You haven't joined any classes yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myClasses.length,
                        itemBuilder: (context, index) {
                          var classData = _myClasses[index];
                          bool isApproved = classData['status'] == 'Approved';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.class_rounded, color: Colors.indigo),
                              title: Text(classData['class_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(classData['course_code']),
                              trailing: Chip(
                                label: Text(classData['status'], style: TextStyle(color: isApproved ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12)),
                                backgroundColor: isApproved ? Colors.green[50] : Colors.orange[50],
                                side: BorderSide.none,
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 32),

                    // --- 3. ATTENDANCE HISTORY SECTION ---
                    const Text('Recent Attendance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_groupedAttendance.isEmpty)
                      const Text("No attendance records found.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _groupedAttendance.keys.map((courseName) {
                          List<dynamic> records = _groupedAttendance[courseName]!;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              iconColor: Colors.indigo,
                              textColor: Colors.indigo,
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo[50],
                                child: const Icon(Icons.history_edu_rounded, color: Colors.indigo),
                              ),
                              title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text('${records.length} Classes Attended'),
                              children: records.map((record) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                                  leading: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                  title: Text(record['date'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                  trailing: Text(record['time'], style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}