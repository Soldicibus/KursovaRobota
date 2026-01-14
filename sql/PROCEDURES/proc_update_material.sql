CREATE OR REPLACE PROCEDURE proc_update_material(
	IN p_id integer,
	IN p_name varchar(100),
    IN p_desc text,
    IN p_link text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
		SELECT 1 FROM vws_materials WHERE material_id = p_id
    ) THEN
        RAISE EXCEPTION 'Material % does not exist', p_id
        USING ERRCODE = '22003';
    END IF; 
	
	p_name := NULLIF(trim(p_name), '');
    p_desc := NULLIF(trim(p_desc), '');
    p_link := NULLIF(trim(p_link), '');

    IF p_name IS NOT NULL AND length(p_name) = 0 THEN
        RAISE EXCEPTION 'Material name cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    UPDATE material
	SET
		material_name	= COALESCE(p_name, material_name),
		material_desc	= p_desc,
		material_link	= p_link
	WHERE material_id = p_id;

    CALL proc_create_audit_log('Material', 'UPDATE', p_id::text, 'Updated material');
END;
$$;

	