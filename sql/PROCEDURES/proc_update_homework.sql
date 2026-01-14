CREATE OR REPLACE PROCEDURE proc_update_homework(
    IN p_id integer,
    IN p_name varchar(100) DEFAULT NULL,
    IN p_teacher integer DEFAULT NULL,
    IN p_lesson integer DEFAULT NULL,
    IN p_duedate date DEFAULT NULL,
    IN p_desc text DEFAULT NULL,
    IN p_class varchar(10) DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_homeworks WHERE homework_id = p_id
    ) THEN
        RAISE EXCEPTION 'Homework % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_desc := NULLIF(trim(p_desc), '');
    p_class := NULLIF(trim(p_class), '');

    IF p_desc IS NOT NULL AND length(p_desc) = 0 THEN
        RAISE EXCEPTION 'Homework description cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_teacher IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_teachers WHERE teacher_id = p_teacher
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '22003';
    END IF;

    IF p_lesson IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_lessons WHERE lesson_id = p_lesson
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson
        USING ERRCODE = '22003';
    END IF;

    IF p_class IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM vws_classes WHERE class_name = p_class
        ) THEN
            RAISE EXCEPTION 'Class % does not exist', p_class
            USING ERRCODE = '22003';
        END IF;

        IF p_class !~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$' THEN
            RAISE EXCEPTION 'Invalid class format: %', p_class
            USING ERRCODE = '23514';
        END IF;
    END IF;

    IF p_duedate IS NOT NULL AND p_duedate < CURRENT_DATE THEN
        RAISE EXCEPTION 'Due date (%) cannot be in the past', p_duedate
        USING ERRCODE = '22007';
    END IF;

    UPDATE homework
    SET
        homework_name    = p_name,
        homework_teacher = p_teacher,
        homework_lesson  = COALESCE(p_lesson, homework_lesson),
        homework_duedate = COALESCE(p_duedate, homework_duedate),
        homework_desc    = COALESCE(p_desc, homework_desc),
        homework_class   = COALESCE(p_class, homework_class)
    WHERE homework_id = p_id;

    CALL proc_create_audit_log('Homework', 'UPDATE', p_id::text, 'Updated homework');
END;
$$;
