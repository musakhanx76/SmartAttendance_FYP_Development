import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  _PendingRequestsScreenState createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    
    // 🔥 CHANGE THIS TO YOUR ACTUAL IP ADDRESS
    String url = 'http://10.121.30.235:8000/pending_requests/';

    try {
      var response = await Dio().get(url);
      if (response.statusCode == 200) {
        setState(() {
          _requests = response.data['requests'] ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch requests. Is the server running?")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveStudent(int enrollmentId, int index) async {
    // 🔥 CHANGE THIS TO YOUR ACTUAL IP ADDRESS
    String url = 'http://10.121.30.235:8000/approve_student/$enrollmentId/';

    try {
      var response = await Dio().post(url);
      if (response.statusCode == 200) {
        // Remove the student from the screen instantly
        setState(() {
          _requests.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to approve student."), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: Colors.orangeAccent, // Orange for Teachers
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("You're all caught up!", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const Text("No pending class requests.", style: TextStyle(color: Color.fromARGB(255, 107, 107, 107))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    var request = _requests[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orange[50],
                              child: const Icon(Icons.person, color: Colors.orangeAccent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['student_name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Text(
                                    'Roll No: ${request['rollNo']}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Requests to join: ${request['course_code']}',
                                      style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 36),
                              onPressed: () => _approveStudent(request['enrollment_id'], index),
                              tooltip: 'Approve Student',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}