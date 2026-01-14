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
