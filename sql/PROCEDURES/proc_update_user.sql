CREATE OR REPLACE PROCEDURE proc_update_user(
    IN p_id integer,
    IN p_username varchar(50) DEFAULT NULL,
    IN p_email varchar(60) DEFAULT NULL,
    IN p_password varchar(50) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM users WHERE user_id = p_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_id
        USING ERRCODE = 'P0002';
    END IF;

    p_username := NULLIF(trim(p_username), '');
    p_email := NULLIF(trim(p_email), '');
    p_password := NULLIF(trim(p_password), '');

    IF p_username IS NOT NULL AND EXISTS (
        SELECT 1 FROM users WHERE username = p_username AND user_id <> p_id
    ) THEN
        RAISE EXCEPTION 'Username % already exists', p_username
        USING ERRCODE = '23505';
    END IF;

    IF p_email IS NOT NULL AND EXISTS (
        SELECT 1 FROM users WHERE email = p_email AND user_id <> p_id
    ) THEN
        RAISE EXCEPTION 'Email % already exists', p_email
        USING ERRCODE = '23505';
    END IF;

    IF p_password IS NOT NULL THEN
	    p_password := crypt(p_password, gen_salt('bf'));
	END IF;

    UPDATE users
    SET
        username = COALESCE(p_username, username),
        email    = COALESCE(p_email, email),
        password = COALESCE(p_password, password)
    WHERE user_id = p_id;
END;
$$;
