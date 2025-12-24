CREATE OR REPLACE VIEW teachers_with_classes AS
	SELECT t.teacher_name, c.class_name
	FROM Teacher t
	JOIN Class c ON c.class_mainTeacher = t.teacher_id;

CREATE OR REPLACE VIEW students_by_class AS
	SELECT student_name, student_class FROM Students;

CREATE OR REPLACE VIEW homework_tomorrow AS
	SELECT * FROM Homework
	WHERE homework_duedate = CURRENT_DATE + 1;

CREATE OR REPLACE VIEW students_avg_above_7 AS
	SELECT s.student_id, AVG(sd.mark) avg_mark
	FROM Students s
	JOIN StudentData sd ON s.student_id = sd.student_id
	GROUP BY s.student_id
	HAVING AVG(sd.mark) > 7;

CREATE OR REPLACE VIEW vw_teachers_with_classes AS
SELECT
    t.teacher_id,
    t.teacher_name,
    t.teacher_surname,
    c.class_name
FROM Teacher t
JOIN Class c
    ON c.class_mainTeacher = t.teacher_id;

CREATE OR REPLACE VIEW vw_students_by_class AS
SELECT
    student_id,
    student_name,
    student_surname,
    student_class
FROM Students;

CREATE OR REPLACE VIEW vw_homework_tomorrow AS
SELECT
    homework_id,
    homework_name,
    homework_desc,
    homework_class
FROM Homework
WHERE homework_duedate = CURRENT_DATE + INTERVAL '1 day';

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

CREATE OR REPLACE VIEW vw_class_ranking AS
SELECT
    s.student_class,
    COUNT(DISTINCT s.student_id) AS students_count,
    ROUND(AVG(sd.mark)::NUMERIC, 2) AS avg_mark,
    RANK() OVER (
        ORDER BY AVG(sd.mark) DESC
    ) AS rank_position
FROM Students s
JOIN StudentData sd ON sd.student_id = s.student_id
JOIN Lessons l ON l.lesson_id = sd.lesson
WHERE sd.mark IS NOT NULL
  AND l.lesson_date BETWEEN '2025-09-01' AND '2026-06-30'
GROUP BY s.student_class;

CREATE OR REPLACE VIEW vw_student_ranking AS
SELECT
    s.student_id,
    s.student_name,
    s.student_class,
    ROUND(AVG(sd.mark)::NUMERIC, 2) AS avg_mark,
    RANK() OVER (
        PARTITION BY s.student_class
        ORDER BY AVG(sd.mark) DESC
    ) AS class_rank
FROM Students s
JOIN StudentData sd ON sd.student_id = s.student_id
JOIN Lessons l ON l.lesson_id = sd.lesson
WHERE sd.mark IS NOT NULL
  AND l.lesson_date BETWEEN '2025-09-01' AND '2026-06-30'
GROUP BY s.student_id, s.student_name, s.student_class;
