import random 
import csv
import string
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework.views import APIView
from .serializers import StudentSerializer
"""from .models import Student
from .ai_utils import extract_face_blueprint # Import our new AI Brain"""
from django.core.files.storage import FileSystemStorage
from .models import Student, Attendance, ClassRoom, Enrollment , ClassSession, Teacher
from datetime import date
from .ai_utils import extract_face_blueprint, scan_classroom_faces
from django.http import JsonResponse
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt

@api_view(['POST'])
def register_student(request):
    """
    Receives the Flutter form data, saves the video, 
    and triggers the AI to extract the face blueprint.
    """
    serializer = StudentSerializer(data=request.data)
    
    if serializer.is_valid():
        # 1. Save the student and the video to the server
        student = serializer.save()
        
        # 2. Get the exact folder path where Django saved the .mp4 file
        video_path = student.face_video.path
        
        print(f"AI INITIALIZED: Processing video for {student.name}...")
        
        # 3. Wake up the AI Brain! Pass the video path to dlib
        face_encoding = extract_face_blueprint(video_path)
        
        if face_encoding:
            # 4. SUCCESS! The AI found a face. Save the 128 numbers.
            student.face_encoding = face_encoding
            student.save()
            print("AI SUCCESS: Blueprint saved to PostgreSQL!")
            return Response(
                {"message": "Student registered and face scanned successfully!"}, 
                status=status.HTTP_201_CREATED
            )
        else:
            # 5. FAILURE! The AI couldn't find a face (too dark, covered camera, etc.)
            # We delete the broken record so the database stays perfectly clean.
            student.delete()
            print("AI ERROR: Registration rejected. No face found.")
            return Response(
                {"error": "AI could not detect a clear face. Please try again."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
@api_view(['POST'])
def mark_attendance(request):
    """
    Receives a classroom photo/video from the teacher, scans it using AI,
    and marks recognized students as Present in the database.
    """
    # 1. Grab the uploaded file AND the course code from the request
    uploaded_file = request.FILES.get('classroom_media')
    
    # 🌟 ADDITION 1: Catch the course code sent by Flutter
    course_code = request.data.get('course_code') 
    
    if not uploaded_file:
        return Response({"error": "No image or video file provided."}, status=status.HTTP_400_BAD_REQUEST)
    if not course_code:
        return Response({"error": "No class selected."}, status=status.HTTP_400_BAD_REQUEST)

    fs = FileSystemStorage()
    filename = fs.save(uploaded_file.name, uploaded_file)
    file_path = fs.path(filename)

    try:
        # 🌟 ADDITION 2: Find the specific classroom in the database
        classroom = ClassRoom.objects.get(course_code=course_code)

        all_students = Student.objects.exclude(face_encoding__isnull=True)
        known_students_dict = {student.rollNo: student.face_encoding for student in all_students}
        
        if not known_students_dict:
            return Response({"error": "No students registered in the database yet!"}, status=status.HTTP_400_BAD_REQUEST)

        present_roll_nos, message = scan_classroom_faces(file_path, known_students_dict)
        
        marked_names = []
        today = date.today() # Get today's date

        for roll_no in present_roll_nos:
            student = Student.objects.get(rollNo=roll_no)
            
            # 🌟 ADDITION 3: Check for today's attendance in THIS specific class
            # (We use a manual check instead of get_or_create because date fields with auto_now_add can be tricky)
            already_marked = Attendance.objects.filter(
                student=student, 
                classroom=classroom, 
                date=today
            ).exists()

            if not already_marked:
                Attendance.objects.create(
                    student=student,
                    classroom=classroom, # Link the class!
                    status="Present"
                )
            
            marked_names.append(student.name)

        fs.delete(filename)

        return Response({
            "message": "AI Scanning Complete!",
            "recognized_count": len(marked_names),
            "present_students": marked_names
        }, status=status.HTTP_200_OK)

    except ClassRoom.DoesNotExist:
        fs.delete(filename)
        return Response({"error": "Invalid course code provided."}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        import traceback
        traceback.print_exc()
        
        fs.delete(filename)
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
#for deleting student    
@csrf_exempt
def delete_student(request, roll_number):
    if request.method == 'DELETE':
        # 1. Clean the incoming text (remove hidden spaces)
        clean_roll = roll_number.strip()
        
        # 2. Print it to your terminal so you can see exactly what arrived!
        print(f"--- ATTEMPTING TO DELETE ROLL NUMBER: '{clean_roll}' ---")
        
        try:
            # 3. Use __iexact for Case-Insensitive matching
            student = Student.objects.get(rollNo__iexact=clean_roll)
            student.delete()
            
            print(f"--- SUCCESS: {clean_roll} deleted! ---")
            return JsonResponse({'status': 'success', 'message': f'Student {clean_roll} deleted successfully.'}, status=200)
        
        except Student.DoesNotExist:
            print(f"--- FAILED: {clean_roll} is not in the database! ---")
            return JsonResponse({'status': 'error', 'message': 'Student not found.'}, status=404)
            
    return JsonResponse({'status': 'error', 'message': 'Invalid request method.'}, status=400)

#for getting attendance report
@api_view(['GET'])
def get_attendance_report(request, date_str):
    """
    Receives a date (YYYY-MM-DD) from Flutter and returns 
    a list of all students marked present on that specific day.
    """
    try:
        # Ask the database for all attendance records matching the requested date
        records = Attendance.objects.filter(date=date_str)
        
        if not records.exists():
            return Response({"message": "No attendance records found for this date.", "records": []}, status=status.HTTP_200_OK)

        # Package the data neatly for Flutter
        data = []
        for record in records:
            data.append({
                "name": record.student.name,
                "rollNo": record.student.rollNo,
                "time": record.time.strftime("%I:%M %p"), # Formats time to '02:30 PM'
                "status": record.status
            })
            
        return Response({
            "message": f"Found {len(data)} records.", 
            "date": date_str, 
            "records": data
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    
    


# ==========================================
# LMS GOOGLE CLASSROOM SYSTEM ENDPOINTS
# ==========================================

#Student Requesting to join a class using a code
@api_view(['POST'])
def join_class(request):
    roll_no = request.data.get('rollNo')
    join_code = request.data.get('join_code')

    try:
        student = Student.objects.get(rollNo__iexact=roll_no)
        classroom = ClassRoom.objects.get(join_code=join_code)

        # Check if they already sent a request or are already enrolled
        enrollment, created = Enrollment.objects.get_or_create(
            student=student,
            classroom=classroom
        )

        if not created:
            status_msg = "Approved" if enrollment.is_approved else "Pending"
            return Response({"message": f"You already have a {status_msg} request for this class."}, status=status.HTTP_400_BAD_REQUEST)

        return Response({"message": f"Request sent to join {classroom.course_code}. Waiting for teacher approval!"}, status=status.HTTP_201_CREATED)

    except Student.DoesNotExist:
        return Response({"error": "Student not found. Please register your face first."}, status=status.HTTP_404_NOT_FOUND)
    except ClassRoom.DoesNotExist:
        return Response({"error": "Invalid Class Code. Please check the WhatsApp group."}, status=status.HTTP_404_NOT_FOUND)

#for teacher Viewing all pending requests
@api_view(['GET'])
def get_pending_requests(request):
    try:
        pending = Enrollment.objects.filter(is_approved=False)
        data = []
        for req in pending:
            data.append({
                "enrollment_id": req.id,
                "student_name": req.student.name,
                "rollNo": req.student.rollNo,
                "class_name": req.classroom.name,
                "course_code": req.classroom.course_code,
                "date": req.request_date.strftime("%b %d, %Y")
            })
        return Response({"requests": data}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#for teacher Approve a student's request
@api_view(['POST'])
def approve_student(request, enrollment_id):
    try:
        enrollment = Enrollment.objects.get(id=enrollment_id)
        enrollment.is_approved = True
        enrollment.save()
        return Response({"message": f"{enrollment.student.name} approved for {enrollment.classroom.course_code}!"}, status=status.HTTP_200_OK)
    except Enrollment.DoesNotExist:
        return Response({"error": "Request not found."}, status=status.HTTP_404_NOT_FOUND)

#for teacher approving the finalized list of "My Students"
@api_view(['GET'])
def get_approved_students(request):
    try:
        # Fetch ONLY students where the teacher clicked "Approve"
        approved = Enrollment.objects.filter(is_approved=True)
        
        data = []
        for item in approved:
            data.append({
                "enrollment_id": item.id,
                "student_name": item.student.name,
                "rollNo": item.student.rollNo,
                "class_name": item.classroom.name,
                "course_code": item.classroom.course_code
            })
        return Response({"students": data}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
#for removing students from the class
@api_view(['DELETE'])
def remove_student_from_class(request, enrollment_id):
    """Allows a teacher to remove a student from a specific class."""
    try:
        enrollment = Enrollment.objects.get(id=enrollment_id)
        student_name = enrollment.student.name
        class_name = enrollment.classroom.course_code
        enrollment.delete() # This only deletes the connection, not the student's face from the DB!
        return Response({"message": f"{student_name} removed from {class_name}."}, status=status.HTTP_200_OK)
    except Enrollment.DoesNotExist:
        return Response({"error": "Student is not in this class."}, status=status.HTTP_404_NOT_FOUND)

#for student login
@api_view(['POST'])
def student_login(request):
    roll_no = request.data.get('rollNo')
    password = request.data.get('password')

    try:
        # Find the student
        student = Student.objects.get(rollNo__iexact=roll_no)
        
        # Check if password matches
        if student.password == password:
            return Response({
                   "message": "Login successful!",
                   "student_name": student.name,
                   "rollNo": student.rollNo
            },  status=status.HTTP_200_OK)
        else:
            return Response({"error": "Incorrect password."}, status=status.HTTP_401_UNAUTHORIZED)
            
    except Student.DoesNotExist:
        return Response({"error": "Student not found. Please register first."}, status=status.HTTP_404_NOT_FOUND)
"""from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
# Check these imports! They must match your actual filenames
from .models import Student 
from .serializers import StudentSerializer

# 1. REGISTER STUDENT API
class StudentRegisterView(APIView):
    parser_classes = (MultiPartParser, FormParser) 

    def post(self, request, *args, **kwargs):
        serializer = StudentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({
                "status": "success", 
                "message": "Student Registered successfully!"
            }, status=status.HTTP_201_CREATED)
        else:
            return Response({
                "status": "error", 
                "message": f"Registration failed: {serializer.errors}",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)"""

class CreateClassView(APIView):
    def post(self, request):
        class_name = request.data.get('name') 
        course_code = request.data.get('course_code') 
        # 🌟 ADDITION 1: Catch the teacher's ID from Flutter
        teacher_id = request.data.get('teacher_id') 
        
        if not class_name or not course_code or not teacher_id:
            return Response({"error": "Class name, course code, and teacher ID are required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # 🌟 ADDITION 2: Verify the teacher exists in the database
            teacher = Teacher.objects.get(id=teacher_id)
        except Teacher.DoesNotExist:
            return Response({"error": "Teacher account not found."}, status=status.HTTP_404_NOT_FOUND)

        # Generate the random 6-character uppercase code (e.g., 'X7B9WQ')
        secure_join_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

        # 🌟 ADDITION 3: Save the class AND attach the teacher!
        new_class = ClassRoom.objects.create(
            name=class_name,
            course_code=course_code, 
            join_code=secure_join_code,
            teacher=teacher # <--- THE FIX IS HERE
        )

        print(f"DATABASE SUCCESS: Created class {new_class.name} for Teacher ID {teacher_id}")

        return Response(
            {
                "message": "Class created successfully!", 
                "join_code": new_class.join_code
            }, 
            status=status.HTTP_201_CREATED
        )

class TeacherLoginView(APIView):
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')

        try:
            teacher = Teacher.objects.get(email=email, password=password)
            
            # THE CHECK: Are they approved by the Admin?
            if not teacher.is_approved:
                return Response({
                    "error": "Account pending. Please wait for University IT to verify your identity."
                }, status=status.HTTP_403_FORBIDDEN)
            
            return Response({
                "message": "Login successful!",
                "teacher_name": teacher.name,
                "teacher_id": teacher.id
            }, status=status.HTTP_200_OK)
            
        except Teacher.DoesNotExist:
            return Response({"error": "Invalid email or password."}, status=status.HTTP_401_UNAUTHORIZED)



class TeacherRegistrationView(APIView):
    def post(self, request):
        name = request.data.get('name')
        email = request.data.get('email')
        password = request.data.get('password')

        # 1. Make sure they didn't leave anything blank
        if not name or not email or not password:
            return Response({"error": "All fields are required."}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Check if this email is already in the system
        if Teacher.objects.filter(email=email).exists():
            return Response({"error": "This email is already registered."}, status=status.HTTP_400_BAD_REQUEST)

        # 3. Create the pending account! (is_approved defaults to False automatically)
        new_teacher = Teacher.objects.create(
            name=name, 
            email=email, 
            password=password
        )

        return Response({
            "message": "Account request sent! Please wait for Admin approval."
        }, status=status.HTTP_201_CREATED)


class GetTeacherClassesView(APIView):
    # Notice we added teacher_id to the parameters here
    def get(self, request, teacher_id): 
        
        # THE FIX: Filter the database where the foreign key matches the logged-in teacher
        classes = ClassRoom.objects.filter(teacher_id=teacher_id).values('name', 'course_code')
        
        # If they have no classes, return an empty list gracefully
        if not classes:
            return Response({"classes": []}, status=status.HTTP_200_OK)

        return Response({"classes": list(classes)}, status=status.HTTP_200_OK)

class GetClassReportView(APIView):
    def get(self, request, course_code, date_str):
        attendances = Attendance.objects.filter(
            classroom__course_code=course_code, 
            date=date_str
        ).order_by('-time')

        if not attendances.exists():
            return Response({"message": "No attendance records found for this class on this date.", "records": []})

        records = []
        for record in attendances:
            records.append({
                "name": record.student.name,
                "rollNo": record.student.rollNo,
                "time": record.time.strftime('%H:%M:%S'),
                "status": record.status
            })

        return Response({"message": "Success", "records": records}, status=status.HTTP_200_OK)




class ExportClassAttendanceCSV(APIView):
    def get(self, request, course_code, date_str): 
        Attendance.objects.filter(classroom__course_code=course_code, date=date_str)
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="Attendance_{course_code}_{date_str}.csv"'

        writer = csv.writer(response)
        writer.writerow(['Class Code', 'Student Name', 'Roll Number', 'Date', 'Time', 'Status'])

        # Filter by class AND date
        student_ids = Enrollment.objects.filter(classroom__course_code=course_code, is_approved=True).values_list('student', flat=True)
        attendances = Attendance.objects.filter(student__id__in=student_ids, date=date_str).order_by('student__name')

        for record in attendances:
            writer.writerow([
                course_code,
                record.student.name,
                record.student.rollNo,
                record.date.strftime('%Y-%m-%d'),
                record.time.strftime('%H:%M:%S'),
                record.status
            ])

        return response

class GetMyStudentsView(APIView):
    def get(self, request, teacher_id):
        try:
            # THIS IS THE MAGIC LINE: 
            # It looks for approved students, but ONLY in classes owned by THIS specific teacher.
            enrollments = Enrollment.objects.filter(
                classroom__teacher_id=teacher_id, 
                is_approved=True
            )
            
            data = []
            for item in enrollments:
                data.append({
                    "enrollment_id": item.id,
                    "student_name": item.student.name,
                    "rollNo": item.student.rollNo,
                    "class_name": item.classroom.name,
                    "course_code": item.classroom.course_code
                })
                
            return Response({"students": data}, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_student_dashboard_classes(request, roll_no):
    """Returns the classes a student has joined and their approval status."""
    try:
        # Find all enrollments for this specific roll number
        enrollments = Enrollment.objects.filter(student__rollNo__iexact=roll_no)
        
        data = []
        for e in enrollments:
            data.append({
                "class_name": e.classroom.name,
                "course_code": e.classroom.course_code,
                "status": "Approved" if e.is_approved else "Pending"
            })
            
        return Response({"classes": data}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_student_attendance_history(request, roll_no):
    """Returns the complete attendance history for a specific student."""
    try:
        # Get all attendance records, newest first
        records = Attendance.objects.filter(student__rollNo__iexact=roll_no).order_by('-date', '-time')
        
        data = []
        for r in records:
            data.append({
                "course_code": r.classroom.course_code,
                "class_name": r.classroom.name,
                "date": r.date.strftime("%Y-%m-%d"),
                "time": r.time.strftime("%I:%M %p"),
                "status": r.status
            })
            
        return Response({"attendance": data}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)