CREATE OR REPLACE FUNCTION get_student_monthly_grades(
    p_student_id INT,
    p_month TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    data_id INT,
    subject_name TEXT,
    mark SMALLINT,
    status journal_status_enum,
    note TEXT,
    lesson_date TIMESTAMP WITHOUT TIME ZONE,
    lesson_id INT,
    teacher_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sd.data_id,
        sub.subject_name,
        sd.mark,
        sd.status,
        sd.note,
        l.lesson_date,
        l.lesson_id,
        l.lesson_teacher
    FROM StudentData sd
    JOIN Lessons l ON sd.lesson = l.lesson_id
    JOIN Subjects sub ON l.lesson_subject = sub.subject_id
    WHERE sd.student_id = p_student_id
      AND sd.mark IS NOT NULL
      AND EXTRACT(MONTH FROM l.lesson_date) = EXTRACT(MONTH FROM COALESCE(p_month, CURRENT_DATE))
      AND EXTRACT(YEAR FROM l.lesson_date) = EXTRACT(YEAR FROM COALESCE(p_month, CURRENT_DATE))
    ORDER BY l.lesson_date, sub.subject_name;
END;
$$;
