CREATE OR REPLACE PROCEDURE proc_delete_parent(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id integer;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM parents WHERE parent_id = p_id) THEN
        RAISE EXCEPTION 'Parent % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    SELECT parent_user_id INTO v_user_id
    FROM parents
    WHERE parent_id = p_id;

    DELETE FROM parents WHERE parent_id = p_id;

    IF v_user_id IS NOT NULL THEN
        PERFORM proc_delete_user(v_user_id);
    END IF;
END;
$$;
