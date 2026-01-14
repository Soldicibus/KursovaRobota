CREATE OR REPLACE PROCEDURE proc_update_class(
    IN p_class_name VARCHAR(10),
    IN p_class_journal_id INT,
    IN p_class_mainTeacher INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Class WHERE class_name = p_class_name) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class_name;
    END IF;

    UPDATE Class
    SET class_journal_id = p_class_journal_id,
        class_mainTeacher = p_class_mainTeacher
    WHERE class_name = p_class_name;

    CALL proc_create_audit_log('Class', 'UPDATE', p_class_name::TEXT, 'Updated class ' || p_class_name);
END;
$$;
