CREATE OR REPLACE PROCEDURE proc_create_user(
    IN p_username varchar(50),
    IN p_email varchar(60),
    IN p_password varchar(50),
    OUT new_user_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_username := NULLIF(trim(p_username), '');
    p_email := NULLIF(trim(p_email), '');
    p_password := NULLIF(trim(p_password), '');

    IF p_username IS NULL THEN
        RAISE EXCEPTION 'Username cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_email IS NULL THEN
        RAISE EXCEPTION 'Email cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_password IS NULL THEN
        RAISE EXCEPTION 'Password cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1 FROM users WHERE username = p_username
    ) THEN
        RAISE EXCEPTION 'Username % already exists', p_username
        USING ERRCODE = '23505';
    END IF;

    IF EXISTS (
        SELECT 1 FROM users WHERE email = p_email
    ) THEN
        RAISE EXCEPTION 'Email % already exists', p_email
        USING ERRCODE = '23505';
    END IF;

    INSERT INTO users (username, email, password)
    VALUES (p_username, p_email, p_password)
    RETURNING user_id INTO new_user_id;
END;
$$;