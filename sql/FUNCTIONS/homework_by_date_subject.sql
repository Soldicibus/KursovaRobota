CREATE OR REPLACE FUNCTION homework_by_date_subject(
    p_date DATE,
    p_subject INT DEFAULT NULL
)
RETURNS TABLE(homework TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
	SELECT h.homework_desc
	FROM Homework h
	JOIN Lessons l ON h.homework_lesson = l.lesson_id
	WHERE h.homework_duedate = p_date
	AND (p_subject IS NULL OR l.lesson_subject = p_subject);
$$;
