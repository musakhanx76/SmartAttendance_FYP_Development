Smart Attendance System (FYP)

A modern, full-stack smart attendance solution that leverages Deep Learning and Facial Recognition to automate classroom roll calls. Built with a Flutter mobile client and a Django backend API.

 Overview:
 
Traditional attendance systems are time-consuming and prone to proxy marking. This project solves that by allowing teachers to scan a classroom using their mobile device. The system uses AI to extract facial blueprints, matches them against a registered database, and securely logs attendance with timestamped precision.

Key Features:

* **AI Facial Recognition:** Utilizes OpenCV and dlib to identify students in real-time.
* **Role-Based Dashboards:** Dedicated mobile interfaces for both Teachers and Students.
* **Secure Enrollment:** Biometric registration process for new students.
* **Automated Reporting:** One-click CSV export for classroom attendance records.
* **Classroom Management:** Dynamic join codes, pending request approvals, and student roster management.

---

Technology Stack:

**Frontend (Mobile App)**
* **Framework:** Flutter (Dart)
* **State Management:** [Insert your state management, e.g., Provider / Riverpod / setState]
* **HTTP Client:** Dio

**Backend (API Server)**
* **Framework:** Django & Django Rest Framework (Python)
* **Database:** PostgreSQL
* **AI/Computer Vision:** OpenCV, face_recognition, dlib

---

Installation & Setup
Because this is a client-server architecture, you will need to run the backend and the mobile app simultaneously.

### 1. Backend Setup (Django)
Ensure you have Python 3.8+ installed.

```bash
# Clone the repository
git clone [https://github.com/musakhanx76/SmartAttendance_FYP_Final_Release.git](https://github.com/musakhanx76/SmartAttendance_FYP_Final_Release.git)
cd SmartAttendance_FYP_Final_Release/backend

# Create and activate a virtual environment
python -m venv venv
source venv/Scripts/activate  # On Windows

# Install dependencies (Make sure dlib and CMake are installed!)
pip install -r requirements.txt

# Run database migrations
python manage.py makemigrations
python manage.py migrate

# Start the development server
python manage.py runserver
