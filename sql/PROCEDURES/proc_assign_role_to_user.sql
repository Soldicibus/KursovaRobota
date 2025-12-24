CREATE OR REPLACE PROCEDURE proc_assign_role_to_user(
    IN p_user_id integer,
    IN p_role_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM roles WHERE role_id = p_role_id
    ) THEN
        RAISE EXCEPTION 'Role % does not exist', p_role_id
        USING ERRCODE = '22003';
    END IF;

    IF EXISTS (
        SELECT 1 FROM userrole
        WHERE user_id = p_user_id AND role_id = p_role_id
    ) THEN
        RAISE EXCEPTION 'User % already has role %', p_user_id, p_role_id
        USING ERRCODE = '23505';
    END IF;

    INSERT INTO userrole (user_id, role_id)
    VALUES (p_user_id, p_role_id);
END;
$$;