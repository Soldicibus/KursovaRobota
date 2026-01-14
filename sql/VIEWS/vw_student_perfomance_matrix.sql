CREATE OR REPLACE VIEW vw_student_performance_matrix AS
WITH 
AcademicStats AS (
    SELECT 
        sd.student_id,
        COUNT(sd.mark) AS count_marks,
        ROUND(AVG(sd.mark), 2) AS avg_grade,
        COUNT(CASE WHEN sd.mark BETWEEN 1 AND 3 THEN 1 END) AS count_failures,
        MAX(l.lesson_date) AS last_graded_date
    FROM StudentData sd
    JOIN Lessons l ON sd.lesson = l.lesson_id
    WHERE sd.mark IS NOT NULL
    GROUP BY sd.student_id
),

AttendanceStats AS (
    SELECT 
        sd.student_id,
        COUNT(*) AS total_entries,
        COUNT(CASE WHEN sd.status IN ('Не присутній', 'Н') THEN 1 END) AS count_absences,
        MAX(l.lesson_date) AS last_seen_date
    FROM StudentData sd
    JOIN Lessons l ON sd.lesson = l.lesson_id
    GROUP BY sd.student_id
)

SELECT 
    s.student_id,
    s.student_name || ' ' || s.student_surname || ' ' || s.student_patronym AS student_full_name,
    s.student_class,
    COALESCE(acad.avg_grade, 0) AS gpa,
    COALESCE(acad.count_marks, 0) AS total_marks_received,
    COALESCE(acad.count_failures, 0) AS total_failed_marks,
    COALESCE(att.count_absences, 0) AS total_absences,
    CASE 
        WHEN COALESCE(att.total_entries, 0) = 0 THEN 0 
        ELSE ROUND((COALESCE(att.count_absences, 0)::DECIMAL / att.total_entries) * 100, 1)
    END AS absence_percentage,
    GREATEST(acad.last_graded_date, att.last_seen_date) AS last_activity_date,
    CASE 
        WHEN GREATEST(acad.last_graded_date, att.last_seen_date) IS NOT NULL 
        THEN (CURRENT_DATE - GREATEST(acad.last_graded_date, att.last_seen_date))
        ELSE NULL 
    END AS days_since_last_activity,
    CASE 
        WHEN (COALESCE(acad.avg_grade, 0) > 0 AND acad.avg_grade < 4) 
             OR (CASE WHEN att.total_entries > 0 THEN (att.count_absences::DECIMAL / att.total_entries) ELSE 0 END > 0.30)
             THEN 'В зоні ризику'
        WHEN acad.avg_grade >= 10 AND COALESCE(att.count_absences, 0) < 3
             THEN 'Відмінник'
        WHEN acad.avg_grade >= 7 
             THEN 'Хорошист'
        WHEN acad.avg_grade IS NULL AND att.total_entries IS NULL
             THEN 'Новий/Без активності'
        ELSE 'Середній рівень'
    END AS student_status_tier

FROM Students s
LEFT JOIN AcademicStats acad ON s.student_id = acad.student_id
LEFT JOIN AttendanceStats att ON s.student_id = att.student_id
ORDER BY 
    student_class, 
    gpa DESC;