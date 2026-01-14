CREATE OR REPLACE PROCEDURE proc_delete_role(
    IN p_role_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_id = p_role_id) THEN
        RAISE EXCEPTION 'Role with ID % does not exist', p_role_id;
    END IF;

    DELETE FROM Roles WHERE role_id = p_role_id;

    CALL proc_create_audit_log('Roles', 'DELETE', p_role_id::TEXT, 'Deleted role ' || p_role_id);
END;
$$;
