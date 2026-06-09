from django.db import models

class Student(models.Model):
    name = models.CharField(max_length=100)
    rollNo = models.CharField(max_length=50, unique=True)
    
    # CHANGED: ImageField is now FileField to accept .mp4 videos
    face_video = models.FileField(upload_to='student_videos/') 

# NEW: This will store the 128-number mathematical face blueprint
    face_encoding = models.JSONField(null=True, blank=True)
    password = models.CharField(max_length=50, default="123456")
    
    def __str__(self):
        return f"{self.name} - {self.rollNo}"

class Teacher(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=50) # In production, use hashed passwords!

# NEW: The Admin Approval Switch! Default is False so they can't log in immediately.
    is_approved = models.BooleanField(default=False)

    def __str__(self):
        status = "✅ Approved" if self.is_approved else "❌ Pending"
        return f"{self.name} ({status})"

        
class ClassRoom(models.Model):
    """The actual class created by the teacher"""
    name = models.CharField(max_length=100) # e.g., "Physics 101"
    course_code = models.CharField(max_length=20) # e.g., "PS101"
    join_code = models.CharField(max_length=15, unique=True) # The secret WhatsApp code e.g., "X7B9Q"
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, null=True, blank=True)
    def __str__(self):
        return f"{self.course_code} - {self.name}"

class Enrollment(models.Model):
    """The bridge connecting a Student to a ClassRoom"""
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    classroom = models.ForeignKey(ClassRoom, on_delete=models.CASCADE)
    
    # This is the magic switch! False = Pending Request. True = Officially Enrolled.
    is_approved = models.BooleanField(default=False) 
    
    # When did they request to join?
    request_date = models.DateTimeField(auto_now_add=True) 

    class Meta:
        # A student can only send ONE request per class
        unique_together = ('student', 'classroom')

    def __str__(self):
        status = "Approved" if self.is_approved else "Pending"
        return f"{self.student.name} -> {self.classroom.course_code} ({status})"

"""class Student(models.Model):
    name = models.CharField(max_length=100)
    rollNo = models.CharField(max_length=50, unique=True)
    image = models.ImageField(upload_to='post_images/')

    # This is the "return function" (Dunder Str)
    def __str__(self):
        return f"{self.name} - {self.rollNo}"""
class ClassSession(models.Model):
    subject_name = models.CharField(max_length=100)
    class_code = models.CharField(max_length=6, unique=True) # e.g. "X9D2A1"
    teacher_name = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.subject_name} ({self.class_code})"

"""class Attendance(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    session = models.ForeignKey(ClassSession, on_delete=models.CASCADE)
    date = models.DateField(auto_now_add=True)
    time = models.TimeField(auto_now_add=True)
    is_present = models.BooleanField(default=True)"""
class Attendance(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    date = models.DateField(auto_now_add=True)  # Automatically grabs today's date
    time = models.TimeField(auto_now_add=True)  # Automatically grabs the exact time
    classroom = models.ForeignKey(ClassRoom, on_delete=models.CASCADE, null=True)
    status = models.CharField(max_length=20, default="Present")

    class Meta:
        # This prevents a student from being marked present twice on the same day!
        unique_together = ('student','classroom', 'date') 

    def __str__(self):
        return f"{self.student.name} - {self.date} - {self.status}"
