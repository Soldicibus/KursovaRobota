CREATE OR REPLACE PROCEDURE proc_unassign_student_parent(
    IN p_student_id integer,
    IN p_parent_id integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_student_parents
        WHERE student_id_ref = p_student_id AND parent_id_ref = p_parent_id
    ) THEN
        RAISE EXCEPTION 'No assignment exists between student % and parent %', p_student_id, p_parent_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM studentparent
    WHERE student_id_ref = p_student_id AND parent_id_ref = p_parent_id;

    CALL proc_create_audit_log('StudentParent', 'DELETE', p_student_id || ',' || p_parent_id, 'Unassigned student from parent');
END;
$$;
