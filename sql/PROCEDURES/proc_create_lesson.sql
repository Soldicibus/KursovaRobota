CREATE OR REPLACE PROCEDURE proc_create_lesson(
    IN p_name varchar(50),
    IN p_class varchar(10),
    IN p_subject integer,
    IN p_material integer,
    IN p_teacher integer,
    IN p_date TIMESTAMP WITHOUT TIME ZONE,
    OUT new_lesson_id integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_classes WHERE class_name = p_class) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM vws_subjects WHERE subject_id = p_subject) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject
        USING ERRCODE = '22003';
    END IF;

    IF p_material IS NOT NULL AND NOT EXISTS (SELECT 1 FROM vws_materials WHERE material_id = p_material) THEN
        RAISE EXCEPTION 'Material % does not exist', p_material
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM vws_teachers WHERE teacher_id = p_teacher) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '22003';
    END IF;

    INSERT INTO Lessons(lesson_name, lesson_class, lesson_subject, lesson_material, lesson_teacher, lesson_date)
    VALUES (p_name, p_class, p_subject, p_material, p_teacher, COALESCE(p_date, CURRENT_DATE))
    RETURNING lesson_id INTO new_lesson_id;

    CALL proc_create_audit_log('Lessons', 'INSERT', new_lesson_id::text, 'Created lesson');
END;
$$;
