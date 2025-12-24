CREATE OR REPLACE PROCEDURE proc_update_material(
	IN p_id integer,
	IN p_name varchar(100),
    IN p_desc text,
    IN p_link text
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
		SELECT 1 FROM material WHERE material_id = p_id
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
		material_desc	= COALESCE(p_desc, material_desc),
		material_link	= COALESCE(p_link, material_link)
	WHERE material_id = p_id;
END;
$$;

	