CREATE OR REPLACE PROCEDURE proc_create_parent(
    IN p_name VARCHAR(50),
    IN p_surname VARCHAR(50),
    IN p_patronym VARCHAR(50),
    IN p_phone VARCHAR(20),
    IN p_user_id INTEGER,
    OUT new_parent_id INTEGER,
    OUT generated_password TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id INT;
    v_username TEXT;
    v_email TEXT;
    v_password TEXT;
    v_patronym_part TEXT;
    v_parent_role_id INT;
BEGIN
	generated_password := NULL;
    /* ---------- Normalize input ---------- */
    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_name IS NULL OR p_surname IS NULL OR p_phone IS NULL THEN
        RAISE EXCEPTION 'Required parent fields cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    /* ---------- If user is provided, validate ---------- */
    IF p_user_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM vws_users WHERE user_id = p_user_id) THEN
            RAISE EXCEPTION 'User % does not exist', p_user_id
            USING ERRCODE = '22003';
        END IF;

        v_user_id := p_user_id;

    ELSE
        /* ---------- Generate username / email / password ---------- */

		IF p_patronym IS NOT NULL THEN
		    v_patronym_part :=
		        substr(
		            translit_uk_to_lat(p_patronym),
		            1,
		            3
		        );
		ELSE
		    v_patronym_part := '';
		END IF;

        v_username :=
		    translit_uk_to_lat(p_name) ||
		    translit_uk_to_lat(p_surname) ||
		    v_patronym_part;
		
		v_email :=
		    translit_uk_to_lat(p_name) ||
		    translit_uk_to_lat(p_surname) ||
		    v_patronym_part || '@school.edu.ua';

        generated_password :=
		    encode(gen_random_bytes(6), 'base64');
		
		v_password := generated_password;
		
        /* ---------- Register user ---------- */
        CALL proc_register_user(
            v_username,
            v_email,
            v_password,
            v_user_id
        );

        /* ---------- Assign parent role ---------- */
        SELECT role_id
        INTO v_parent_role_id
        FROM vws_roles
        WHERE role_name = 'Parent';

        IF v_parent_role_id IS NULL THEN
            RAISE EXCEPTION 'Role parent does not exist';
        END IF;

        CALL proc_assign_role_to_user(v_user_id, v_parent_role_id);

        RAISE NOTICE 'Generated password for %: %', v_username, v_password;
    END IF;

    /* ---------- Create parent entity ---------- */
    INSERT INTO parents (
        parent_name,
        parent_surname,
        parent_patronym,
        parent_phone,
        parent_user_id
    )
    VALUES (
        p_name,
        p_surname,
        p_patronym,
        p_phone,
        v_user_id
    )
    RETURNING parent_id INTO new_parent_id;

    CALL proc_create_audit_log('Parents', 'INSERT', new_parent_id::text, 'Created parent');
END;
$$;
