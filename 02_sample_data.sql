SET search_path TO sms;

INSERT INTO departments (dept_code, dept_name) VALUES
('CSE', 'Computer Science and Engineering'),
('ECE', 'Electronics and Communication Engineering'),
('MGT', 'Management Studies');

INSERT INTO programs (dept_id, program_code, program_name, degree_level, duration_semesters) VALUES
(1, 'BTECH-CSE', 'B.Tech Computer Science and Engineering', 'UNDERGRAD', 8),
(2, 'BTECH-ECE', 'B.Tech Electronics and Communication Engineering', 'UNDERGRAD', 8),
(3, 'MBA', 'Master of Business Administration', 'POSTGRAD', 4);

INSERT INTO students (
    university_roll_no, program_id, first_name, last_name, gender, dob, email, phone,
    admission_year, current_semester, status
) VALUES
('22CSE001', 1, 'Aisha', 'Sharma', 'FEMALE', '2004-01-12', 'aisha.sharma@univ.edu', '9000000001', 2022, 6, 'ACTIVE'),
('22CSE002', 1, 'Rohan', 'Mehta', 'MALE', '2003-11-22', 'rohan.mehta@univ.edu', '9000000002', 2022, 6, 'ACTIVE'),
('22CSE003', 1, 'Arjun', 'Rao', 'MALE', '2004-06-18', 'arjun.rao@univ.edu', '9000000003', 2022, 6, 'ACTIVE'),
('22ECE001', 2, 'Neha', 'Verma', 'FEMALE', '2004-03-09', 'neha.verma@univ.edu', '9000000004', 2022, 6, 'ACTIVE');

INSERT INTO instructors (dept_id, emp_no, first_name, last_name, email, designation) VALUES
(1, 'FAC-CSE-101', 'Priya', 'Nair', 'priya.nair@univ.edu', 'Associate Professor'),
(2, 'FAC-ECE-201', 'Vikram', 'Sen', 'vikram.sen@univ.edu', 'Assistant Professor');

INSERT INTO courses (dept_id, course_code, course_title, credits) VALUES
(1, 'CS301', 'Database Management Systems', 4),
(1, 'CS305', 'Data Warehousing and Mining', 3),
(2, 'EC201', 'Digital Communication', 4);

INSERT INTO course_offerings (
    course_id, instructor_id, semester, academic_year, section, capacity, room_no, schedule_slot
) VALUES
(1, 1, 'ODD', 2025, 'A', 60, 'B-201', 'MON-WED 10:00'),
(2, 1, 'ODD', 2025, 'A', 40, 'B-203', 'TUE-THU 12:00'),
(3, 2, 'ODD', 2025, 'A', 50, 'E-101', 'MON-WED 14:00');

INSERT INTO enrollments (student_id, offering_id, enrolled_on, enrollment_status, final_grade) VALUES
(1, 1, '2025-07-15', 'ENROLLED', 'A'),
(2, 1, '2025-07-15', 'ENROLLED', 'A-'),
(3, 1, '2025-07-16', 'ENROLLED', 'B'),
(1, 2, '2025-07-16', 'ENROLLED', 'A'),
(2, 2, '2025-07-16', 'ENROLLED', 'B+'),
(4, 3, '2025-07-17', 'ENROLLED', 'A-');

INSERT INTO attendance_sessions (
    offering_id, session_date, start_time, end_time, session_topic, sensor_device_id
) VALUES
(1, '2025-08-01', '10:00', '11:00', 'Introduction to DBMS', 'RFID-CS301-A'),
(1, '2025-08-03', '10:00', '11:00', 'ER Modeling', 'RFID-CS301-A'),
(3, '2025-08-02', '14:00', '15:00', 'Signal Encoding Basics', 'BLE-EC201-A');

INSERT INTO attendance_records (
    session_id, student_id, check_in_ts, attendance_status, source_type, confidence_score
) VALUES
(1, 1, '2025-08-01 09:58:11', 'PRESENT', 'RFID', 99.20),
(1, 2, '2025-08-01 09:59:44', 'PRESENT', 'RFID', 98.80),
(1, 3, NULL, 'ABSENT', 'MANUAL', NULL),
(2, 1, '2025-08-03 09:57:40', 'PRESENT', 'RFID', 98.90),
(2, 2, '2025-08-03 10:04:10', 'LATE', 'RFID', 97.10),
(2, 3, '2025-08-03 10:01:22', 'PRESENT', 'RFID', 98.10),
(3, 4, '2025-08-02 13:58:22', 'PRESENT', 'BLE', 95.70);

INSERT INTO assessments (
    offering_id, assessment_name, assessment_type, max_marks, weightage, due_date
) VALUES
(1, 'Quiz 1', 'QUIZ', 20, 10, '2025-08-10'),
(1, 'Midterm', 'MIDTERM', 50, 30, '2025-09-15'),
(1, 'Endterm', 'ENDTERM', 100, 60, '2025-11-20'),
(2, 'Assignment 1', 'ASSIGNMENT', 25, 20, '2025-08-20'),
(2, 'Midterm', 'MIDTERM', 50, 30, '2025-09-18'),
(2, 'Endterm', 'ENDTERM', 100, 50, '2025-11-25'),
(3, 'Lab Test', 'LAB', 30, 20, '2025-08-25'),
(3, 'Midterm', 'MIDTERM', 50, 30, '2025-09-20'),
(3, 'Endterm', 'ENDTERM', 100, 50, '2025-11-28');

INSERT INTO assessment_scores (
    assessment_id, student_id, marks_obtained, submitted_at, feedback
) VALUES
(1, 1, 18, '2025-08-10 11:30', 'Strong start'),
(1, 2, 16, '2025-08-10 11:35', 'Good understanding'),
(1, 3, 14, '2025-08-10 11:40', 'Needs revision on keys'),
(2, 1, 43, '2025-09-15 13:00', 'Excellent ER and SQL answers'),
(2, 2, 39, '2025-09-15 13:00', 'Good performance'),
(2, 3, 34, '2025-09-15 13:00', 'Average normalization answers'),
(3, 1, 88, '2025-11-20 16:00', 'Consistent throughout'),
(3, 2, 82, '2025-11-20 16:00', 'Very good'),
(3, 3, 71, '2025-11-20 16:00', 'Fair final performance'),
(4, 1, 22, '2025-08-20 18:00', 'Well researched'),
(4, 2, 19, '2025-08-20 18:05', 'Decent submission'),
(5, 1, 41, '2025-09-18 13:00', 'Good analytical depth'),
(5, 2, 36, '2025-09-18 13:00', 'Needs stronger warehouse design'),
(6, 1, 84, '2025-11-25 16:30', 'High quality end-term answer'),
(6, 2, 76, '2025-11-25 16:30', 'Conceptually sound'),
(7, 4, 24, '2025-08-25 17:00', 'Technically strong'),
(8, 4, 40, '2025-09-20 14:30', 'Good problem solving'),
(9, 4, 79, '2025-11-28 16:15', 'Strong final performance');

INSERT INTO fee_invoices (
    student_id, term_label, amount_due, amount_paid, due_date, invoice_status
) VALUES
(1, '2025-ODD', 45000, 0, '2025-08-05', 'UNPAID'),
(2, '2025-ODD', 45000, 0, '2025-08-05', 'UNPAID'),
(3, '2025-ODD', 45000, 0, '2025-08-05', 'UNPAID'),
(4, '2025-ODD', 43000, 0, '2025-08-05', 'UNPAID');

INSERT INTO payments (invoice_id, payment_date, amount, payment_mode, reference_no) VALUES
(1, '2025-08-01', 25000, 'UPI', 'PAY-AISHA-001'),
(1, '2025-08-04', 20000, 'CARD', 'PAY-AISHA-002'),
(2, '2025-08-03', 25000, 'NETBANKING', 'PAY-ROHAN-001'),
(4, '2025-08-02', 43000, 'SCHOLARSHIP', 'PAY-NEHA-001');

INSERT INTO roles (role_name) VALUES
('admin'),
('faculty'),
('student'),
('finance_officer');

INSERT INTO app_users (username, password_hash, user_type, linked_student_id, linked_instructor_id, is_active) VALUES
('admin01', 'argon2$demo$admin_hash', 'ADMIN', NULL, NULL, TRUE),
('priya.nair', 'argon2$demo$priya_hash', 'FACULTY', NULL, 1, TRUE),
('vikram.sen', 'argon2$demo$vikram_hash', 'FACULTY', NULL, 2, TRUE),
('22cse001', 'argon2$demo$aisha_hash', 'STUDENT', 1, NULL, TRUE),
('22cse002', 'argon2$demo$rohan_hash', 'STUDENT', 2, NULL, TRUE),
('finance01', 'argon2$demo$finance_hash', 'FINANCE', NULL, NULL, TRUE);

INSERT INTO user_roles (user_id, role_id) VALUES
(1, 1),
(2, 2),
(3, 2),
(4, 3),
(5, 3),
(6, 4);
