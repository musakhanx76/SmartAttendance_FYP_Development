from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

# 1. Temporarily removed CreateClassView from this import
from api.views import register_student, mark_attendance, delete_student , get_attendance_report, join_class, get_pending_requests, approve_student, get_approved_students, remove_student_from_class, student_login

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # 2. Temporarily comment out this path so Django ignores it
    # path('api/create_class/', CreateClassView.as_view(), name='create_class'),
    
    path('register/', register_student, name='register_student'),
    path('mark_attendance/', mark_attendance, name='mark_attendance'),
    path('delete_student/<path:roll_number>/', delete_student, name='delete_student'),
    path('get_report/<str:date_str>/', get_attendance_report, name='get_attendance_report'),
    # New LMS Paths:
    path('join_class/', join_class, name='join_class'),
    path('pending_requests/', get_pending_requests, name='pending_requests'),
    path('approve_student/<int:enrollment_id>/', approve_student, name='approve_student'),
    path('my_students/', get_approved_students, name='my_students'),
    path('remove_student/<int:enrollment_id>/', remove_student_from_class, name='remove_student'),
    path('student_login/', student_login, name='student_login'),
    
    path('api/', include('api.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)