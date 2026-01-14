CREATE OR REPLACE FUNCTION get_teacher_salary(
    p_teacher_id INT,
    p_from DATE DEFAULT CURRENT_DATE - INTERVAL '1 month',
    p_to DATE DEFAULT CURRENT_DATE
)
RETURNS NUMERIC
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
SELECT COUNT(*) * 550
	FROM Lessons
	WHERE lesson_teacher = p_teacher_id
	AND lesson_date BETWEEN p_from AND p_to;
$$;