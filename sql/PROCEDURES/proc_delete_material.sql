CREATE OR REPLACE PROCEDURE proc_delete_material(
    IN p_id integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_materials WHERE material_id = p_id) THEN
        RAISE EXCEPTION 'Material % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM material WHERE material_id = p_id;

    CALL proc_create_audit_log('Material', 'DELETE', p_id::text, 'Deleted material');
END;
$$;