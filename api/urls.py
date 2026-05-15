from django.urls import path
from .views import CreateClassView, TeacherLoginView, TeacherRegistrationView, GetTeacherClassesView, GetClassReportView, ExportClassAttendanceCSV, mark_attendance

urlpatterns = [
   
    path('create_class/', CreateClassView.as_view(), name='create_class'),
    path('teacher_login/', TeacherLoginView.as_view(), name='teacher_login'),
    path('request_teacher/', TeacherRegistrationView.as_view(), name='request_teacher'),
    path('get_classes/', GetTeacherClassesView.as_view()),
    path('get_report/<str:course_code>/<str:date_str>/', GetClassReportView.as_view()),
    path('export_csv/<str:course_code>/<str:date_str>/', ExportClassAttendanceCSV.as_view()),
    path('mark_attendance/', mark_attendance, name='mark_attendance'),
]