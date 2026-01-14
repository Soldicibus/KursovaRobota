CREATE OR REPLACE PROCEDURE proc_delete_subject(
    IN p_subject_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Subjects WHERE subject_id = p_subject_id) THEN
        RAISE EXCEPTION 'Subject with ID % does not exist', p_subject_id;
    END IF;

    DELETE FROM Subjects WHERE subject_id = p_subject_id;

    CALL proc_create_audit_log('Subjects', 'DELETE', p_subject_id::TEXT, 'Deleted subject ' || p_subject_id);
END;
$$;
