CREATE OR REPLACE PROCEDURE proc_delete_material(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM material WHERE material_id = p_id) THEN
        RAISE EXCEPTION 'Material % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM material WHERE material_id = p_id;
END;
$$;