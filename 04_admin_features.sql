SET search_path TO sms;

-- Indexes for join and filter optimization
CREATE INDEX idx_students_program_id ON students(program_id);
CREATE INDEX idx_enrollments_student_offering ON enrollments(student_id, offering_id);
CREATE INDEX idx_course_offerings_course_term ON course_offerings(course_id, semester, academic_year);
CREATE INDEX idx_attendance_sessions_offering_date ON attendance_sessions(offering_id, session_date);
CREATE INDEX idx_attendance_records_student_session ON attendance_records(student_id, session_id);
CREATE INDEX idx_assessment_scores_student_assessment ON assessment_scores(student_id, assessment_id);
CREATE INDEX idx_fee_invoices_student_status ON fee_invoices(student_id, invoice_status);
CREATE INDEX idx_payments_invoice_date ON payments(invoice_id, payment_date);

-- Sample EXPLAIN queries for optimization discussion
EXPLAIN ANALYZE
SELECT
    s.university_roll_no,
    c.course_code,
    e.enrollment_status
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
JOIN course_offerings co ON co.offering_id = e.offering_id
JOIN courses c ON c.course_id = co.course_id
WHERE s.university_roll_no = '22CSE001';

EXPLAIN ANALYZE
SELECT
    ar.student_id,
    ats.offering_id,
    COUNT(*) FILTER (WHERE ar.attendance_status IN ('PRESENT', 'LATE')) AS present_count
FROM attendance_records ar
JOIN attendance_sessions ats ON ats.session_id = ar.session_id
WHERE ats.session_date BETWEEN '2025-08-01' AND '2025-08-31'
GROUP BY ar.student_id, ats.offering_id;

-- Transaction 1: course enrollment with capacity check
BEGIN;

DO $$
DECLARE
    v_offering_id INTEGER := 2;
    v_student_id  BIGINT := 3;
    v_capacity    INTEGER;
    v_enrolled    INTEGER;
BEGIN
    SELECT capacity INTO v_capacity
    FROM course_offerings
    WHERE offering_id = v_offering_id
    FOR UPDATE;

    SELECT COUNT(*) INTO v_enrolled
    FROM enrollments
    WHERE offering_id = v_offering_id
      AND enrollment_status = 'ENROLLED';

    IF v_enrolled < v_capacity THEN
        INSERT INTO enrollments (student_id, offering_id, enrolled_on, enrollment_status, final_grade)
        VALUES (v_student_id, v_offering_id, CURRENT_DATE, 'ENROLLED', NULL)
        ON CONFLICT (student_id, offering_id) DO NOTHING;
    ELSE
        RAISE EXCEPTION 'Enrollment blocked: offering % is full', v_offering_id;
    END IF;
END $$;

COMMIT;

-- Transaction 2: rollback demo for invalid payment amount
BEGIN;

INSERT INTO payments (invoice_id, payment_date, amount, payment_mode, reference_no)
VALUES (3, CURRENT_DATE, 10000, 'UPI', 'PAY-ARJUN-ROLLBACK');

ROLLBACK;

-- Security setup example
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sms_admin') THEN
        CREATE ROLE sms_admin LOGIN PASSWORD 'change_me_admin';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sms_faculty') THEN
        CREATE ROLE sms_faculty LOGIN PASSWORD 'change_me_faculty';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sms_student') THEN
        CREATE ROLE sms_student LOGIN PASSWORD 'change_me_student';
    END IF;
END $$;

GRANT USAGE ON SCHEMA sms TO sms_admin, sms_faculty, sms_student;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA sms TO sms_admin;
GRANT SELECT, INSERT, UPDATE ON sms.attendance_records, sms.assessment_scores TO sms_faculty;
GRANT SELECT ON sms.students, sms.enrollments, sms.fee_invoices, sms.payments, sms.vw_student_academic_summary, sms.vw_course_attendance_summary
TO sms_student;


-- Security note:
-- Replace demo passwords immediately. In production, credentials should be managed
-- outside SQL scripts and password hashes should be generated in the application layer.
