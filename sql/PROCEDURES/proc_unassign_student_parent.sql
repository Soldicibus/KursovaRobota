CREATE OR REPLACE PROCEDURE proc_unassign_student_parent(
    IN p_student_id integer,
    IN p_parent_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM studentparent
        WHERE student_id = p_student_id AND parent_id = p_parent_id
    ) THEN
        RAISE EXCEPTION 'No assignment exists between student % and parent %', p_student_id, p_parent_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM studentparent
    WHERE student_id = p_student_id AND parent_id = p_parent_id;
END;
$$;
