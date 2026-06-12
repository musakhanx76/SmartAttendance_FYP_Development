from django.urls import path
from .views import CreateClassView, TeacherLoginView, TeacherRegistrationView, GetTeacherClassesView, GetClassReportView, ExportClassAttendanceCSV, mark_attendance, GetMyStudentsView, get_student_dashboard_classes, get_student_attendance_history, student_login, register_student, join_class, get_pending_requests, approve_student, remove_student_from_class

urlpatterns = [
   
    path('create_class/', CreateClassView.as_view(), name='create_class'),
    path('teacher_login/', TeacherLoginView.as_view(), name='teacher_login'),
    path('request_teacher/', TeacherRegistrationView.as_view(), name='request_teacher'),
    path('get_classes/<int:teacher_id>/', GetTeacherClassesView.as_view(), name='get_classes'),
    path('my_students/<int:teacher_id>/', GetMyStudentsView.as_view(), name='my_students'),
    path('get_report/<str:course_code>/<str:date_str>/', GetClassReportView.as_view()),
    path('export_csv/<str:course_code>/<str:date_str>/', ExportClassAttendanceCSV.as_view()),
    path('mark_attendance/', mark_attendance, name='mark_attendance'),
    path('student_classes/<str:roll_no>/', get_student_dashboard_classes, name='student_classes'),
    path('student_attendance/<str:roll_no>/', get_student_attendance_history, name='student_attendance'),
    path('student_login/', student_login, name='student_login'),
    path('join_class/', join_class, name='join_class'),
    path('register/', register_student, name='register'),
    path('get_pending_requests/<int:teacher_id>/', get_pending_requests, name='get_pending_requests'),
    path('approve_student/<int:enrollment_id>/', approve_student, name='approve_student'),
    path('remove_student/<int:enrollment_id>/', remove_student_from_class, name='remove_student'),
]
