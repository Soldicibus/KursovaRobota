CREATE OR REPLACE PROCEDURE proc_update_student(
    IN p_id integer,
    IN p_name varchar(50),
    IN p_surname varchar(50),
    IN p_patronym varchar(50),
    IN p_phone varchar(20),
    IN p_user_id integer,
    IN p_class varchar(10)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM students WHERE student_id = p_id
    ) THEN
        RAISE EXCEPTION 'Student % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_class IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM class WHERE class_name = p_class
    ) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '22003';
    END IF;

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    UPDATE students
    SET
        student_name       = COALESCE(p_name, student_name),
        student_surname    = COALESCE(p_surname, student_surname),
        student_patronym   = COALESCE(p_patronym, student_patronym),
        student_phone      = COALESCE(p_phone, student_phone),
        student_user_id    = COALESCE(p_user_id, student_user_id),
        student_class      = COALESCE(p_class, student_class)
    WHERE student_id = p_id;
END;
$$;