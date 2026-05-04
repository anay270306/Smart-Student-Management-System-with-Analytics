DROP SCHEMA IF EXISTS sms CASCADE;
CREATE SCHEMA sms;
SET search_path TO sms;

CREATE TABLE departments (
    dept_id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_code            VARCHAR(10) NOT NULL UNIQUE,
    dept_name            VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE programs (
    program_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_id              INTEGER NOT NULL REFERENCES departments(dept_id) ON DELETE RESTRICT,
    program_code         VARCHAR(15) NOT NULL UNIQUE,
    program_name         VARCHAR(120) NOT NULL,
    degree_level         VARCHAR(20) NOT NULL CHECK (degree_level IN ('UNDERGRAD', 'POSTGRAD', 'DOCTORAL')),
    duration_semesters   INTEGER NOT NULL CHECK (duration_semesters BETWEEN 2 AND 12),
    UNIQUE (dept_id, program_name)
);

CREATE TABLE students (
    student_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    university_roll_no   VARCHAR(20) NOT NULL UNIQUE,
    program_id           INTEGER NOT NULL REFERENCES programs(program_id) ON DELETE RESTRICT,
    first_name           VARCHAR(50) NOT NULL,
    last_name            VARCHAR(50) NOT NULL,
    gender               VARCHAR(10) NOT NULL CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    dob                  DATE NOT NULL,
    email                VARCHAR(120) NOT NULL UNIQUE,
    phone                VARCHAR(15) NOT NULL UNIQUE,
    admission_year       INTEGER NOT NULL CHECK (admission_year BETWEEN 2020 AND 2035),
    current_semester     INTEGER NOT NULL CHECK (current_semester BETWEEN 1 AND 12),
    status               VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'GRADUATED', 'SUSPENDED', 'DROPPED'))
);

CREATE TABLE instructors (
    instructor_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_id              INTEGER NOT NULL REFERENCES departments(dept_id) ON DELETE RESTRICT,
    emp_no               VARCHAR(20) NOT NULL UNIQUE,
    first_name           VARCHAR(50) NOT NULL,
    last_name            VARCHAR(50) NOT NULL,
    email                VARCHAR(120) NOT NULL UNIQUE,
    designation          VARCHAR(50) NOT NULL
);

CREATE TABLE courses (
    course_id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_id              INTEGER NOT NULL REFERENCES departments(dept_id) ON DELETE RESTRICT,
    course_code          VARCHAR(15) NOT NULL UNIQUE,
    course_title         VARCHAR(120) NOT NULL,
    credits              INTEGER NOT NULL CHECK (credits BETWEEN 1 AND 6)
);

CREATE TABLE course_offerings (
    offering_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id            INTEGER NOT NULL REFERENCES courses(course_id) ON DELETE RESTRICT,
    instructor_id        INTEGER NOT NULL REFERENCES instructors(instructor_id) ON DELETE RESTRICT,
    semester             VARCHAR(10) NOT NULL CHECK (semester IN ('ODD', 'EVEN', 'SUMMER')),
    academic_year        INTEGER NOT NULL CHECK (academic_year BETWEEN 2020 AND 2035),
    section              VARCHAR(10) NOT NULL,
    capacity             INTEGER NOT NULL CHECK (capacity > 0),
    room_no              VARCHAR(20) NOT NULL,
    schedule_slot        VARCHAR(40) NOT NULL,
    UNIQUE (course_id, semester, academic_year, section)
);

CREATE TABLE enrollments (
    enrollment_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id           BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    offering_id          INTEGER NOT NULL REFERENCES course_offerings(offering_id) ON DELETE CASCADE,
    enrolled_on          DATE NOT NULL DEFAULT CURRENT_DATE,
    enrollment_status    VARCHAR(20) NOT NULL DEFAULT 'ENROLLED' CHECK (enrollment_status IN ('ENROLLED', 'DROPPED', 'WAITLISTED', 'COMPLETED')),
    final_grade          VARCHAR(2),
    UNIQUE (student_id, offering_id)
);

CREATE TABLE attendance_sessions (
    session_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offering_id          INTEGER NOT NULL REFERENCES course_offerings(offering_id) ON DELETE CASCADE,
    session_date         DATE NOT NULL,
    start_time           TIME NOT NULL,
    end_time             TIME NOT NULL,
    session_topic        VARCHAR(150) NOT NULL,
    sensor_device_id     VARCHAR(30) NOT NULL,
    CHECK (end_time > start_time),
    UNIQUE (offering_id, session_date, start_time)
);

CREATE TABLE attendance_records (
    attendance_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id           INTEGER NOT NULL REFERENCES attendance_sessions(session_id) ON DELETE CASCADE,
    student_id           BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    check_in_ts          TIMESTAMP,
    attendance_status    VARCHAR(10) NOT NULL CHECK (attendance_status IN ('PRESENT', 'ABSENT', 'LATE')),
    source_type          VARCHAR(20) NOT NULL CHECK (source_type IN ('MANUAL', 'RFID', 'BLE', 'FACE_RECOGNITION')),
    confidence_score     NUMERIC(5,2) CHECK (confidence_score BETWEEN 0 AND 100),
    UNIQUE (session_id, student_id)
);

CREATE TABLE assessments (
    assessment_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offering_id          INTEGER NOT NULL REFERENCES course_offerings(offering_id) ON DELETE CASCADE,
    assessment_name      VARCHAR(80) NOT NULL,
    assessment_type      VARCHAR(20) NOT NULL CHECK (assessment_type IN ('QUIZ', 'ASSIGNMENT', 'MIDTERM', 'ENDTERM', 'LAB', 'PROJECT')),
    max_marks            NUMERIC(6,2) NOT NULL CHECK (max_marks > 0),
    weightage            NUMERIC(5,2) NOT NULL CHECK (weightage > 0 AND weightage <= 100),
    due_date             DATE NOT NULL,
    UNIQUE (offering_id, assessment_name)
);

CREATE TABLE assessment_scores (
    score_id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    assessment_id        INTEGER NOT NULL REFERENCES assessments(assessment_id) ON DELETE CASCADE,
    student_id           BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    marks_obtained       NUMERIC(6,2) NOT NULL CHECK (marks_obtained >= 0),
    submitted_at         TIMESTAMP,
    feedback             VARCHAR(250),
    UNIQUE (assessment_id, student_id)
);

CREATE TABLE fee_invoices (
    invoice_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id           BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    term_label           VARCHAR(20) NOT NULL,
    amount_due           NUMERIC(12,2) NOT NULL CHECK (amount_due > 0),
    amount_paid          NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    due_date             DATE NOT NULL,
    invoice_status       VARCHAR(15) NOT NULL DEFAULT 'UNPAID' CHECK (invoice_status IN ('UNPAID', 'PARTIAL', 'PAID', 'OVERDUE')),
    UNIQUE (student_id, term_label)
);

CREATE TABLE payments (
    payment_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id           INTEGER NOT NULL REFERENCES fee_invoices(invoice_id) ON DELETE CASCADE,
    payment_date         DATE NOT NULL,
    amount               NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_mode         VARCHAR(20) NOT NULL CHECK (payment_mode IN ('UPI', 'CARD', 'NETBANKING', 'CASH', 'SCHOLARSHIP')),
    reference_no         VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE app_users (
    user_id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username             VARCHAR(40) NOT NULL UNIQUE,
    password_hash        VARCHAR(255) NOT NULL,
    user_type            VARCHAR(20) NOT NULL CHECK (user_type IN ('ADMIN', 'FACULTY', 'STUDENT', 'FINANCE')),
    linked_student_id    BIGINT UNIQUE REFERENCES students(student_id) ON DELETE CASCADE,
    linked_instructor_id INTEGER UNIQUE REFERENCES instructors(instructor_id) ON DELETE CASCADE,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (
        (linked_student_id IS NOT NULL AND linked_instructor_id IS NULL)
        OR (linked_student_id IS NULL AND linked_instructor_id IS NOT NULL)
        OR (linked_student_id IS NULL AND linked_instructor_id IS NULL)
    )
);

CREATE TABLE roles (
    role_id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name            VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE user_roles (
    user_id              INTEGER NOT NULL REFERENCES app_users(user_id) ON DELETE CASCADE,
    role_id              INTEGER NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE OR REPLACE FUNCTION sync_invoice_status(p_invoice_id INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_due NUMERIC(12,2);
    v_paid NUMERIC(12,2);
BEGIN
    SELECT amount_due, amount_paid
      INTO v_due, v_paid
      FROM fee_invoices
     WHERE invoice_id = p_invoice_id;

    UPDATE fee_invoices
       SET invoice_status =
           CASE
               WHEN v_paid <= 0 THEN 'UNPAID'
               WHEN v_paid < v_due THEN 'PARTIAL'
               ELSE 'PAID'
           END
     WHERE invoice_id = p_invoice_id;
END;
$$;

CREATE OR REPLACE FUNCTION trg_apply_payment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE fee_invoices
       SET amount_paid = amount_paid + NEW.amount
     WHERE invoice_id = NEW.invoice_id;

    PERFORM sync_invoice_status(NEW.invoice_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER after_payment_insert
AFTER INSERT ON payments
FOR EACH ROW
EXECUTE FUNCTION trg_apply_payment();
