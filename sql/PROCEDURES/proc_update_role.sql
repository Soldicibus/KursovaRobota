CREATE OR REPLACE PROCEDURE proc_update_role(
    IN p_role_id INT,
    IN p_role_name VARCHAR(10),
    IN p_role_desc TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_id = p_role_id) THEN
        RAISE EXCEPTION 'Role with ID % does not exist', p_role_id;
    END IF;

    UPDATE Roles
    SET role_name = COALESCE(p_role_name, role_name),
        role_desc = NULLIF(TRIM(p_role_desc), '')
    WHERE role_id = p_role_id;

    CALL proc_create_audit_log('Roles', 'UPDATE', p_role_id::TEXT, 'Updated role ' || p_role_id);
END;
$$;
