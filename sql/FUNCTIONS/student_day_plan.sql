CREATE OR REPLACE FUNCTION student_day_plan(
    p_student_id INT,
    p_date DATE
)
RETURNS TABLE(lesson VARCHAR, mark SMALLINT, homework TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
	SELECT l.lesson_name, sd.mark, h.homework_desc
	FROM Students s
	JOIN Lessons l ON l.lesson_class = s.student_class
	LEFT JOIN StudentData sd ON sd.student_id = s.student_id
	LEFT JOIN Homework h ON h.homework_class = s.student_class
	WHERE s.student_id = p_student_id
	AND l.lesson_date = p_date;
$$;
