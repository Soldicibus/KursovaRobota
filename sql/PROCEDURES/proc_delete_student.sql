CREATE OR REPLACE PROCEDURE proc_delete_student(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id integer;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM students WHERE student_id = p_id) THEN
        RAISE EXCEPTION 'Student % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    SELECT student_user_id INTO v_user_id
    FROM students
    WHERE student_id = p_id;

    DELETE FROM students WHERE student_id = p_id;

    IF v_user_id IS NOT NULL THEN
        PERFORM proc_delete_user(v_user_id);
    END IF;
END;
$$;
