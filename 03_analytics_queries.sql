SET search_path TO sms;

-- 1. INNER JOIN: student, program, course, instructor
SELECT
    s.university_roll_no,
    s.first_name || ' ' || s.last_name AS student_name,
    p.program_code,
    c.course_code,
    c.course_title,
    i.first_name || ' ' || i.last_name AS instructor_name
FROM students s
JOIN programs p ON p.program_id = s.program_id
JOIN enrollments e ON e.student_id = s.student_id
JOIN course_offerings co ON co.offering_id = e.offering_id
JOIN courses c ON c.course_id = co.course_id
JOIN instructors i ON i.instructor_id = co.instructor_id
ORDER BY s.university_roll_no, c.course_code;

-- 2. LEFT JOIN: all students, with payment status even if unpaid
SELECT
    s.university_roll_no,
    s.first_name || ' ' || s.last_name AS student_name,
    fi.term_label,
    fi.amount_due,
    fi.amount_paid,
    (fi.amount_due - fi.amount_paid) AS balance
FROM students s
LEFT JOIN fee_invoices fi ON fi.student_id = s.student_id
ORDER BY s.university_roll_no;

-- 3. RIGHT JOIN: all course offerings, whether enrollments exist or not
SELECT
    c.course_code,
    co.section,
    s.university_roll_no,
    e.enrollment_status
FROM enrollments e
RIGHT JOIN course_offerings co ON co.offering_id = e.offering_id
JOIN courses c ON c.course_id = co.course_id
LEFT JOIN students s ON s.student_id = e.student_id
ORDER BY c.course_code, s.university_roll_no NULLS LAST;

-- 4. FULL JOIN: invoice and payment reconciliation
SELECT
    fi.invoice_id,
    fi.term_label,
    fi.amount_due,
    p.payment_id,
    p.amount AS payment_amount,
    p.payment_date
FROM fee_invoices fi
FULL JOIN payments p ON p.invoice_id = fi.invoice_id
ORDER BY fi.invoice_id, p.payment_date;

-- 5. Subquery: students above course average in DBMS
SELECT
    s.university_roll_no,
    s.first_name || ' ' || s.last_name AS student_name,
    ROUND(AVG((sc.marks_obtained / a.max_marks) * 100), 2) AS avg_percent
FROM students s
JOIN assessment_scores sc ON sc.student_id = s.student_id
JOIN assessments a ON a.assessment_id = sc.assessment_id
WHERE a.offering_id = 1
GROUP BY s.student_id, s.university_roll_no, s.first_name, s.last_name
HAVING AVG((sc.marks_obtained / a.max_marks) * 100) > (
    SELECT AVG((sc2.marks_obtained / a2.max_marks) * 100)
    FROM assessment_scores sc2
    JOIN assessments a2 ON a2.assessment_id = sc2.assessment_id
    WHERE a2.offering_id = 1
);

-- 6. View: weighted academic summary per student per offering
CREATE OR REPLACE VIEW vw_student_academic_summary AS
SELECT
    s.student_id,
    s.university_roll_no,
    s.first_name || ' ' || s.last_name AS student_name,
    c.course_code,
    c.course_title,
    co.offering_id,
    ROUND(SUM((sc.marks_obtained / a.max_marks) * a.weightage), 2) AS weighted_percentage,
    e.final_grade
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
JOIN course_offerings co ON co.offering_id = e.offering_id
JOIN courses c ON c.course_id = co.course_id
LEFT JOIN assessments a ON a.offering_id = co.offering_id
LEFT JOIN assessment_scores sc
       ON sc.assessment_id = a.assessment_id
      AND sc.student_id = s.student_id
GROUP BY
    s.student_id, s.university_roll_no, s.first_name, s.last_name,
    c.course_code, c.course_title, co.offering_id, e.final_grade;

-- 7. View: attendance summary
CREATE OR REPLACE VIEW vw_course_attendance_summary AS
SELECT
    c.course_code,
    s.university_roll_no,
    COUNT(ar.attendance_id) AS sessions_held,
    COUNT(*) FILTER (WHERE ar.attendance_status IN ('PRESENT', 'LATE')) AS sessions_present,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE ar.attendance_status IN ('PRESENT', 'LATE'))
        / NULLIF(COUNT(ar.attendance_id), 0),
        2
    ) AS attendance_pct
FROM attendance_records ar
JOIN attendance_sessions ats ON ats.session_id = ar.session_id
JOIN course_offerings co ON co.offering_id = ats.offering_id
JOIN courses c ON c.course_id = co.course_id
JOIN students s ON s.student_id = ar.student_id
GROUP BY c.course_code, s.university_roll_no;

-- 8. Window function: row number within each course by score
SELECT
    vas.course_code,
    vas.university_roll_no,
    vas.student_name,
    vas.weighted_percentage,
    ROW_NUMBER() OVER (
        PARTITION BY vas.course_code
        ORDER BY vas.weighted_percentage DESC
    ) AS row_num_in_course
FROM vw_student_academic_summary vas
ORDER BY vas.course_code, row_num_in_course;

-- 9. Window function: institution-wide rank
SELECT
    university_roll_no,
    student_name,
    ROUND(AVG(weighted_percentage), 2) AS overall_weighted_percentage,
    RANK() OVER (ORDER BY AVG(weighted_percentage) DESC) AS class_rank
FROM vw_student_academic_summary
GROUP BY university_roll_no, student_name
ORDER BY class_rank, university_roll_no;

-- 10. Correlated subquery: students with attendance below 75 percent in any course
SELECT
    s.university_roll_no,
    s.first_name || ' ' || s.last_name AS student_name,
    c.course_code
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
JOIN course_offerings co ON co.offering_id = e.offering_id
JOIN courses c ON c.course_id = co.course_id
WHERE (
    SELECT ROUND(
        100.0 * COUNT(*) FILTER (WHERE ar.attendance_status IN ('PRESENT', 'LATE'))
        / NULLIF(COUNT(*), 0),
        2
    )
    FROM attendance_records ar
    JOIN attendance_sessions ats ON ats.session_id = ar.session_id
    WHERE ats.offering_id = co.offering_id
      AND ar.student_id = s.student_id
) < 75;

-- 11. Department-wise performance summary
SELECT
    d.dept_code,
    d.dept_name,
    ROUND(AVG(vas.weighted_percentage), 2) AS avg_weighted_percentage
FROM vw_student_academic_summary vas
JOIN students s ON s.student_id = vas.student_id
JOIN programs p ON p.program_id = s.program_id
JOIN departments d ON d.dept_id = p.dept_id
GROUP BY d.dept_code, d.dept_name
ORDER BY avg_weighted_percentage DESC;

-- 12. Fee defaulters
SELECT
    s.university_roll_no,
    s.first_name || ' ' || s.last_name AS student_name,
    fi.term_label,
    fi.amount_due,
    fi.amount_paid,
    (fi.amount_due - fi.amount_paid) AS balance
FROM fee_invoices fi
JOIN students s ON s.student_id = fi.student_id
WHERE fi.amount_paid < fi.amount_due
ORDER BY balance DESC;
