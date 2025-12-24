CREATE OR REPLACE PROCEDURE proc_create_homework(
    INOUT p_name varchar(100),
    IN p_teacher integer,
    IN p_lesson integer,
    INOUT p_duedate date,
    INOUT p_desc text,
    IN p_class varchar(10),
    OUT new_homework_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_name := NULLIF(trim(p_name), '');
    p_desc := NULLIF(trim(p_desc), '');

    IF p_desc IS NULL THEN
        RAISE EXCEPTION 'Homework description cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM teacher WHERE teacher_id = p_teacher
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM lessons WHERE lesson_id = p_lesson
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM class WHERE class_name = p_class
    ) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '23503';
    END IF;

    IF p_class !~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$' THEN
        RAISE EXCEPTION 'Class "%" does not match format N-Letter (e.g., 7-А)', p_class
        USING ERRCODE = '23514';
    END IF;

    IF p_duedate IS NULL THEN
        RAISE EXCEPTION 'Due date cannot be NULL'
        USING ERRCODE = '23502';
    END IF;

    IF p_duedate < CURRENT_DATE THEN
        RAISE EXCEPTION 'Due date (%) cannot be in the past', p_duedate
        USING ERRCODE = '22007';
    END IF;

    INSERT INTO homework(
        homework_name,
        homework_teacher,
        homework_lesson,
        homework_duedate,
        homework_desc,
        homework_class
    )
    VALUES (
        p_name,
        p_teacher,
        p_lesson,
        p_duedate,
        p_desc,
        p_class
    )
    RETURNING homework_id INTO new_homework_id;
END;
$$;
