CREATE OR REPLACE FUNCTION get_homework_by_duedate(
	p_class character varying,
	p_date date)
    RETURNS TABLE(homework_name character varying, teacher_name character varying, teacher_surname character varying, lesson_name character varying, homework_duedate date, homework_created_at date, homework_desc text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.homework_name,
        t.teacher_name,
        t.teacher_surname,
        l.lesson_name,
        h.homework_duedate,
		h.homework_created_at,
        h.homework_desc
    FROM Homework h
	JOIN Lessons l ON h.homework_lesson = l.lesson_id
    JOIN Teacher t ON h.homework_teacher = t.teacher_id
	WHERE homework_class = p_class
	AND homework_duedate = p_date;
END;
$$;

CREATE OR REPLACE FUNCTION get_homework_by_createdate(
	p_class character varying,
	p_date date)
    RETURNS TABLE(homework_name character varying, teacher_name character varying, teacher_surname character varying, lesson_name character varying, homework_duedate date, homework_created_at date, homework_desc text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.homework_name,
        t.teacher_name,
        t.teacher_surname,
        l.lesson_name,
        h.homework_duedate,
		h.homework_created_at,
        h.homework_desc
    FROM Homework h
    JOIN Lessons l ON h.homework_lesson = l.lesson_id
    JOIN Teacher t ON h.homework_teacher = t.teacher_id
    WHERE h.homework_class = p_class
      AND h.homework_created_at = p_date
    ORDER BY l.lesson_date;
END;
$$;



CREATE OR REPLACE FUNCTION student_attendance_report(
    p_student_id INT,
    p_from DATE DEFAULT CURRENT_DATE,
    p_to DATE DEFAULT (CURRENT_DATE + INTERVAL '7 days')::DATE
)
RETURNS TABLE (
    present INT,
    absent INT,
    present_percent NUMERIC(5,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    total INT;
BEGIN
    SELECT COUNT(*)::INT
    INTO total
    FROM StudentData sd
    JOIN Lessons l ON l.lesson_id = sd.lesson
    WHERE sd.student_id = p_student_id
      AND l.lesson_date BETWEEN p_from AND p_to;

    IF total = 0 THEN
        RETURN QUERY SELECT 0, 0, (0)::numeric;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE sd.status IN ('П','Присутній'))::INT,
        COUNT(*) FILTER (WHERE sd.status IN ('Н','Не присутній'))::INT,
        ROUND(
            (COUNT(*) FILTER (WHERE sd.status IN ('П','Присутній'))::NUMERIC / total) * 100,
            2
        )
    FROM StudentData sd
    JOIN Lessons l ON l.lesson_id = sd.lesson
    WHERE sd.student_id = p_student_id
      AND l.lesson_date BETWEEN p_from AND p_to;
END;
$$;

CREATE OR REPLACE FUNCTION student_day_plan(
    p_student_id INT,
    p_date DATE
)
RETURNS TABLE(lesson VARCHAR, mark SMALLINT, homework TEXT)
LANGUAGE sql
AS $$
	SELECT l.lesson_name, sd.mark, h.homework_desc
	FROM Students s
	JOIN Lessons l ON l.lesson_class = s.student_class
	LEFT JOIN StudentData sd ON sd.student_id = s.student_id
	LEFT JOIN Homework h ON h.homework_class = s.student_class
	WHERE s.student_id = p_student_id
	AND l.lesson_date = p_date;
$$;

CREATE OR REPLACE FUNCTION get_children_by_parent(
    p_parent_id INT
)
RETURNS TABLE(student_name VARCHAR)
LANGUAGE sql
AS $$
	SELECT s.student_name
	FROM StudentParent sp
	JOIN Students s ON sp.student_id_ref = s.student_id
	WHERE sp.parent_id_ref = p_parent_id;
$$;

CREATE OR REPLACE FUNCTION get_user_role(
    p_user_id INT
)
RETURNS TABLE(role_name VARCHAR)
LANGUAGE sql
AS $$
	SELECT r.role_name
	FROM UserRole ur
	JOIN Roles r ON ur.role_id = r.role_id
	WHERE ur.user_id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION absents_more_than_x(
    p_class VARCHAR,
    p_x INT
)
RETURNS TABLE(student_id INT, student_name VARCHAR, student_surname VARCHAR, absents INT)
LANGUAGE sql
AS $$
	SELECT s.student_id, s.student_name, s.student_surname, COUNT(*)
	FROM Students s
	JOIN StudentData sd ON s.student_id = sd.student_id
	WHERE s.student_class = p_class
	AND sd.status IN ('Н','Не присутній')
	GROUP BY s.student_id
	HAVING COUNT(*) > p_x;
$$;