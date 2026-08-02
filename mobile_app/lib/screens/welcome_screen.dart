import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'teacher_login_screen.dart';
import '../main.dart'; // Importing your RegisterScreen from main.dart

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // App Logo or Icon
              const Icon(Icons.school_rounded, size: 100, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'Smart Attendance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'Powered by AI Face Recognition',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 60),
              
              const Text(
                'Please select your role to continue:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Teacher Button
             _buildRoleButton(
                context,
                title: 'I am a Teacher',
                icon: Icons.assignment_ind_rounded,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    
                    MaterialPageRoute(builder: (context) => const TeacherLoginScreen()),
                  );
                },
              ),
              
              const SizedBox(height: 16),

              // Student Login Button
          _buildRoleButton(
            context,
            title: 'Student Login',
            icon: Icons.login_rounded,
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Student Registration Button
          _buildRoleButton(
            context,
            title: 'New Student Registration',
            icon: Icons.face_retouching_natural_rounded,
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
          ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 24,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis, // This adds '...' if the text is too long!
            ),
           ),
          ],
        ),
      ),
    );
  }
}