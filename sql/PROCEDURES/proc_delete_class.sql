CREATE OR REPLACE PROCEDURE proc_delete_class(
    IN p_class_name VARCHAR(10)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Class WHERE class_name = p_class_name) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class_name;
    END IF;

    DELETE FROM Class WHERE class_name = p_class_name;

    CALL proc_create_audit_log('Class', 'DELETE', p_class_name::TEXT, 'Deleted class ' || p_class_name);
END;
$$;
