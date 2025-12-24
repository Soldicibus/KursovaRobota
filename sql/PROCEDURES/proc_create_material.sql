CREATE OR REPLACE PROCEDURE proc_create_material(
    IN p_name varchar(100),
    IN p_desc text,
    IN p_link text,
    OUT new_material_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_name := NULLIF(trim(p_name), '');
    IF p_name IS NULL THEN
        RAISE EXCEPTION 'Material name cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    p_desc := NULLIF(trim(p_desc), '');
    p_link := NULLIF(trim(p_link), '');

    INSERT INTO material(material_name, material_desc, material_link)
    VALUES (p_name, p_desc, p_link)
    RETURNING material_id INTO new_material_id;
END;
$$;
