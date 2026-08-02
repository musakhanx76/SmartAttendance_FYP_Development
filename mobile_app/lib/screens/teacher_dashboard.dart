import 'package:flutter/material.dart';
import 'create_class_screen.dart';
import 'take_attendance_screen.dart';
import 'view_reports_screen.dart';
import 'pending_requests_screen.dart';
import 'my_classes_screen.dart';
class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Teacher Command Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Add logout logic and return to Login Screen
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome, Professor!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What would you like to do today?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),
            
            // The Interactive Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'Create Class',
                    icon: Icons.add_business_rounded,
                    color: Colors.blueAccent,
                    onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateClassScreen()),
                     );
                    },
                  ),
                  _buildDashboardCard(
                   context,
                   title: 'Take Attendance',
                   icon: Icons.camera_alt_rounded,
                   color: Colors.teal,
                   onTap: () {
                   // THIS IS THE CRITICAL NAVIGATION CODE
                   Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const TakeAttendanceScreen()),
                     );
                    },
                   ),
                  _buildDashboardCard(
                    context,
                    title: 'View Reports',
                    icon: Icons.analytics_rounded,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ViewReportsScreen()),
                     );
                    },
                  ),
                  _buildDashboardCard(
                   context,
                   title: 'My Classes', // Renamed to make more sense!
                   icon: Icons.folder_shared_rounded,
                   color: Colors.deepPurpleAccent,
                   onTap: () {
                     Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const MyClassesScreen()),
                    );
                   },
                  ),
                  _buildDashboardCard(
                   context,
                   title: 'Pending Approvals',
                   icon: Icons.person_add_alt_1_rounded,
                   color: Colors.redAccent,
                   onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PendingRequestsScreen()),
                );
              },
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A helper widget to create beautiful, uniform cards
  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}