from django.contrib import admin
from .models import Student, Attendance, ClassRoom, Enrollment, Teacher

admin.site.register(Student)
admin.site.register(Attendance)
admin.site.register(ClassRoom)
admin.site.register(Enrollment)


# This makes it look nice and easy to approve people on your laptop
@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    list_display = ('name', 'email', 'is_approved')
    list_filter = ('is_approved',) # Adds a filter sidebar to quickly find pending teachers
    search_fields = ('name', 'email')