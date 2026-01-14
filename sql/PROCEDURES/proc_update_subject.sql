CREATE OR REPLACE PROCEDURE proc_update_subject(
    IN p_subject_id INT,
    IN p_subject_name TEXT,
    IN p_cabinet INT,
    IN p_subject_program TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Subjects WHERE subject_id = p_subject_id) THEN
        RAISE EXCEPTION 'Subject with ID % does not exist', p_subject_id;
    END IF;

    UPDATE Subjects
    SET subject_name = COALESCE(p_subject_name, subject_name),
        cabinet = COALESCE(p_cabinet, cabinet),
        subject_program = NULLIF(TRIM(p_subject_program), '')
    WHERE subject_id = p_subject_id;

    CALL proc_create_audit_log('Subjects', 'UPDATE', p_subject_id::TEXT, 'Updated subject ' || p_subject_id);
END;
$$;
