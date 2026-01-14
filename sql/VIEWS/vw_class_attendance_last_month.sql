CREATE OR REPLACE VIEW vw_class_attendance_last_month AS
SELECT
    s.student_class,
    ROUND(
        COUNT(*) FILTER (
            WHERE sd.status IN ('П', 'Присутній')
        )::NUMERIC
        /
        COUNT(*) * 100,
        2
    ) AS attendance_percent
FROM Students s
JOIN StudentData sd
    ON sd.student_id = s.student_id
JOIN Lessons l
    ON l.lesson_id = sd.lesson
WHERE l.lesson_date >= date_trunc('month', CURRENT_DATE - INTERVAL '1 month')
  AND l.lesson_date <  date_trunc('month', CURRENT_DATE)
GROUP BY s.student_class;

CREATE OR REPLACE VIEW vw_homework_by_student_or_class AS
SELECT
    s.student_id,
    s.student_name,
    h.homework_name,
    h.homework_desc,
    h.homework_duedate
FROM Students s
JOIN Homework h
    ON h.homework_class = s.student_class;


