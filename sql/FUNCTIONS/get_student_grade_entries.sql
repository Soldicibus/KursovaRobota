CREATE OR REPLACE FUNCTION get_student_grade_entries(
    p_student_id INT,
    p_start_date DATE DEFAULT (CURRENT_DATE - INTERVAL '2 days')::DATE,
    p_end_date DATE DEFAULT (CURRENT_DATE + INTERVAL '7 days')::DATE
)
RETURNS TABLE (
    lesson_id INT,
    lesson_date DATE,
    subject_name TEXT,
    data_id INT,
    mark SMALLINT,
    status TEXT
)
LANGUAGE sql
AS $$
    SELECT
	l.lesson_id,
        l.lesson_date,
        s.subject_name,
	s.data_id,
        sd.mark,
        sd.status
    FROM StudentData sd
    JOIN Lessons l ON sd.lesson = l.lesson_id
    JOIN Subjects s ON l.lesson_subject = s.subject_id
    WHERE sd.student_id = p_student_id
      AND l.lesson_date BETWEEN p_start_date AND p_end_date
	  AND sd.mark IS NOT NULL
    ORDER BY l.lesson_date DESC, s.subject_name;
$$;