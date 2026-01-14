CREATE OR REPLACE PROCEDURE proc_delete_homework(
    IN p_id integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_homeworks WHERE homework_id = p_id) THEN
        RAISE EXCEPTION 'Homework % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM homework WHERE homework_id = p_id;

    CALL proc_create_audit_log('Homework', 'DELETE', p_id::text, 'Deleted homework');
END;
$$;