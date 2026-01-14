CREATE OR REPLACE PROCEDURE proc_create_teacher(
    IN p_name varchar(50),
    IN p_surname varchar(50),
    IN p_patronym varchar(50),
    IN p_phone varchar(20),
    IN p_user_id integer,
    OUT new_teacher_id integer,
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
    v_teacher_role_id INT;
BEGIN
	generated_password := NULL;
    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_name IS NULL OR p_surname IS NULL OR p_phone IS NULL THEN
        RAISE EXCEPTION 'Required teacher fields cannot be empty'
        USING ERRCODE = '23514';
    END IF;

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

        /* ---------- Assign teacher role ---------- */
        SELECT role_id
        INTO v_teacher_role_id
        FROM vws_roles
        WHERE role_name = 'Student';

        IF v_teacher_role_id IS NULL THEN
            RAISE EXCEPTION 'Role teacher does not exist';
        END IF;

        CALL proc_assign_role_to_user(v_user_id, v_teacher_role_id);

        RAISE NOTICE 'Generated password for %: %', v_username, v_password;
    END IF;

    INSERT INTO teacher (
        teacher_name,
        teacher_surname,
        teacher_patronym,
        teacher_phone,
        teacher_user_id
    )
    VALUES (
        p_name,
        p_surname,
        p_patronym,
        p_phone,
        v_user_id
    )
    RETURNING teacher_id INTO new_teacher_id;

    CALL proc_create_audit_log('Teacher', 'INSERT', new_teacher_id::text, 'Created teacher');
END;
$$;