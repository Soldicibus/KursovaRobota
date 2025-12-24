CREATE OR REPLACE PROCEDURE proc_create_teacher(
    IN p_name varchar(50),
    IN p_surname varchar(50),
    IN p_patronym varchar(50),
    IN p_phone varchar(20),
    IN p_user_id integer,
    OUT new_teacher_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_name IS NULL OR p_surname IS NULL OR p_phone IS NULL THEN
        RAISE EXCEPTION 'Required teacher fields cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    INSERT INTO teacher (
        teacher_name,
        teacher_surname,
        teacher_patronym,
        teacher_phone,
        teacher_user_id
    )
    VALUES (
        p_name,
        p_surname,
        p_patronym,
        p_phone,
        p_user_id
    )
    RETURNING teacher_id INTO new_teacher_id;
END;
$$;