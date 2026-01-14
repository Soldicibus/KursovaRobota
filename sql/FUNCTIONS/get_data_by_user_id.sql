CREATE OR REPLACE FUNCTION get_data_by_user_id(
    p_user_id INT
)
RETURNS TABLE (
    role TEXT,
    entity_id INT,
    name VARCHAR,
    surname VARCHAR,
    patronym VARCHAR,
    email VARCHAR,
    phone VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.role,
        v.entity_id,
        v.name,
        v.surname,
        v.patronym,
        v.email,
        v.phone
    FROM vws_all_user_details v
    WHERE v.user_id = p_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No entity linked to user_id %', p_user_id
        USING ERRCODE = 'P0001';
    END IF;
END;
$$;