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
SECURITY DEFINER
SET search_path = public, pg_temp
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
