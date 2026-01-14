DROP FUNCTION get_student_grade_entries;

CREATE OR REPLACE FUNCTION get_student_grade_entries(
    p_student_id INT,
    p_start_date TIMESTAMP WITHOUT TIME ZONE DEFAULT (CURRENT_DATE - INTERVAL '30 days')::TIMESTAMP WITHOUT TIME ZONE,
    p_end_date TIMESTAMP WITHOUT TIME ZONE DEFAULT (CURRENT_DATE + INTERVAL '7 days')::TIMESTAMP WITHOUT TIME ZONE --just in case
)
RETURNS TABLE (
    lesson_id INT,
    lesson_date TIMESTAMP WITHOUT TIME ZONE,
    subject_name TEXT,
	journal_id INT,
    data_id INT,
    mark SMALLINT,
    status TEXT,
	note TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT
	l.lesson_id,
        l.lesson_date,
        s.subject_name,
		sd.journal_id,
		sd.data_id,
        sd.mark,
        sd.status,
		sd.note
    FROM StudentData sd
    JOIN Lessons l ON sd.lesson = l.lesson_id
    JOIN Subjects s ON l.lesson_subject = s.subject_id
    WHERE sd.student_id = p_student_id
      AND l.lesson_date BETWEEN p_start_date AND p_end_date
	  AND sd.mark IS NOT NULL
    ORDER BY l.lesson_date DESC, s.subject_name;
$$;