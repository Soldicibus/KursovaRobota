CREATE OR REPLACE PROCEDURE proc_create_subject(
    IN p_subject_name TEXT,
    IN p_cabinet INT,
    IN p_subject_program TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO Subjects (subject_name, cabinet, subject_program)
    VALUES (p_subject_name, p_cabinet, p_subject_program);

    CALL proc_create_audit_log('Subjects', 'INSERT', p_subject_name, 'Created subject ' || p_subject_name);
END;
$$;
