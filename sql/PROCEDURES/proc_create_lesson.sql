CREATE OR REPLACE PROCEDURE public.proc_create_lesson(
	INOUT p_name character varying,
	IN p_class character varying,
	IN p_subject integer,
	INOUT p_material integer,
	IN p_teacher integer,
	INOUT p_date date,
	OUT new_lesson_id integer)
LANGUAGE 'plpgsql'
    SECURITY DEFINER 
AS $BODY$
BEGIN
    p_name := NULLIF(trim(p_name), '');
    p_material := CASE WHEN p_material = 0 THEN NULL ELSE p_material END;

    IF p_material IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM material WHERE material_id = p_material
    ) THEN
        RAISE EXCEPTION 'Material % does not exist', p_material
        USING ERRCODE = '22003';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM teacher WHERE teacher_id = p_teacher
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM class WHERE class_name = p_class
    ) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '22003';
    END IF;

    IF p_class !~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$' THEN
        RAISE EXCEPTION 'Class "%" does not match format N-Letter (e.g., 7-А)', p_class
        USING ERRCODE = '23514';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM subjects WHERE subject_id = p_subject
    ) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject
        USING ERRCODE = '22003';
    END IF;
    
    IF p_date IS NULL THEN
        p_date := CURRENT_DATE;
    END IF;

    INSERT INTO lessons (
        lesson_name,
        lesson_class,
        lesson_subject,
        lesson_material,
        lesson_teacher,
        lesson_date
    )
    VALUES (
        p_name,
        p_class,
        p_subject,
        p_material,
        p_teacher,
        p_date
    )
    RETURNING lesson_id INTO new_lesson_id;
END;
$BODY$;