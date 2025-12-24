CREATE OR REPLACE PROCEDURE proc_update_teacher(
    IN p_id integer,
    IN p_name varchar(50),
    IN p_surname varchar(50),
    IN p_patronym varchar(50),
    IN p_phone varchar(20),
    IN p_user_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM teacher WHERE teacher_id = p_id
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    UPDATE teacher
    SET
        teacher_name     = COALESCE(p_name, teacher_name),
        teacher_surname  = COALESCE(p_surname, teacher_surname),
        teacher_patronym = COALESCE(p_patronym, teacher_patronym),
        teacher_phone    = COALESCE(p_phone, teacher_phone),
        teacher_user_id  = COALESCE(p_user_id, teacher_user_id)
    WHERE teacher_id = p_id;
END;
$$;
