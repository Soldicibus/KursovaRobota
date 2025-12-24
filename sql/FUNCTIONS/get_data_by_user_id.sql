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
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM students WHERE student_user_id = p_user_id
    ) THEN
        RETURN QUERY
        SELECT
            get_user_role(p_user_id)::TEXT,
            s.student_id,
            s.student_name,
            s.student_surname,
	        s.student_patronym,
            u.email,
            s.student_phone
        FROM students s
        JOIN users u ON u.user_id = s.student_user_id
        WHERE s.student_user_id = p_user_id;
    ELSIF EXISTS (
        SELECT 1 FROM teacher WHERE teacher_user_id = p_user_id
    ) THEN
        RETURN QUERY
        SELECT
            get_user_role(p_user_id)::TEXT,
            t.teacher_id,
            t.teacher_name,
            t.teacher_surname,
			t.teacher_patronym,
            u.email,
            t.teacher_phone
        FROM teacher t
        JOIN users u ON u.user_id = t.teacher_user_id
        WHERE t.teacher_user_id = p_user_id;
    ELSIF EXISTS (
        SELECT 1 FROM parents WHERE parent_user_id = p_user_id
    ) THEN
        RETURN QUERY
        SELECT
            get_user_role(p_user_id)::TEXT,
            p.parent_id,
            p.parent_name,
            p.parent_surname,
			p.parent_patronym,
            u.email,
            p.parent_phone
        FROM parents p
        JOIN users u ON u.user_id = p.parent_user_id
        WHERE p.parent_user_id = p_user_id;

    ELSE
        RAISE EXCEPTION 'No entity linked to user_id %', p_user_id
        USING ERRCODE = 'P0001';
    END IF;
END;
$$;