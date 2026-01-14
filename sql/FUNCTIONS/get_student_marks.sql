CREATE OR REPLACE FUNCTION get_student_marks(
    p_student_id INT,
    p_from DATE DEFAULT CURRENT_DATE - INTERVAL '1 month',
    p_to DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(mark SMALLINT, lesson_date DATE)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
	SELECT sd.mark, l.lesson_date
	FROM StudentData sd
	JOIN Journal j ON sd.journal_id = j.journal_id
	JOIN Lessons l ON j.journal_teacher = l.lesson_teacher
	WHERE sd.mark IS NOT NULL
	AND sd.student_id = p_student_id
	  AND l.lesson_date BETWEEN p_from AND p_to;
$$;