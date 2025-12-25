CREATE OR REPLACE PROCEDURE public.proc_update_lesson(
	IN p_lesson_id integer,
	IN p_name character varying DEFAULT NULL::character varying,
	IN p_class character varying DEFAULT NULL::character varying,
	IN p_subject integer DEFAULT NULL::integer,
	IN p_material integer DEFAULT NULL::integer,
	IN p_teacher integer DEFAULT NULL::integer,
	IN p_date date DEFAULT NULL::date)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM lessons WHERE lesson_id = p_lesson_id
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');

    IF p_material = 0 THEN
        p_material := NULL;
    END IF;

    IF p_teacher IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM teacher WHERE teacher_id = p_teacher
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '22003';
    END IF;

    IF p_class IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM class WHERE class_name = p_class
        ) THEN
            RAISE EXCEPTION 'Class % does not exist', p_class
            USING ERRCODE = '22003';
        END IF;

        IF p_class !~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$' THEN
            RAISE EXCEPTION 'Invalid class format: %', p_class
            USING ERRCODE = '23514';
        END IF;
    END IF;

    IF p_subject IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM subjects WHERE subject_id = p_subject
    ) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject
        USING ERRCODE = '22003';
    END IF;

    UPDATE lessons
    SET
        lesson_name     = COALESCE(p_name, lesson_name),
        lesson_class    = COALESCE(p_class, lesson_class),
        lesson_subject  = COALESCE(p_subject, lesson_subject),
        lesson_material = COALESCE(p_material, lesson_material),
        lesson_teacher  = COALESCE(p_teacher, lesson_teacher),
        lesson_date     = COALESCE(p_date, lesson_date)
    WHERE lesson_id = p_lesson_id;
END;
$BODY$;