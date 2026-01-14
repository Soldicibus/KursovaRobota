CREATE OR REPLACE PROCEDURE proc_delete_studentdata(
    IN p_id integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_student_data WHERE data_id = p_id) THEN
        RAISE EXCEPTION 'StudentData % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM studentdata WHERE data_id = p_id;

    CALL proc_create_audit_log('StudentData', 'DELETE', p_id::text, 'Deleted student data');
END;
$$;