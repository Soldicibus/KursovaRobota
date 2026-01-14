CREATE OR REPLACE PROCEDURE proc_update_parent(
    IN p_id integer,
    IN p_name varchar(50),
    IN p_surname varchar(50),
    IN p_patronym varchar(50),
    IN p_phone varchar(20),
    IN p_user_id integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_parents WHERE parent_id = p_id
    ) THEN
        RAISE EXCEPTION 'Parent % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    UPDATE parents
    SET
        parent_name      = COALESCE(p_name, parent_name),
        parent_surname   = COALESCE(p_surname, parent_surname),
        parent_patronym  = p_patronym,
        parent_phone     = COALESCE(p_phone, parent_phone),
        parent_user_id   = COALESCE(p_user_id, parent_user_id)
    WHERE parent_id = p_id;

    CALL proc_create_audit_log('Parents', 'UPDATE', p_id::text, 'Updated parent');
END;
$$;