CREATE OR REPLACE PROCEDURE proc_assign_student_parent(
    IN p_student_id integer,
    IN p_parent_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM students WHERE student_id = p_student_id) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM parents WHERE parent_id = p_parent_id) THEN
        RAISE EXCEPTION 'Parent % does not exist', p_parent_id
        USING ERRCODE = '22003';
    END IF;

    IF EXISTS (
        SELECT 1 FROM studentparent
        WHERE student_id_ref = p_student_id AND parent_id_ref = p_parent_id
    ) THEN
        RAISE EXCEPTION 'This student is already assigned to this parent'
        USING ERRCODE = '23505';
    END IF;

    INSERT INTO studentparent(student_id_ref, parent_id_ref)
    VALUES (p_student_id, p_parent_id);
END;
$$;