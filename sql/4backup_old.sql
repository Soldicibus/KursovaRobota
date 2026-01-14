--
-- PostgreSQL database dump
--

\restrict I6CIjYrKRpVuxhnlKWAodXhoAHUoHCWtBdVXSPOIVFH4aY8NGbNIrbfWr5W6tK7

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: journal_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.journal_status_enum AS ENUM (
    'Присутній',
    'П',
    'Не присутній',
    'Н'
);


ALTER TYPE public.journal_status_enum OWNER TO postgres;

--
-- Name: absents_more_than_x(character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.absents_more_than_x(p_class character varying, p_x integer) RETURNS TABLE(student_id integer, student_name character varying, student_surname character varying, absents integer)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
	SELECT s.student_id, s.student_name, s.student_surname, COUNT(*)
	FROM Students s
	JOIN StudentData sd ON s.student_id = sd.student_id
	WHERE s.student_class = p_class
	AND sd.status IN ('Н','Не присутній')
	GROUP BY s.student_id
	HAVING COUNT(*) > p_x;
$$;


ALTER FUNCTION public.absents_more_than_x(p_class character varying, p_x integer) OWNER TO postgres;

--
-- Name: get_children_by_parent(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_children_by_parent(p_parent_id integer) RETURNS TABLE(student_id integer, student_name character varying, student_surname character varying, student_class character varying, avg_grade numeric, attendance numeric)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
    SELECT
        s.student_id,
        s.student_name,
        s.student_surname,
        s.student_class,

        ROUND(AVG(j.mark)::NUMERIC, 2) AS avg_grade,

        ROUND(
            100.0 * COUNT(*) FILTER (WHERE j.status = 'Присутній' OR j.status = 'П')
            / NULLIF(COUNT(*), 0),
            2
        ) AS attendance

    FROM StudentParent sp
    JOIN Students s ON sp.student_id_ref = s.student_id
    LEFT JOIN StudentData j ON j.student_id = s.student_id

    WHERE sp.parent_id_ref = p_parent_id

    GROUP BY s.student_id, s.student_name, s.student_surname, s.student_class;
$$;


ALTER FUNCTION public.get_children_by_parent(p_parent_id integer) OWNER TO postgres;

--
-- Name: get_data_by_user_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_data_by_user_id(p_user_id integer) RETURNS TABLE(role text, entity_id integer, name character varying, surname character varying, patronym character varying, email character varying, phone character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
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


ALTER FUNCTION public.get_data_by_user_id(p_user_id integer) OWNER TO postgres;

--
-- Name: get_homework_by_createdate(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) RETURNS TABLE(homework_name character varying, teacher_name character varying, teacher_surname character varying, lesson_name character varying, homework_duedate date, homework_created_at date, homework_desc text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.homework_name,
        t.teacher_name,
        t.teacher_surname,
        l.lesson_name,
        h.homework_duedate,
		h.homework_created_at,
        h.homework_desc
    FROM Homework h
    JOIN Lessons l ON h.homework_lesson = l.lesson_id
    JOIN Teacher t ON h.homework_teacher = t.teacher_id
    WHERE h.homework_class = p_class
      AND h.homework_created_at = p_date
    ORDER BY l.lesson_date;
END;
$$;


ALTER FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) OWNER TO postgres;

--
-- Name: get_homework_by_date_class(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_homework_by_date_class(p_class character varying, p_date date) RETURNS TABLE(name character varying, description text)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
	SELECT homework_name, homework_desc
	FROM Homework
	WHERE homework_class = p_class
	AND homework_duedate = p_date;
$$;


ALTER FUNCTION public.get_homework_by_date_class(p_class character varying, p_date date) OWNER TO postgres;

--
-- Name: get_homework_by_duedate(character varying, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) RETURNS TABLE(homework_name character varying, teacher_name character varying, teacher_surname character varying, lesson_name character varying, homework_duedate date, homework_created_at date, homework_desc text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.homework_name,
        t.teacher_name,
        t.teacher_surname,
        l.lesson_name,
        h.homework_duedate,
		h.homework_created_at,
        h.homework_desc
    FROM Homework h
	JOIN Lessons l ON h.homework_lesson = l.lesson_id
    JOIN Teacher t ON h.homework_teacher = t.teacher_id
	WHERE homework_class = p_class
	AND homework_duedate = p_date;
END;
$$;


ALTER FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) OWNER TO postgres;

--
-- Name: get_student_grade_entries(integer, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_grade_entries(p_student_id integer, p_start_date timestamp without time zone DEFAULT (CURRENT_DATE - '2 days'::interval), p_end_date timestamp without time zone DEFAULT (CURRENT_DATE + '7 days'::interval)) RETURNS TABLE(lesson_id integer, lesson_date timestamp without time zone, subject_name text, journal_id integer, data_id integer, mark smallint, note text, status text)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
    SELECT
	l.lesson_id,
        l.lesson_date,
        s.subject_name,
		sd.journal_id,
		sd.data_id,
        sd.mark,
		sd.note,
        sd.status
    FROM StudentData sd
    JOIN Lessons l ON sd.lesson = l.lesson_id
    JOIN Subjects s ON l.lesson_subject = s.subject_id
    WHERE sd.student_id = p_student_id
      AND l.lesson_date BETWEEN p_start_date AND p_end_date
	  AND sd.mark IS NOT NULL
    ORDER BY l.lesson_date DESC, s.subject_name;
$$;


ALTER FUNCTION public.get_student_grade_entries(p_student_id integer, p_start_date timestamp without time zone, p_end_date timestamp without time zone) OWNER TO postgres;

--
-- Name: get_student_marks(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_marks(p_student_id integer, p_from date DEFAULT (CURRENT_DATE - '1 mon'::interval), p_to date DEFAULT CURRENT_DATE) RETURNS TABLE(mark smallint, lesson_date date)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
	SELECT sd.mark, l.lesson_date
	FROM StudentData sd
	JOIN Journal j ON sd.journal_id = j.journal_id
	JOIN Lessons l ON j.journal_teacher = l.lesson_teacher
	WHERE sd.mark IS NOT NULL
	AND sd.student_id = p_student_id
	  AND l.lesson_date BETWEEN p_from AND p_to;
$$;


ALTER FUNCTION public.get_student_marks(p_student_id integer, p_from date, p_to date) OWNER TO postgres;

--
-- Name: get_teacher_salary(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_teacher_salary(p_teacher_id integer, p_from date DEFAULT (CURRENT_DATE - '1 mon'::interval), p_to date DEFAULT CURRENT_DATE) RETURNS numeric
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
SELECT COUNT(*) * 550
	FROM Lessons
	WHERE lesson_teacher = p_teacher_id
	AND lesson_date BETWEEN p_from AND p_to;
$$;


ALTER FUNCTION public.get_teacher_salary(p_teacher_id integer, p_from date, p_to date) OWNER TO postgres;

--
-- Name: get_timetable_id_by_student_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_timetable_id_by_student_id(p_student_id integer) RETURNS integer
    LANGUAGE sql
    AS $$
    SELECT t.timetable_id
    FROM students s
    JOIN class c ON c.class_name = s.student_class
    JOIN timetable t ON t.timetable_class = c.class_name
    WHERE s.student_id = p_student_id
    LIMIT 1;
$$;


ALTER FUNCTION public.get_timetable_id_by_student_id(p_student_id integer) OWNER TO postgres;

--
-- Name: get_user_role(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_role(p_user_id integer) RETURNS TABLE(role_name character varying)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
	SELECT r.role_name
	FROM UserRole ur
	JOIN Roles r ON ur.role_id = r.role_id
	WHERE ur.user_id = p_user_id;
$$;


ALTER FUNCTION public.get_user_role(p_user_id integer) OWNER TO postgres;

--
-- Name: homework_by_date_subject(date, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.homework_by_date_subject(p_date date, p_subject integer DEFAULT NULL::integer) RETURNS TABLE(homework text)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
	SELECT h.homework_desc
	FROM Homework h
	JOIN Lessons l ON h.homework_lesson = l.lesson_id
	WHERE h.homework_duedate = p_date
	AND (p_subject IS NULL OR l.lesson_subject = p_subject);
$$;


ALTER FUNCTION public.homework_by_date_subject(p_date date, p_subject integer) OWNER TO postgres;

--
-- Name: login_user(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.login_user(p_login text, p_password text) RETURNS TABLE(user_id integer, username character varying, email character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.user_id,
        u.username,
        u.email
    FROM vws_user_auth_info u
    WHERE
        (u.username = p_login OR u.email = p_login)
        AND u.password = crypt(p_password, u.password);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid credentials'
        USING ERRCODE = '28P01';
    END IF;
END;
$$;


ALTER FUNCTION public.login_user(p_login text, p_password text) OWNER TO postgres;

--
-- Name: proc_assign_role_to_user(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_assign_role_to_user(IN p_user_id integer, IN p_role_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_roles WHERE role_id = p_role_id
    ) THEN
        RAISE EXCEPTION 'Role % does not exist', p_role_id
        USING ERRCODE = '22003';
    END IF;

    IF EXISTS (
        SELECT 1 FROM vws_user_roles
        WHERE user_id = p_user_id AND role_id = p_role_id
    ) THEN
        RAISE EXCEPTION 'User % already has role %', p_user_id, p_role_id
        USING ERRCODE = '23505';
    END IF;

    INSERT INTO userrole (user_id, role_id)
    VALUES (p_user_id, p_role_id);

    CALL proc_create_audit_log('UserRole', 'INSERT', p_user_id || ',' || p_role_id, 'Assigned role to user');
END;
$$;


ALTER PROCEDURE public.proc_assign_role_to_user(IN p_user_id integer, IN p_role_id integer) OWNER TO postgres;

--
-- Name: proc_assign_student_parent(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_assign_student_parent(IN p_student_id integer, IN p_parent_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_students WHERE student_id = p_student_id) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM vws_parents WHERE parent_id = p_parent_id) THEN
        RAISE EXCEPTION 'Parent % does not exist', p_parent_id
        USING ERRCODE = '22003';
    END IF;

    IF EXISTS (
        SELECT 1 FROM vws_student_parents
        WHERE student_id_ref = p_student_id AND parent_id_ref = p_parent_id
    ) THEN
        RAISE EXCEPTION 'This student is already assigned to this parent'
        USING ERRCODE = '23505';
    END IF;

    INSERT INTO studentparent(student_id_ref, parent_id_ref)
    VALUES (p_student_id, p_parent_id);

    CALL proc_create_audit_log('StudentParent', 'INSERT', p_student_id || ',' || p_parent_id, 'Assigned student to parent');
END;
$$;


ALTER PROCEDURE public.proc_assign_student_parent(IN p_student_id integer, IN p_parent_id integer) OWNER TO postgres;

--
-- Name: proc_assign_user_to_entity(integer, text, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_assign_user_to_entity(IN p_user_id integer, IN p_entity_type text, IN p_entity_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF lower(p_entity_type) NOT IN ('student', 'parent', 'teacher') THEN
        RAISE EXCEPTION
            'Invalid entity type: % (allowed: student, parent, teacher)',
            p_entity_type
        USING ERRCODE = '22023';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION
            'User with id % does not exist',
            p_user_id
        USING ERRCODE = '23503';
    END IF;

    IF EXISTS (
        SELECT 1 FROM Students WHERE student_user_id = p_user_id
        UNION ALL
        SELECT 1 FROM Parents  WHERE parent_user_id = p_user_id
        UNION ALL
        SELECT 1 FROM Teacher WHERE teacher_user_id = p_user_id
    ) THEN
        RAISE EXCEPTION
            'User % is already assigned to an entity',
            p_user_id
        USING ERRCODE = '23505';
    END IF;

    CASE lower(p_entity_type)

        WHEN 'student' THEN
            UPDATE Students
            SET student_user_id = p_user_id
            WHERE student_id = p_entity_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION
                    'Student with id % not found',
                    p_entity_id
                USING ERRCODE = '02000';
            END IF;

        WHEN 'parent' THEN
            UPDATE Parents
            SET parent_user_id = p_user_id
            WHERE parent_id = p_entity_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION
                    'Parent with id % not found',
                    p_entity_id
                USING ERRCODE = '02000';
            END IF;

        WHEN 'teacher' THEN
            UPDATE Teacher
            SET teacher_user_id = p_user_id
            WHERE teacher_id = p_entity_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION
                    'Teacher with id % not found',
                    p_entity_id
                USING ERRCODE = '02000';
            END IF;

    END CASE;
END;
$$;


ALTER PROCEDURE public.proc_assign_user_to_entity(IN p_user_id integer, IN p_entity_type text, IN p_entity_id integer) OWNER TO postgres;

--
-- Name: proc_create_audit_log(character varying, character varying, text, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_audit_log(IN p_table_name character varying, IN p_operation character varying, IN p_record_id text, IN p_details text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF p_table_name IS NULL OR p_operation IS NULL THEN
        RAISE EXCEPTION 'Table name and operation type are required for auditing.'
        USING ERRCODE = '22004';
    END IF;

    IF length(p_table_name) > 50 THEN
        RAISE EXCEPTION 'Table name exceeds 50 characters.'
        USING ERRCODE = '22001';
    END IF;

    IF length(p_operation) > 20 THEN
        RAISE EXCEPTION 'Operation type exceeds 20 characters.'
        USING ERRCODE = '22001';
    END IF;
	
	INSERT INTO AuditLog (table_name, operation, record_id, details)
    VALUES (p_table_name, p_operation, p_record_id, p_details);
END;
$$;


ALTER PROCEDURE public.proc_create_audit_log(IN p_table_name character varying, IN p_operation character varying, IN p_record_id text, IN p_details text) OWNER TO postgres;

--
-- Name: proc_create_class(character varying, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO Class (class_name, class_journal_id, class_mainTeacher)
    VALUES (p_class_name, p_class_journal_id, p_class_mainTeacher);

    CALL proc_create_audit_log('Class', 'INSERT', p_class_name::TEXT, 'Created class ' || p_class_name);
END;
$$;


ALTER PROCEDURE public.proc_create_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer) OWNER TO postgres;

--
-- Name: proc_create_day(integer, integer, time without time zone, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_day(IN p_subject integer, IN p_timetable integer, IN p_day_time time without time zone, IN p_day_weekday character varying, OUT new_day_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_timetables WHERE timetable_id = p_timetable
    ) THEN
        RAISE EXCEPTION 'Timetable % does not exist', p_timetable
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_subjects WHERE subject_id = p_subject
    ) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject
        USING ERRCODE = '22003';
    END IF;
	
    IF p_day_time IS NULL THEN
        RAISE EXCEPTION 'Day time cannot be NULL'
        USING ERRCODE = '23502';
    END IF;

    IF NOT p_day_weekday IN ('Понеділок', 'Вівторок', 'Середа', 'Четвер', 'П''ятниця') THEN
        RAISE EXCEPTION 'Invalid weekday: %', p_day_weekday
        USING ERRCODE = '23514';
    END IF;

    INSERT INTO Days(day_subject, day_timetable, day_time, day_weekday)
    VALUES (p_subject, p_timetable, p_day_time, p_day_weekday)
    RETURNING day_id INTO new_day_id;

    CALL proc_create_audit_log('Days', 'INSERT', new_day_id::text, 'Created day');
END;
$$;


ALTER PROCEDURE public.proc_create_day(IN p_subject integer, IN p_timetable integer, IN p_day_time time without time zone, IN p_day_weekday character varying, OUT new_day_id integer) OWNER TO postgres;

--
-- Name: proc_create_homework(character varying, integer, integer, date, text, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_homework(INOUT p_name character varying, IN p_teacher integer, IN p_lesson integer, INOUT p_duedate date, INOUT p_desc text, IN p_class character varying, OUT new_homework_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
BEGIN
    p_name := NULLIF(trim(p_name), '');
    p_desc := NULLIF(trim(p_desc), '');

    IF p_desc IS NULL THEN
        RAISE EXCEPTION 'Homework description cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_teachers WHERE teacher_id = p_teacher
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_lessons WHERE lesson_id = p_lesson
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_classes WHERE class_name = p_class
    ) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '23503';
    END IF;

    IF p_class !~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$' THEN
        RAISE EXCEPTION 'Class "%" does not match format N-Letter (e.g., 7-А)', p_class
        USING ERRCODE = '23514';
    END IF;

    IF p_duedate IS NULL THEN
        RAISE EXCEPTION 'Due date cannot be NULL'
        USING ERRCODE = '23502';
    END IF;

    IF p_duedate < CURRENT_DATE THEN
        RAISE EXCEPTION 'Due date (%) cannot be in the past', p_duedate
        USING ERRCODE = '22007';
    END IF;

    INSERT INTO homework(
        homework_name,
        homework_teacher,
        homework_lesson,
        homework_duedate,
        homework_desc,
        homework_class
    )
    VALUES (
        p_name,
        p_teacher,
        p_lesson,
        p_duedate,
        p_desc,
        p_class
    )
    RETURNING homework_id INTO new_homework_id;

    CALL proc_create_audit_log('Homework', 'INSERT', new_homework_id::text, 'Created homework');
END;
$_$;


ALTER PROCEDURE public.proc_create_homework(INOUT p_name character varying, IN p_teacher integer, IN p_lesson integer, INOUT p_duedate date, INOUT p_desc text, IN p_class character varying, OUT new_homework_id integer) OWNER TO postgres;

--
-- Name: proc_create_journal(integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_journal(IN p_journal_teacher integer, IN p_journal_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO Journal (journal_teacher, journal_name)
    VALUES (p_journal_teacher, p_journal_name);

    CALL proc_create_audit_log('Journal', 'INSERT', p_journal_name, 'Created journal ' || p_journal_name);
END;
$$;


ALTER PROCEDURE public.proc_create_journal(IN p_journal_teacher integer, IN p_journal_name character varying) OWNER TO postgres;

--
-- Name: proc_create_lesson(character varying, character varying, integer, integer, integer, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_lesson(IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone, OUT new_lesson_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_classes WHERE class_name = p_class) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM vws_subjects WHERE subject_id = p_subject) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject
        USING ERRCODE = '22003';
    END IF;

    IF p_material IS NOT NULL AND NOT EXISTS (SELECT 1 FROM vws_materials WHERE material_id = p_material) THEN
        RAISE EXCEPTION 'Material % does not exist', p_material
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM vws_teachers WHERE teacher_id = p_teacher) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '22003';
    END IF;

    INSERT INTO Lessons(lesson_name, lesson_class, lesson_subject, lesson_material, lesson_teacher, lesson_date)
    VALUES (p_name, p_class, p_subject, p_material, p_teacher, COALESCE(p_date, CURRENT_DATE))
    RETURNING lesson_id INTO new_lesson_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Lessons', 'INSERT', new_lesson_id::text, SESSION_USER, 'Created lesson');
END;
$$;


ALTER PROCEDURE public.proc_create_lesson(IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone, OUT new_lesson_id integer) OWNER TO postgres;

--
-- Name: proc_create_material(character varying, text, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_material(IN p_name character varying, IN p_desc text, IN p_link text, OUT new_material_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
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

    CALL proc_create_audit_log('Material', 'INSERT', new_material_id::text, 'Created material');
END;
$$;


ALTER PROCEDURE public.proc_create_material(IN p_name character varying, IN p_desc text, IN p_link text, OUT new_material_id integer) OWNER TO postgres;

--
-- Name: proc_create_parent(character varying, character varying, character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_parent(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_parent_id integer, OUT generated_password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
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

		v_patronym_part :=
		    substr(
		        translit_uk_to_lat(coalesce(p_patronym, 'xxx')),
		        1,
		        3
		    );

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


ALTER PROCEDURE public.proc_create_parent(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_parent_id integer, OUT generated_password text) OWNER TO postgres;

--
-- Name: proc_create_role(character varying, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_role(IN p_role_name character varying, IN p_role_desc text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO Roles (role_name, role_desc)
    VALUES (p_role_name, p_role_desc);

    CALL proc_create_audit_log('Roles', 'INSERT', p_role_name, 'Created role ' || p_role_name);
END;
$$;


ALTER PROCEDURE public.proc_create_role(IN p_role_name character varying, IN p_role_desc text) OWNER TO postgres;

--
-- Name: proc_create_student(character varying, character varying, character varying, character varying, integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_student(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying, OUT new_student_id integer, OUT generated_password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_user_id INT;
    v_username TEXT;
    v_email TEXT;
    v_password TEXT;
    v_patronym_part TEXT;
    v_student_role_id INT;
BEGIN
	generated_password := NULL;
    /* ---------- Normalize input ---------- */
    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_name IS NULL OR p_surname IS NULL OR p_phone IS NULL THEN
        RAISE EXCEPTION 'Required student fields cannot be empty'
        USING ERRCODE = '23514';
    END IF;

	IF NOT EXISTS (
        SELECT 1 FROM vws_classes WHERE class_name = p_class
    ) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '22003';
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

		v_patronym_part :=
		    substr(
		        translit_uk_to_lat(coalesce(p_patronym, 'xxx')),
		        1,
		        3
		    );

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

        /* ---------- Assign student role ---------- */
        SELECT role_id
        INTO v_student_role_id
        FROM vws_roles
        WHERE role_name = 'Student';

        IF v_student_role_id IS NULL THEN
            RAISE EXCEPTION 'Role student does not exist';
        END IF;

        CALL proc_assign_role_to_user(v_user_id, v_student_role_id);

        RAISE NOTICE 'Generated password for %: %', v_username, v_password;
    END IF;

    /* ---------- Create parent entity ---------- */
    INSERT INTO students (
        student_name,
        student_surname,
        student_patronym,
        student_phone,
        student_user_id,
		student_class
    )
    VALUES (
        p_name,
        p_surname,
        p_patronym,
        p_phone,
        v_user_id,
		p_class
    )
    RETURNING student_id INTO new_student_id;

    CALL proc_create_audit_log('Students', 'INSERT', new_student_id::text, 'Created student');
END;
$$;


ALTER PROCEDURE public.proc_create_student(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying, OUT new_student_id integer, OUT generated_password text) OWNER TO postgres;

--
-- Name: proc_create_studentdata(integer, integer, integer, smallint, public.journal_status_enum, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_studentdata(IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, INOUT p_note text, OUT new_data_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_journals WHERE journal_id = p_journal_id
    ) THEN
        RAISE EXCEPTION 'Journal % does not exist', p_journal_id
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_students WHERE student_id = p_student_id
    ) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_lessons WHERE lesson_id = p_lesson
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson
        USING ERRCODE = '23503';
    END IF;

    IF p_mark IS NOT NULL AND (p_mark < 1 OR p_mark > 12) THEN
        RAISE EXCEPTION 'Mark % is out of range (1–12)', p_mark
        USING ERRCODE = '22003';
    END IF;

    p_note := NULLIF(trim(p_note), '');

    INSERT INTO studentdata (
        journal_id,
        student_id,
        lesson,
        mark,
        status,
        note
    )
    VALUES (
        p_journal_id,
        p_student_id,
        p_lesson,
        p_mark,
        p_status,
        p_note
    )
    RETURNING data_id INTO new_data_id;

    CALL proc_create_audit_log('StudentData', 'INSERT', new_data_id::text, 'Created student data');
END;
$$;


ALTER PROCEDURE public.proc_create_studentdata(IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, INOUT p_note text, OUT new_data_id integer) OWNER TO postgres;

--
-- Name: proc_create_subject(text, integer, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_subject(IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO Subjects (subject_name, cabinet, subject_program)
    VALUES (p_subject_name, p_cabinet, p_subject_program);

    CALL proc_create_audit_log('Subjects', 'INSERT', p_subject_name, 'Created subject ' || p_subject_name);
END;
$$;


ALTER PROCEDURE public.proc_create_subject(IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text) OWNER TO postgres;

--
-- Name: proc_create_teacher(character varying, character varying, character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_teacher(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_teacher_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_name IS NULL OR p_surname IS NULL OR p_phone IS NULL THEN
        RAISE EXCEPTION 'Required teacher fields cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
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
        p_user_id
    )
    RETURNING teacher_id INTO new_teacher_id;

    CALL proc_create_audit_log('Teacher', 'INSERT', new_teacher_id::text, 'Created teacher');
END;
$$;


ALTER PROCEDURE public.proc_create_teacher(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_teacher_id integer) OWNER TO postgres;

--
-- Name: proc_create_timetable(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_timetable(IN p_timetable_name character varying, IN p_timetable_class character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO Timetable (timetable_name, timetable_class)
    VALUES (p_timetable_name, p_timetable_class);

    CALL proc_create_audit_log('Timetable', 'INSERT', p_timetable_name, 'Created timetable ' || p_timetable_name);
END;
$$;


ALTER PROCEDURE public.proc_create_timetable(IN p_timetable_name character varying, IN p_timetable_class character varying) OWNER TO postgres;

--
-- Name: proc_create_user(character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_create_user(IN p_username character varying, IN p_email character varying, IN p_password character varying, OUT new_user_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    p_username := NULLIF(trim(p_username), '');
    p_email := NULLIF(trim(p_email), '');
    p_password := NULLIF(trim(p_password), '');

    IF p_username IS NULL THEN
        RAISE EXCEPTION 'Username cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_email IS NULL THEN
        RAISE EXCEPTION 'Email cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_password IS NULL THEN
        RAISE EXCEPTION 'Password cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1 FROM vws_users WHERE username = p_username
    ) THEN
        RAISE EXCEPTION 'Username % already exists', p_username
        USING ERRCODE = '23505';
    END IF;

    IF EXISTS (
        SELECT 1 FROM vws_users WHERE email = p_email
    ) THEN
        RAISE EXCEPTION 'Email % already exists', p_email
        USING ERRCODE = '23505';
    END IF;

    INSERT INTO users (username, email, password)
    VALUES (p_username, p_email, p_password)
    RETURNING user_id INTO new_user_id;

    CALL proc_create_audit_log('Users', 'INSERT', new_user_id::text, 'Created user');
END;
$$;


ALTER PROCEDURE public.proc_create_user(IN p_username character varying, IN p_email character varying, IN p_password character varying, OUT new_user_id integer) OWNER TO postgres;

--
-- Name: proc_delete_class(character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_class(IN p_class_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Class WHERE class_name = p_class_name) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class_name;
    END IF;

    DELETE FROM Class WHERE class_name = p_class_name;

    CALL proc_create_audit_log('Class', 'DELETE', p_class_name::TEXT, 'Deleted class ' || p_class_name);
END;
$$;


ALTER PROCEDURE public.proc_delete_class(IN p_class_name character varying) OWNER TO postgres;

--
-- Name: proc_delete_day(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_day(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_days WHERE day_id = p_id) THEN
        RAISE EXCEPTION 'Day % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM days WHERE day_id = p_id;

    CALL proc_create_audit_log('Days', 'DELETE', p_id::text, 'Deleted day');
END;
$$;


ALTER PROCEDURE public.proc_delete_day(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_homework(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_homework(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_homeworks WHERE homework_id = p_id) THEN
        RAISE EXCEPTION 'Homework % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM homework WHERE homework_id = p_id;

    CALL proc_create_audit_log('Homework', 'DELETE', p_id::text, 'Deleted homework');
END;
$$;


ALTER PROCEDURE public.proc_delete_homework(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_journal(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_journal(IN p_journal_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Journal WHERE journal_id = p_journal_id) THEN
        RAISE EXCEPTION 'Journal with ID % does not exist', p_journal_id;
    END IF;

    DELETE FROM Journal WHERE journal_id = p_journal_id;

    CALL proc_create_audit_log('Journal', 'DELETE', p_journal_id::TEXT, 'Deleted journal ' || p_journal_id);
END;
$$;


ALTER PROCEDURE public.proc_delete_journal(IN p_journal_id integer) OWNER TO postgres;

--
-- Name: proc_delete_lesson(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_lesson(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_lessons WHERE lesson_id = p_id) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM lessons WHERE lesson_id = p_id;

    CALL proc_create_audit_log('Lessons', 'DELETE', p_id::text, 'Deleted lesson');
END;
$$;


ALTER PROCEDURE public.proc_delete_lesson(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_material(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_material(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
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


ALTER PROCEDURE public.proc_delete_material(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_parent(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_parent(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_user_id integer;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_parents WHERE parent_id = p_id) THEN
        RAISE EXCEPTION 'Parent % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    SELECT parent_user_id INTO v_user_id
    FROM vws_parents
    WHERE parent_id = p_id;

    DELETE FROM parents WHERE parent_id = p_id;

    CALL proc_create_audit_log('Parents', 'DELETE', p_id::text, 'Deleted parent');

    IF v_user_id IS NOT NULL THEN
        PERFORM proc_delete_user(v_user_id);
    END IF;
END;
$$;


ALTER PROCEDURE public.proc_delete_parent(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_role(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_role(IN p_role_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_id = p_role_id) THEN
        RAISE EXCEPTION 'Role with ID % does not exist', p_role_id;
    END IF;

    DELETE FROM Roles WHERE role_id = p_role_id;

    CALL proc_create_audit_log('Roles', 'DELETE', p_role_id::TEXT, 'Deleted role ' || p_role_id);
END;
$$;


ALTER PROCEDURE public.proc_delete_role(IN p_role_id integer) OWNER TO postgres;

--
-- Name: proc_delete_student(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_student(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_user_id integer;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_students WHERE student_id = p_id) THEN
        RAISE EXCEPTION 'Student % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    SELECT student_user_id INTO v_user_id
    FROM vws_students
    WHERE student_id = p_id;

    DELETE FROM students WHERE student_id = p_id;

    CALL proc_create_audit_log('Students', 'DELETE', p_id::text, 'Deleted student');

    IF v_user_id IS NOT NULL THEN
        PERFORM proc_delete_user(v_user_id);
    END IF;
END;
$$;


ALTER PROCEDURE public.proc_delete_student(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_studentdata(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_studentdata(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_student_data WHERE data_id = p_id) THEN
        RAISE EXCEPTION 'StudentData % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM studentdata WHERE data_id = p_id;

    CALL proc_create_audit_log('StudentData', 'DELETE', p_id::text, 'Deleted student data');
END;
$$;


ALTER PROCEDURE public.proc_delete_studentdata(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_subject(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_subject(IN p_subject_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Subjects WHERE subject_id = p_subject_id) THEN
        RAISE EXCEPTION 'Subject with ID % does not exist', p_subject_id;
    END IF;

    DELETE FROM Subjects WHERE subject_id = p_subject_id;

    CALL proc_create_audit_log('Subjects', 'DELETE', p_subject_id::TEXT, 'Deleted subject ' || p_subject_id);
END;
$$;


ALTER PROCEDURE public.proc_delete_subject(IN p_subject_id integer) OWNER TO postgres;

--
-- Name: proc_delete_teacher(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_teacher(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_user_id integer;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_teachers WHERE teacher_id = p_id) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    SELECT teacher_user_id INTO v_user_id
    FROM vws_teachers
    WHERE teacher_id = p_id;

    DELETE FROM teacher WHERE teacher_id = p_id;

    CALL proc_create_audit_log('Teacher', 'DELETE', p_id::text, 'Deleted teacher');

    IF v_user_id IS NOT NULL THEN
        PERFORM proc_delete_user(v_user_id);
    END IF;
END;
$$;


ALTER PROCEDURE public.proc_delete_teacher(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_delete_timetable(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_timetable(IN p_timetable_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Timetable WHERE timetable_id = p_timetable_id) THEN
        RAISE EXCEPTION 'Timetable with ID % does not exist', p_timetable_id;
    END IF;

    DELETE FROM Timetable WHERE timetable_id = p_timetable_id;

    CALL proc_create_audit_log('Timetable', 'DELETE', p_timetable_id::TEXT, 'Deleted timetable ' || p_timetable_id);
END;
$$;


ALTER PROCEDURE public.proc_delete_timetable(IN p_timetable_id integer) OWNER TO postgres;

--
-- Name: proc_delete_user(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_delete_user(IN p_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_users WHERE user_id = p_id) THEN
        RAISE EXCEPTION 'User % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM users WHERE user_id = p_id;

    CALL proc_create_audit_log('Users', 'DELETE', p_id::text, 'Deleted user');
END;
$$;


ALTER PROCEDURE public.proc_delete_user(IN p_id integer) OWNER TO postgres;

--
-- Name: proc_register_user(character varying, character varying, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_register_user(IN p_username character varying, IN p_email character varying, IN p_password text, OUT new_user_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    /* ---------- Normalize ---------- */
    p_username := NULLIF(trim(p_username), '');
    p_email    := NULLIF(trim(p_email), '');
    p_password := NULLIF(trim(p_password), '');

    IF p_username IS NULL THEN
        RAISE EXCEPTION 'Username cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_email IS NULL THEN
        RAISE EXCEPTION 'Email cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_password IS NULL THEN
        RAISE EXCEPTION 'Password cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF EXISTS (SELECT 1 FROM vws_users WHERE username = p_username) THEN
        RAISE EXCEPTION 'Username % already exists', p_username
        USING ERRCODE = '23505';
    END IF;

    IF EXISTS (SELECT 1 FROM vws_users WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email % already exists', p_email
        USING ERRCODE = '23505';
    END IF;

    /* ---------- Hash password ---------- */
    p_password := crypt(p_password, gen_salt('bf'));

    /* ---------- PASS OUT PARAM DIRECTLY ---------- */
    CALL proc_create_user(
        p_username,
        p_email,
        p_password,
        new_user_id
    );
END;
$$;


ALTER PROCEDURE public.proc_register_user(IN p_username character varying, IN p_email character varying, IN p_password text, OUT new_user_id integer) OWNER TO postgres;

--
-- Name: proc_remove_role_from_user(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_remove_role_from_user(IN p_user_id integer, IN p_role_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM vws_users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vws_user_roles
        WHERE user_id = p_user_id AND role_id = p_role_id
    ) THEN
        RAISE EXCEPTION 'Role % is not assigned to user %', p_role_id, p_user_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM userrole
    WHERE user_id = p_user_id AND role_id = p_role_id;

    CALL proc_create_audit_log('UserRole', 'DELETE', p_user_id || ',' || p_role_id, 'Removed role from user');
END;
$$;


ALTER PROCEDURE public.proc_remove_role_from_user(IN p_user_id integer, IN p_role_id integer) OWNER TO postgres;

--
-- Name: proc_reset_user_password(integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_reset_user_password(IN p_user_id integer, IN p_new_password character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    p_new_password := NULLIF(trim(p_new_password), '');

    IF p_new_password IS NULL THEN
        RAISE EXCEPTION 'Password cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    UPDATE users
    SET password = p_new_password
    WHERE user_id = p_user_id;

    CALL proc_create_audit_log('Users', 'UPDATE', p_user_id::text, 'Reset user password');
END;
$$;


ALTER PROCEDURE public.proc_reset_user_password(IN p_user_id integer, IN p_new_password character varying) OWNER TO postgres;

--
-- Name: proc_unassign_student_parent(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_unassign_student_parent(IN p_student_id integer, IN p_parent_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_student_parents
        WHERE student_id_ref = p_student_id AND parent_id_ref = p_parent_id
    ) THEN
        RAISE EXCEPTION 'No assignment exists between student % and parent %', p_student_id, p_parent_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM studentparent
    WHERE student_id_ref = p_student_id AND parent_id_ref = p_parent_id;

    CALL proc_create_audit_log('StudentParent', 'DELETE', p_student_id || ',' || p_parent_id, 'Unassigned student from parent');
END;
$$;


ALTER PROCEDURE public.proc_unassign_student_parent(IN p_student_id integer, IN p_parent_id integer) OWNER TO postgres;

--
-- Name: proc_update_class(character varying, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Class WHERE class_name = p_class_name) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class_name;
    END IF;

    UPDATE Class
    SET class_journal_id = COALESCE(p_class_journal_id, class_journal_id),
        class_mainTeacher = COALESCE(p_class_mainTeacher, class_mainTeacher)
    WHERE class_name = p_class_name;

    CALL proc_create_audit_log('Class', 'UPDATE', p_class_name::TEXT, 'Updated class ' || p_class_name);
END;
$$;


ALTER PROCEDURE public.proc_update_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer) OWNER TO postgres;

--
-- Name: proc_update_day(integer, integer, integer, time without time zone, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_day(IN p_id integer, IN p_subject integer, IN p_timetable integer, IN p_time time without time zone DEFAULT NULL::time without time zone, IN p_weekday character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_days WHERE day_id = p_id
    ) THEN
        RAISE EXCEPTION 'Day % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;
	
	IF NOT EXISTS (
        SELECT 1 FROM vws_timetables WHERE timetable_id = p_timetable
    ) THEN
        RAISE EXCEPTION 'Timetable % does not exist', p_timetable
        USING ERRCODE = '22003';
    END IF;

	IF NOT EXISTS (
        SELECT 1 FROM vws_subjects WHERE subject_id = p_subject
    ) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject
        USING ERRCODE = '22003';
    END IF;
    p_weekday := NULLIF(trim(p_weekday), '');

    IF p_weekday IS NOT NULL AND
       p_weekday NOT IN ('Понеділок', 'Вівторок', 'Середа', 'Четвер', 'П’ятниця') THEN
        RAISE EXCEPTION 'Invalid weekday: %', p_weekday
        USING ERRCODE = '23514';
    END IF;

    UPDATE days
    SET
        day_timetable    = COALESCE(p_timetable, day_timetable),
		day_subject		= COALESCE(p_subject, day_subject),
        day_time    = COALESCE(p_time, day_time),
        day_weekday = COALESCE(p_weekday, day_weekday)
    WHERE day_id = p_id;

    CALL proc_create_audit_log('Days', 'UPDATE', p_id::text, 'Updated day');
END;
$$;


ALTER PROCEDURE public.proc_update_day(IN p_id integer, IN p_subject integer, IN p_timetable integer, IN p_time time without time zone, IN p_weekday character varying) OWNER TO postgres;

--
-- Name: proc_update_homework(integer, character varying, integer, integer, date, text, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_homework(IN p_id integer, IN p_name character varying DEFAULT NULL::character varying, IN p_teacher integer DEFAULT NULL::integer, IN p_lesson integer DEFAULT NULL::integer, IN p_duedate date DEFAULT NULL::date, IN p_desc text DEFAULT NULL::text, IN p_class character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_homeworks WHERE homework_id = p_id
    ) THEN
        RAISE EXCEPTION 'Homework % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_desc := NULLIF(trim(p_desc), '');
    p_class := NULLIF(trim(p_class), '');

    IF p_desc IS NOT NULL AND length(p_desc) = 0 THEN
        RAISE EXCEPTION 'Homework description cannot be empty'
        USING ERRCODE = '23514';
    END IF;

    IF p_teacher IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_teachers WHERE teacher_id = p_teacher
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '22003';
    END IF;

    IF p_lesson IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_lessons WHERE lesson_id = p_lesson
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson
        USING ERRCODE = '22003';
    END IF;

    IF p_class IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM vws_classes WHERE class_name = p_class
        ) THEN
            RAISE EXCEPTION 'Class % does not exist', p_class
            USING ERRCODE = '22003';
        END IF;

        IF p_class !~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$' THEN
            RAISE EXCEPTION 'Invalid class format: %', p_class
            USING ERRCODE = '23514';
        END IF;
    END IF;

    IF p_duedate IS NOT NULL AND p_duedate < CURRENT_DATE THEN
        RAISE EXCEPTION 'Due date (%) cannot be in the past', p_duedate
        USING ERRCODE = '22007';
    END IF;

    UPDATE homework
    SET
        homework_name    = COALESCE(p_name, homework_name),
        homework_teacher = COALESCE(p_teacher, homework_teacher),
        homework_lesson  = COALESCE(p_lesson, homework_lesson),
        homework_duedate = COALESCE(p_duedate, homework_duedate),
        homework_desc    = COALESCE(p_desc, homework_desc),
        homework_class   = COALESCE(p_class, homework_class)
    WHERE homework_id = p_id;

    CALL proc_create_audit_log('Homework', 'UPDATE', p_id::text, 'Updated homework');
END;
$_$;


ALTER PROCEDURE public.proc_update_homework(IN p_id integer, IN p_name character varying, IN p_teacher integer, IN p_lesson integer, IN p_duedate date, IN p_desc text, IN p_class character varying) OWNER TO postgres;

--
-- Name: proc_update_journal(integer, integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_journal(IN p_journal_id integer, IN p_journal_teacher integer, IN p_journal_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Journal WHERE journal_id = p_journal_id) THEN
        RAISE EXCEPTION 'Journal with ID % does not exist', p_journal_id;
    END IF;

    UPDATE Journal
    SET journal_teacher = COALESCE(p_journal_teacher, journal_teacher),
        journal_name = COALESCE(p_journal_name, journal_name)
    WHERE journal_id = p_journal_id;

    CALL proc_create_audit_log('Journal', 'UPDATE', p_journal_id::TEXT, 'Updated journal ' || p_journal_id);
END;
$$;


ALTER PROCEDURE public.proc_update_journal(IN p_journal_id integer, IN p_journal_teacher integer, IN p_journal_name character varying) OWNER TO postgres;

--
-- Name: proc_update_lesson(integer, character varying, character varying, integer, integer, integer, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_lesson(IN p_lesson_id integer, IN p_name character varying DEFAULT NULL::character varying, IN p_class character varying DEFAULT NULL::character varying, IN p_subject integer DEFAULT NULL::integer, IN p_material integer DEFAULT NULL::integer, IN p_teacher integer DEFAULT NULL::integer, IN p_date timestamp without time zone DEFAULT NULL::date)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_lessons WHERE lesson_id = p_lesson_id
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');

    IF p_material = 0 THEN
        p_material := NULL;
    END IF;

    IF p_teacher IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_teachers WHERE teacher_id = p_teacher
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_teacher
        USING ERRCODE = '22003';
    END IF;

    IF p_class IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM vws_classes WHERE class_name = p_class
        ) THEN
            RAISE EXCEPTION 'Class % does not exist', p_class
            USING ERRCODE = '22003';
        END IF;

        IF p_class !~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$' THEN
            RAISE EXCEPTION 'Invalid class format: %', p_class
            USING ERRCODE = '23514';
        END IF;
    END IF;

    IF p_subject IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_subjects WHERE subject_id = p_subject
    ) THEN
        RAISE EXCEPTION 'Subject % does not exist', p_subject
        USING ERRCODE = '22003';
    END IF;

    UPDATE lessons
    SET
        lesson_name     = COALESCE(p_name, lesson_name),
        lesson_class    = COALESCE(p_class, lesson_class),
        lesson_subject  = COALESCE(p_subject, lesson_subject),
        lesson_material = COALESCE(p_material, lesson_material),
        lesson_teacher  = COALESCE(p_teacher, lesson_teacher),
        lesson_date     = COALESCE(p_date, lesson_date)
    WHERE lesson_id = p_lesson_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Lessons', 'UPDATE', p_lesson_id::text, SESSION_USER, 'Updated lesson');
END;
$_$;


ALTER PROCEDURE public.proc_update_lesson(IN p_lesson_id integer, IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone) OWNER TO postgres;

--
-- Name: proc_update_material(integer, character varying, text, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_material(IN p_id integer, IN p_name character varying, IN p_desc text, IN p_link text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
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
		material_desc	= COALESCE(p_desc, material_desc),
		material_link	= COALESCE(p_link, material_link)
	WHERE material_id = p_id;

    CALL proc_create_audit_log('Material', 'UPDATE', p_id::text, 'Updated material');
END;
$$;


ALTER PROCEDURE public.proc_update_material(IN p_id integer, IN p_name character varying, IN p_desc text, IN p_link text) OWNER TO postgres;

--
-- Name: proc_update_parent(integer, character varying, character varying, character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_parent(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_parents WHERE parent_id = p_id
    ) THEN
        RAISE EXCEPTION 'Parent % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    UPDATE parents
    SET
        parent_name      = COALESCE(p_name, parent_name),
        parent_surname   = COALESCE(p_surname, parent_surname),
        parent_patronym  = COALESCE(p_patronym, parent_patronym),
        parent_phone     = COALESCE(p_phone, parent_phone),
        parent_user_id   = COALESCE(p_user_id, parent_user_id)
    WHERE parent_id = p_id;

    CALL proc_create_audit_log('Parents', 'UPDATE', p_id::text, 'Updated parent');
END;
$$;


ALTER PROCEDURE public.proc_update_parent(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer) OWNER TO postgres;

--
-- Name: proc_update_role(integer, character varying, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_role(IN p_role_id integer, IN p_role_name character varying, IN p_role_desc text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_id = p_role_id) THEN
        RAISE EXCEPTION 'Role with ID % does not exist', p_role_id;
    END IF;

    UPDATE Roles
    SET role_name = COALESCE(p_role_name, role_name),
        role_desc = COALESCE(p_role_desc, role_desc)
    WHERE role_id = p_role_id;

    CALL proc_create_audit_log('Roles', 'UPDATE', p_role_id::TEXT, 'Updated role ' || p_role_id);
END;
$$;


ALTER PROCEDURE public.proc_update_role(IN p_role_id integer, IN p_role_name character varying, IN p_role_desc text) OWNER TO postgres;

--
-- Name: proc_update_student(integer, character varying, character varying, character varying, character varying, integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_student(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_students WHERE student_id = p_id
    ) THEN
        RAISE EXCEPTION 'Student % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_class IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_classes WHERE class_name = p_class
    ) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class
        USING ERRCODE = '22003';
    END IF;

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    UPDATE students
    SET
        student_name       = COALESCE(p_name, student_name),
        student_surname    = COALESCE(p_surname, student_surname),
        student_patronym   = COALESCE(p_patronym, student_patronym),
        student_phone      = COALESCE(p_phone, student_phone),
        student_user_id    = COALESCE(p_user_id, student_user_id),
        student_class      = COALESCE(p_class, student_class)
    WHERE student_id = p_id;

    CALL proc_create_audit_log('Students', 'UPDATE', p_id::text, 'Updated student');
END;
$$;


ALTER PROCEDURE public.proc_update_student(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying) OWNER TO postgres;

--
-- Name: proc_update_studentdata(integer, integer, integer, integer, smallint, public.journal_status_enum, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_studentdata(IN p_id integer, IN p_journal_id integer DEFAULT NULL::integer, IN p_student_id integer DEFAULT NULL::integer, IN p_lesson integer DEFAULT NULL::integer, IN p_mark smallint DEFAULT NULL::smallint, IN p_status public.journal_status_enum DEFAULT NULL::public.journal_status_enum, IN p_note text DEFAULT NULL::text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_student_data WHERE data_id = p_id
    ) THEN
        RAISE EXCEPTION 'Studentdata % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_note := NULLIF(trim(p_note), '');

    IF p_journal_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_journals WHERE journal_id = p_journal_id
    ) THEN
        RAISE EXCEPTION 'Journal % does not exist', p_journal_id
        USING ERRCODE = '22003';
    END IF;

    IF p_student_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_students WHERE student_id = p_student_id
    ) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id
        USING ERRCODE = '22003';
    END IF;

    IF p_lesson IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_lessons WHERE lesson_id = p_lesson
    ) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_lesson
        USING ERRCODE = '22003';
    END IF;

    IF p_mark IS NOT NULL AND (p_mark < 1 OR p_mark > 12) THEN
        RAISE EXCEPTION 'Mark % is out of range (1–12)', p_mark
        USING ERRCODE = '22003';
    END IF;

    UPDATE studentdata
    SET
        journal_id = COALESCE(p_journal_id, journal_id),
        student_id = COALESCE(p_student_id, student_id),
        lesson     = COALESCE(p_lesson, lesson),
        mark       = COALESCE(p_mark, mark),
        status     = COALESCE(p_status, status),
        note       = COALESCE(p_note, note)
    WHERE data_id = p_id;

    CALL proc_create_audit_log('StudentData', 'UPDATE', p_id::text, 'Updated student data');
END;
$$;


ALTER PROCEDURE public.proc_update_studentdata(IN p_id integer, IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, IN p_note text) OWNER TO postgres;

--
-- Name: proc_update_subject(integer, text, integer, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_subject(IN p_subject_id integer, IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Subjects WHERE subject_id = p_subject_id) THEN
        RAISE EXCEPTION 'Subject with ID % does not exist', p_subject_id;
    END IF;

    UPDATE Subjects
    SET subject_name = COALESCE(p_subject_name, subject_name),
        cabinet = COALESCE(p_cabinet, cabinet),
        subject_program = COALESCE(p_subject_program, subject_program)
    WHERE subject_id = p_subject_id;

    CALL proc_create_audit_log('Subjects', 'UPDATE', p_subject_id::TEXT, 'Updated subject ' || p_subject_id);
END;
$$;


ALTER PROCEDURE public.proc_update_subject(IN p_subject_id integer, IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text) OWNER TO postgres;

--
-- Name: proc_update_teacher(integer, character varying, character varying, character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_teacher(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_teachers WHERE teacher_id = p_id
    ) THEN
        RAISE EXCEPTION 'Teacher % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_name := NULLIF(trim(p_name), '');
    p_surname := NULLIF(trim(p_surname), '');
    p_patronym := NULLIF(trim(p_patronym), '');
    p_phone := NULLIF(trim(p_phone), '');

    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
        USING ERRCODE = '22003';
    END IF;

    UPDATE teacher
    SET
        teacher_name     = COALESCE(p_name, teacher_name),
        teacher_surname  = COALESCE(p_surname, teacher_surname),
        teacher_patronym = COALESCE(p_patronym, teacher_patronym),
        teacher_phone    = COALESCE(p_phone, teacher_phone),
        teacher_user_id  = COALESCE(p_user_id, teacher_user_id)
    WHERE teacher_id = p_id;

    CALL proc_create_audit_log('Teacher', 'UPDATE', p_id::text, 'Updated teacher');
END;
$$;


ALTER PROCEDURE public.proc_update_teacher(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer) OWNER TO postgres;

--
-- Name: proc_update_timetable(integer, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_timetable(IN p_timetable_id integer, IN p_timetable_name character varying, IN p_timetable_class character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Timetable WHERE timetable_id = p_timetable_id) THEN
        RAISE EXCEPTION 'Timetable with ID % does not exist', p_timetable_id;
    END IF;

    UPDATE Timetable
    SET timetable_name = COALESCE(p_timetable_name, timetable_name),
        timetable_class = COALESCE(p_timetable_class, timetable_class)
    WHERE timetable_id = p_timetable_id;

    CALL proc_create_audit_log('Timetable', 'UPDATE', p_timetable_id::TEXT, 'Updated timetable ' || p_timetable_id);
END;
$$;


ALTER PROCEDURE public.proc_update_timetable(IN p_timetable_id integer, IN p_timetable_name character varying, IN p_timetable_class character varying) OWNER TO postgres;

--
-- Name: proc_update_user(integer, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.proc_update_user(IN p_id integer, IN p_username character varying DEFAULT NULL::character varying, IN p_email character varying DEFAULT NULL::character varying, IN p_password character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vws_users WHERE user_id = p_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_id
        USING ERRCODE = 'P0002';
    END IF;

    p_username := NULLIF(trim(p_username), '');
    p_email := NULLIF(trim(p_email), '');
    p_password := NULLIF(trim(p_password), '');

    IF p_username IS NOT NULL AND EXISTS (
        SELECT 1 FROM vws_users WHERE username = p_username AND user_id <> p_id
    ) THEN
        RAISE EXCEPTION 'Username % already exists', p_username
        USING ERRCODE = '23505';
    END IF;

    IF p_email IS NOT NULL AND EXISTS (
        SELECT 1 FROM vws_users WHERE email = p_email AND user_id <> p_id
    ) THEN
        RAISE EXCEPTION 'Email % already exists', p_email
        USING ERRCODE = '23505';
    END IF;

    UPDATE users
    SET
        username = COALESCE(p_username, username),
        email    = COALESCE(p_email, email)
    WHERE user_id = p_id;

    IF p_password IS NOT NULL THEN
	    CALL proc_reset_user_password(p_id::integer, p_password::varchar);
	END IF;

    CALL proc_create_audit_log('Users', 'UPDATE', p_id::text, 'Updated user');
END;
$$;


ALTER PROCEDURE public.proc_update_user(IN p_id integer, IN p_username character varying, IN p_email character varying, IN p_password character varying) OWNER TO postgres;

--
-- Name: student_attendance_report(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.student_attendance_report(p_student_id integer, p_from date DEFAULT CURRENT_DATE, p_to date DEFAULT ((CURRENT_DATE + '7 days'::interval))::date) RETURNS TABLE(present integer, absent integer, present_percent numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    total INT;
BEGIN
    SELECT COUNT(*)::INT
    INTO total
    FROM StudentData sd
    JOIN Lessons l ON l.lesson_id = sd.lesson
    WHERE sd.student_id = p_student_id
      AND l.lesson_date BETWEEN p_from AND p_to;

    IF total = 0 THEN
        RETURN QUERY SELECT 0, 0, (0)::numeric;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE sd.status IN ('П','Присутній'))::INT,
        COUNT(*) FILTER (WHERE sd.status IN ('Н','Не присутній'))::INT,
        ROUND(
            (COUNT(*) FILTER (WHERE sd.status IN ('П','Присутній'))::NUMERIC / total) * 100,
            2
        )
    FROM StudentData sd
    JOIN Lessons l ON l.lesson_id = sd.lesson
    WHERE sd.student_id = p_student_id
      AND l.lesson_date BETWEEN p_from AND p_to;
END;
$$;


ALTER FUNCTION public.student_attendance_report(p_student_id integer, p_from date, p_to date) OWNER TO postgres;

--
-- Name: student_day_plan(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.student_day_plan(p_student_id integer, p_date date) RETURNS TABLE(lesson character varying, mark smallint, homework text)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
	SELECT l.lesson_name, sd.mark, h.homework_desc
	FROM Students s
	JOIN Lessons l ON l.lesson_class = s.student_class
	LEFT JOIN StudentData sd ON sd.student_id = s.student_id
	LEFT JOIN Homework h ON h.homework_class = s.student_class
	WHERE s.student_id = p_student_id
	AND l.lesson_date = p_date;
$$;


ALTER FUNCTION public.student_day_plan(p_student_id integer, p_date date) OWNER TO postgres;

--
-- Name: translit_uk_to_lat(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.translit_uk_to_lat(p_text text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    t TEXT;
BEGIN
    t := lower(p_text);

    -- Multi-letter replacements first
    t := replace(t, 'щ', 'shch');
    t := replace(t, 'ж', 'zh');
    t := replace(t, 'ч', 'ch');
    t := replace(t, 'ш', 'sh');
    t := replace(t, 'ю', 'yu');
    t := replace(t, 'я', 'ya');
    t := replace(t, 'є', 'ye');
    t := replace(t, 'ї', 'yi');
    t := replace(t, 'х', 'kh');
    t := replace(t, 'ц', 'ts');

    -- Single-letter mapping
    t := translate(
        t,
        'абвгґдеиіїйклмнопрстуфзь',
        'abvhgdeyiyiklmnoprstufz'
    );

    RETURN t;
END;
$$;


ALTER FUNCTION public.translit_uk_to_lat(p_text text) OWNER TO postgres;

--
-- Name: trg_check_timetable_conflict(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_check_timetable_conflict() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM lessons l
        WHERE
            l.lesson_date = NEW.lesson_date
            AND (
                l.lesson_teacher = NEW.lesson_teacher
                OR l.lesson_class = NEW.lesson_class
            )
            -- avoid self-conflict on UPDATE
            AND l.lesson_id <> COALESCE(NEW.lesson_id, -1)
    ) THEN
        RAISE EXCEPTION
            'Schedule conflict: teacher or class already occupied at this exact time';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_check_timetable_conflict() OWNER TO postgres;

--
-- Name: trg_prevent_fast_double_mark(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_prevent_fast_double_mark() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM StudentData
        WHERE student_id = NEW.student_id
          AND lesson = NEW.lesson
          AND created_at > CURRENT_TIMESTAMP - INTERVAL '1 minute'
    ) THEN
        RAISE EXCEPTION 'Mark already added less than a minute ago';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_prevent_fast_double_mark() OWNER TO postgres;

--
-- Name: trg_unique_user_fields(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_unique_user_fields() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
	    IF EXISTS (
	        SELECT 1 FROM Users
	        WHERE email = NEW.email
	           OR username = NEW.username
	    ) THEN
	        RAISE EXCEPTION 'Duplicate email or username';
	    END IF;
	
	    RETURN NEW;
	END;
$$;


ALTER FUNCTION public.trg_unique_user_fields() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auditlog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditlog (
    log_id integer NOT NULL,
    table_name character varying(50) NOT NULL,
    operation character varying(20) NOT NULL,
    record_id text,
    changed_by character varying(50) DEFAULT CURRENT_ROLE,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    details text
);


ALTER TABLE public.auditlog OWNER TO postgres;

--
-- Name: auditlog_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auditlog ALTER COLUMN log_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auditlog_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.class (
    class_name character varying(10) NOT NULL,
    class_journal_id integer NOT NULL,
    class_mainteacher integer NOT NULL,
    CONSTRAINT class_class_name_check CHECK (((class_name)::text ~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$'::text))
);


ALTER TABLE public.class OWNER TO postgres;

--
-- Name: days; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.days (
    day_id integer NOT NULL,
    day_subject integer NOT NULL,
    day_time time without time zone NOT NULL,
    day_weekday character varying(20),
    day_timetable integer NOT NULL,
    CONSTRAINT days_day_weekday_check CHECK (((day_weekday)::text = ANY (ARRAY[('Понеділок'::character varying)::text, ('Вівторок'::character varying)::text, ('Середа'::character varying)::text, ('Четвер'::character varying)::text, ('П’ятниця'::character varying)::text])))
);


ALTER TABLE public.days OWNER TO postgres;

--
-- Name: days_day_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.days ALTER COLUMN day_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.days_day_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: homework; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.homework (
    homework_id integer NOT NULL,
    homework_name character varying(100),
    homework_teacher integer NOT NULL,
    homework_lesson integer NOT NULL,
    homework_duedate date NOT NULL,
    homework_created_at date DEFAULT CURRENT_DATE NOT NULL,
    homework_desc text NOT NULL,
    homework_class character varying(10) NOT NULL,
    CONSTRAINT homework_homework_class_check CHECK (((homework_class)::text ~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$'::text))
);


ALTER TABLE public.homework OWNER TO postgres;

--
-- Name: homework_homework_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.homework ALTER COLUMN homework_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.homework_homework_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: journal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.journal (
    journal_id integer NOT NULL,
    journal_teacher integer,
    journal_name character varying(50)
);


ALTER TABLE public.journal OWNER TO postgres;

--
-- Name: journal_journal_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.journal ALTER COLUMN journal_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.journal_journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: lessons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lessons (
    lesson_id integer NOT NULL,
    lesson_name character varying(50),
    lesson_class character varying(10) NOT NULL,
    lesson_subject integer NOT NULL,
    lesson_material integer,
    lesson_teacher integer NOT NULL,
    lesson_date timestamp without time zone NOT NULL,
    CONSTRAINT lessons_lesson_class_check CHECK (((lesson_class)::text ~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$'::text))
);


ALTER TABLE public.lessons OWNER TO postgres;

--
-- Name: lessons_lesson_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.lessons ALTER COLUMN lesson_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.lessons_lesson_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: material; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material (
    material_id integer NOT NULL,
    material_name character varying(100) NOT NULL,
    material_desc text,
    material_link text
);


ALTER TABLE public.material OWNER TO postgres;

--
-- Name: material_material_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.material ALTER COLUMN material_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.material_material_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: parents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parents (
    parent_id integer NOT NULL,
    parent_name character varying(50) NOT NULL,
    parent_surname character varying(50) NOT NULL,
    parent_patronym character varying(50),
    parent_phone character varying(20) NOT NULL,
    parent_user_id integer
);


ALTER TABLE public.parents OWNER TO postgres;

--
-- Name: parents_parent_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.parents ALTER COLUMN parent_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.parents_parent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role_name character varying(10) NOT NULL,
    role_desc text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.roles ALTER COLUMN role_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.roles_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: studentdata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.studentdata (
    data_id integer NOT NULL,
    journal_id integer NOT NULL,
    student_id integer NOT NULL,
    lesson integer NOT NULL,
    mark smallint,
    status public.journal_status_enum NOT NULL,
    note text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT studentdata_mark_check CHECK (((mark >= 1) AND (mark <= 12)))
);


ALTER TABLE public.studentdata OWNER TO postgres;

--
-- Name: studentdata_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.studentdata ALTER COLUMN data_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.studentdata_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: studentparent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.studentparent (
    student_id_ref integer NOT NULL,
    parent_id_ref integer NOT NULL
);


ALTER TABLE public.studentparent OWNER TO postgres;

--
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    student_id integer NOT NULL,
    student_name character varying(50) NOT NULL,
    student_surname character varying(50) NOT NULL,
    student_patronym character varying(50),
    student_phone character varying(20) NOT NULL,
    student_user_id integer,
    student_class character varying(10) NOT NULL,
    CONSTRAINT students_student_phone_check CHECK (((student_phone)::text ~ '^0[3-9]\d{1}-\d{3}-\d{4}$'::text))
);


ALTER TABLE public.students OWNER TO postgres;

--
-- Name: students_student_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.students ALTER COLUMN student_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.students_student_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subjects (
    subject_id integer NOT NULL,
    subject_name text NOT NULL,
    subject_program text,
    cabinet integer DEFAULT 100 NOT NULL,
    CONSTRAINT subjects_cabinet_check CHECK (((cabinet > 99) AND (cabinet < 399)))
);


ALTER TABLE public.subjects OWNER TO postgres;

--
-- Name: subjects_subject_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.subjects ALTER COLUMN subject_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.subjects_subject_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: teacher; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher (
    teacher_id integer NOT NULL,
    teacher_name character varying(50) NOT NULL,
    teacher_surname character varying(50) NOT NULL,
    teacher_patronym character varying(50),
    teacher_phone character varying(20) NOT NULL,
    teacher_user_id integer,
    CONSTRAINT teacher_teacher_phone_check CHECK (((teacher_phone)::text ~ '^0[3-9]\d{1}-\d{3}-\d{4}$'::text))
);


ALTER TABLE public.teacher OWNER TO postgres;

--
-- Name: teacher_teacher_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.teacher ALTER COLUMN teacher_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.teacher_teacher_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: timetable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.timetable (
    timetable_id integer NOT NULL,
    timetable_name character varying(20),
    timetable_class character varying(10) NOT NULL,
    CONSTRAINT timetable_timetable_class_check CHECK (((timetable_class)::text ~ '^(?:[1-9]|1[0-2])-([А-ЩЬЮЯҐЄІЇ]|[а-щьюяґєії])$'::text))
);


ALTER TABLE public.timetable OWNER TO postgres;

--
-- Name: timetable_timetable_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.timetable ALTER COLUMN timetable_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.timetable_timetable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: userrole; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.userrole (
    user_id integer NOT NULL,
    role_id integer NOT NULL
);


ALTER TABLE public.userrole OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(60) NOT NULL,
    password text NOT NULL,
    CONSTRAINT users_email_check CHECK (((email)::text ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'::text))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.users ALTER COLUMN user_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: vw_class_attendance_last_month; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_class_attendance_last_month AS
 SELECT s.student_class,
    round((((count(*) FILTER (WHERE (sd.status = ANY (ARRAY['П'::public.journal_status_enum, 'Присутній'::public.journal_status_enum]))))::numeric / (count(*))::numeric) * (100)::numeric), 2) AS attendance_percent
   FROM ((public.students s
     JOIN public.studentdata sd ON ((sd.student_id = s.student_id)))
     JOIN public.lessons l ON ((l.lesson_id = sd.lesson)))
  WHERE ((l.lesson_date >= date_trunc('month'::text, (CURRENT_DATE - '1 mon'::interval))) AND (l.lesson_date < date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))
  GROUP BY s.student_class;


ALTER VIEW public.vw_class_attendance_last_month OWNER TO postgres;

--
-- Name: vw_class_ranking; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_class_ranking AS
 SELECT s.student_class,
    count(DISTINCT s.student_id) AS students_count,
    round(avg(sd.mark), 2) AS avg_mark,
    rank() OVER (ORDER BY (avg(sd.mark)) DESC) AS rank_position
   FROM ((public.students s
     JOIN public.studentdata sd ON ((sd.student_id = s.student_id)))
     JOIN public.lessons l ON ((l.lesson_id = sd.lesson)))
  WHERE ((sd.mark IS NOT NULL) AND ((l.lesson_date >= '2025-09-01 00:00:00'::timestamp without time zone) AND (l.lesson_date <= '2026-06-30 00:00:00'::timestamp without time zone)))
  GROUP BY s.student_class;


ALTER VIEW public.vw_class_ranking OWNER TO postgres;

--
-- Name: vw_homework_by_student_or_class; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_homework_by_student_or_class AS
 SELECT s.student_id,
    sj.subject_name,
    h.homework_name,
    h.homework_desc,
    h.homework_id,
    h.homework_lesson,
    h.homework_duedate
   FROM (((public.students s
     JOIN public.homework h ON (((h.homework_class)::text = (s.student_class)::text)))
     JOIN public.lessons l ON ((h.homework_lesson = l.lesson_id)))
     JOIN public.subjects sj ON ((l.lesson_subject = sj.subject_id)));


ALTER VIEW public.vw_homework_by_student_or_class OWNER TO postgres;

--
-- Name: vw_homework_tomorrow; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_homework_tomorrow AS
 SELECT homework_id,
    homework_name,
    homework_desc,
    homework_class
   FROM public.homework
  WHERE (homework_duedate = (CURRENT_DATE + '1 day'::interval));


ALTER VIEW public.vw_homework_tomorrow OWNER TO postgres;

--
-- Name: vw_student_perfomance_matrix; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_student_perfomance_matrix AS
 WITH academicstats AS (
         SELECT sd.student_id,
            count(sd.mark) AS count_marks,
            round(avg(sd.mark), 2) AS avg_grade,
            count(
                CASE
                    WHEN ((sd.mark >= 1) AND (sd.mark <= 3)) THEN 1
                    ELSE NULL::integer
                END) AS count_failures,
            max(l.lesson_date) AS last_graded_date
           FROM (public.studentdata sd
             JOIN public.lessons l ON ((sd.lesson = l.lesson_id)))
          WHERE (sd.mark IS NOT NULL)
          GROUP BY sd.student_id
        ), attendancestats AS (
         SELECT sd.student_id,
            count(*) AS total_entries,
            count(
                CASE
                    WHEN (sd.status = ANY (ARRAY['Не присутній'::public.journal_status_enum, 'Н'::public.journal_status_enum])) THEN 1
                    ELSE NULL::integer
                END) AS count_absences,
            max(l.lesson_date) AS last_seen_date
           FROM (public.studentdata sd
             JOIN public.lessons l ON ((sd.lesson = l.lesson_id)))
          GROUP BY sd.student_id
        )
 SELECT s.student_id,
    (((((s.student_name)::text || ' '::text) || (s.student_surname)::text) || ' '::text) || (s.student_patronym)::text) AS student_full_name,
    s.student_class,
    COALESCE(acad.avg_grade, (0)::numeric) AS gpa,
    COALESCE(acad.count_marks, (0)::bigint) AS total_marks_received,
    COALESCE(acad.count_failures, (0)::bigint) AS total_failed_marks,
    COALESCE(att.count_absences, (0)::bigint) AS total_absences,
        CASE
            WHEN (COALESCE(att.total_entries, (0)::bigint) = 0) THEN (0)::numeric
            ELSE round((((COALESCE(att.count_absences, (0)::bigint))::numeric / (att.total_entries)::numeric) * (100)::numeric), 1)
        END AS absence_percentage,
    GREATEST(acad.last_graded_date, att.last_seen_date) AS last_activity_date,
        CASE
            WHEN (GREATEST(acad.last_graded_date, att.last_seen_date) IS NOT NULL) THEN ((CURRENT_DATE)::timestamp without time zone - GREATEST(acad.last_graded_date, att.last_seen_date))
            ELSE NULL::interval
        END AS days_since_last_activity,
        CASE
            WHEN (((COALESCE(acad.avg_grade, (0)::numeric) > (0)::numeric) AND (acad.avg_grade < (4)::numeric)) OR (
            CASE
                WHEN (att.total_entries > 0) THEN ((att.count_absences)::numeric / (att.total_entries)::numeric)
                ELSE (0)::numeric
            END > 0.30)) THEN 'В зоні ризику'::text
            WHEN ((acad.avg_grade >= (10)::numeric) AND (COALESCE(att.count_absences, (0)::bigint) < 3)) THEN 'Відмінник'::text
            WHEN (acad.avg_grade >= (7)::numeric) THEN 'Хорошист'::text
            WHEN ((acad.avg_grade IS NULL) AND (att.total_entries IS NULL)) THEN 'Новий/Без активності'::text
            ELSE 'Середній рівень'::text
        END AS student_status_tier
   FROM ((public.students s
     LEFT JOIN academicstats acad ON ((s.student_id = acad.student_id)))
     LEFT JOIN attendancestats att ON ((s.student_id = att.student_id)))
  ORDER BY s.student_class, COALESCE(acad.avg_grade, (0)::numeric) DESC;


ALTER VIEW public.vw_student_perfomance_matrix OWNER TO postgres;

--
-- Name: vw_student_ranking; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_student_ranking AS
SELECT
    NULL::integer AS student_id,
    NULL::character varying(50) AS student_name,
    NULL::character varying(50) AS student_surname,
    NULL::character varying(10) AS student_class,
    NULL::numeric AS avg_mark,
    NULL::bigint AS class_rank;


ALTER VIEW public.vw_student_ranking OWNER TO postgres;

--
-- Name: vw_students_avg_above_7; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_students_avg_above_7 AS
 SELECT s.student_id,
    avg(sd.mark) AS avg_mark
   FROM (public.students s
     JOIN public.studentdata sd ON ((s.student_id = sd.student_id)))
  GROUP BY s.student_id
 HAVING (avg(sd.mark) > (7)::numeric);


ALTER VIEW public.vw_students_avg_above_7 OWNER TO postgres;

--
-- Name: vw_students_by_class; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_students_by_class AS
 SELECT student_id,
    student_name,
    student_surname,
    student_class
   FROM public.students;


ALTER VIEW public.vw_students_by_class OWNER TO postgres;

--
-- Name: vw_teacher_analytics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_teacher_analytics AS
 WITH lessoncounts AS (
         SELECT lessons.lesson_teacher,
            count(*) AS lessons_conducted,
            max(lessons.lesson_date) AS last_lesson
           FROM public.lessons
          GROUP BY lessons.lesson_teacher
        ), gradingstats AS (
         SELECT l.lesson_teacher,
            count(sd.mark) AS marks_given,
            round(avg(sd.mark), 2) AS avg_mark_given
           FROM (public.studentdata sd
             JOIN public.lessons l ON ((sd.lesson = l.lesson_id)))
          GROUP BY l.lesson_teacher
        )
 SELECT t.teacher_surname,
    t.teacher_name,
    t.teacher_patronym,
    sub.subject_name,
    COALESCE(lc.lessons_conducted, (0)::bigint) AS total_lessons,
    COALESCE(gs.marks_given, (0)::bigint) AS total_marks_assigned,
    gs.avg_mark_given AS strictness_factor,
    ((CURRENT_DATE)::timestamp without time zone - lc.last_lesson) AS days_since_last_lesson
   FROM (((public.teacher t
     LEFT JOIN lessoncounts lc ON ((t.teacher_id = lc.lesson_teacher)))
     LEFT JOIN gradingstats gs ON ((t.teacher_id = gs.lesson_teacher)))
     LEFT JOIN public.subjects sub ON ((t.teacher_id = ( SELECT lessons.lesson_teacher
           FROM public.lessons
          WHERE (lessons.lesson_teacher = t.teacher_id)
         LIMIT 1))));


ALTER VIEW public.vw_teacher_analytics OWNER TO postgres;

--
-- Name: vw_teacher_class_students; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_teacher_class_students AS
 SELECT c.class_mainteacher,
    c.class_name,
    s.student_name,
    s.student_surname,
    s.student_id
   FROM ((public.class c
     JOIN public.teacher t ON ((c.class_mainteacher = t.teacher_id)))
     LEFT JOIN public.students s ON (((s.student_class)::text = (c.class_name)::text)))
  ORDER BY c.class_name, s.student_surname, s.student_name;


ALTER VIEW public.vw_teacher_class_students OWNER TO postgres;

--
-- Name: vw_teachers_with_classes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_teachers_with_classes AS
 SELECT t.teacher_name,
    c.class_name
   FROM (public.teacher t
     JOIN public.class c ON ((c.class_mainteacher = t.teacher_id)));


ALTER VIEW public.vw_teachers_with_classes OWNER TO postgres;

--
-- Name: vw_view_timetable_week; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_view_timetable_week AS
 SELECT tt.timetable_id,
    tt.timetable_class AS class_name,
    d.day_weekday AS weekday,
    d.day_time AS lesson_time,
    s.subject_name AS subject,
    s.cabinet
   FROM ((public.timetable tt
     JOIN public.days d ON ((d.day_timetable = tt.timetable_id)))
     JOIN public.subjects s ON ((d.day_subject = s.subject_id)))
  ORDER BY tt.timetable_class,
        CASE d.day_weekday
            WHEN 'Понеділок'::text THEN 1
            WHEN 'Вівторок'::text THEN 2
            WHEN 'Середа'::text THEN 3
            WHEN 'Четвер'::text THEN 4
            WHEN 'П’ятниця'::text THEN 5
            ELSE NULL::integer
        END, d.day_time;


ALTER VIEW public.vw_view_timetable_week OWNER TO postgres;

--
-- Name: vws_audits; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_audits AS
 SELECT log_id,
    table_name,
    operation,
    record_id,
    changed_by,
    changed_at,
    details
   FROM public.auditlog;


ALTER VIEW public.vws_audits OWNER TO postgres;

--
-- Name: vws_class_schedule; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_class_schedule AS
 SELECT t.timetable_name,
    t.timetable_class,
    d.day_weekday,
    d.day_time,
    s.subject_name,
    s.cabinet,
    te.teacher_surname AS main_teacher
   FROM ((((public.timetable t
     JOIN public.days d ON ((t.timetable_id = d.day_timetable)))
     JOIN public.subjects s ON ((d.day_subject = s.subject_id)))
     LEFT JOIN public.class c ON (((t.timetable_class)::text = (c.class_name)::text)))
     LEFT JOIN public.teacher te ON ((c.class_mainteacher = te.teacher_id)))
  ORDER BY t.timetable_class,
        CASE d.day_weekday
            WHEN 'Понеділок'::text THEN 1
            WHEN 'Вівторок'::text THEN 2
            WHEN 'Середа'::text THEN 3
            WHEN 'Четвер'::text THEN 4
            WHEN 'П’ятниця'::text THEN 5
            ELSE NULL::integer
        END, d.day_time;


ALTER VIEW public.vws_class_schedule OWNER TO postgres;

--
-- Name: vws_classes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_classes AS
 SELECT class_name,
    class_journal_id,
    class_mainteacher
   FROM public.class;


ALTER VIEW public.vws_classes OWNER TO postgres;

--
-- Name: vws_days; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_days AS
 SELECT day_id,
    day_subject,
    day_time,
    day_weekday,
    day_timetable
   FROM public.days;


ALTER VIEW public.vws_days OWNER TO postgres;

--
-- Name: vws_full_journal; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_full_journal AS
 SELECT sd.data_id,
    j.journal_name,
    cl.class_name,
    sub.subject_name,
    l.lesson_date,
    l.lesson_name,
    s.student_id,
    (((((s.student_name)::text || ' '::text) || (s.student_surname)::text) || ' '::text) || (s.student_patronym)::text) AS student_full_name,
    sd.mark,
    sd.status,
    sd.note,
    (((t.teacher_name)::text || ' '::text) || (t.teacher_surname)::text) AS teacher
   FROM ((((((public.studentdata sd
     JOIN public.journal j ON ((sd.journal_id = j.journal_id)))
     JOIN public.lessons l ON ((sd.lesson = l.lesson_id)))
     JOIN public.subjects sub ON ((l.lesson_subject = sub.subject_id)))
     JOIN public.students s ON ((sd.student_id = s.student_id)))
     JOIN public.class cl ON (((s.student_class)::text = (cl.class_name)::text)))
     JOIN public.teacher t ON ((l.lesson_teacher = t.teacher_id)));


ALTER VIEW public.vws_full_journal OWNER TO postgres;

--
-- Name: vws_homeworks; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_homeworks AS
 SELECT homework_id,
    homework_name,
    homework_teacher,
    homework_lesson,
    homework_duedate,
    homework_created_at,
    homework_desc,
    homework_class
   FROM public.homework;


ALTER VIEW public.vws_homeworks OWNER TO postgres;

--
-- Name: vws_journals; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_journals AS
 SELECT journal_id,
    journal_teacher,
    journal_name
   FROM public.journal;


ALTER VIEW public.vws_journals OWNER TO postgres;

--
-- Name: vws_lessons; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_lessons AS
 SELECT lesson_id,
    lesson_name,
    lesson_class,
    lesson_subject,
    lesson_material,
    lesson_teacher,
    (lesson_date)::timestamp with time zone AS lesson_date
   FROM public.lessons;


ALTER VIEW public.vws_lessons OWNER TO postgres;

--
-- Name: vws_materials; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_materials AS
 SELECT material_id,
    material_name,
    material_desc,
    material_link
   FROM public.material;


ALTER VIEW public.vws_materials OWNER TO postgres;

--
-- Name: vws_parents; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_parents AS
 SELECT parent_id,
    parent_name,
    parent_surname,
    parent_patronym,
    parent_phone,
    parent_user_id
   FROM public.parents;


ALTER VIEW public.vws_parents OWNER TO postgres;

--
-- Name: vws_roles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_roles AS
 SELECT role_id,
    role_name,
    role_desc
   FROM public.roles;


ALTER VIEW public.vws_roles OWNER TO postgres;

--
-- Name: vws_student_data; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_student_data AS
 SELECT data_id,
    journal_id,
    student_id,
    lesson,
    mark,
    status,
    note,
    created_at
   FROM public.studentdata;


ALTER VIEW public.vws_student_data OWNER TO postgres;

--
-- Name: vws_student_parents; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_student_parents AS
 SELECT student_id_ref,
    parent_id_ref
   FROM public.studentparent;


ALTER VIEW public.vws_student_parents OWNER TO postgres;

--
-- Name: vws_student_profile; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_student_profile AS
 SELECT s.student_id,
    s.student_name,
    s.student_surname,
    s.student_patronym,
    s.student_class,
    s.student_phone,
    u.email,
    u.username
   FROM (public.students s
     LEFT JOIN public.users u ON ((s.student_user_id = u.user_id)));


ALTER VIEW public.vws_student_profile OWNER TO postgres;

--
-- Name: vws_students; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_students AS
 SELECT student_id,
    student_name,
    student_surname,
    student_patronym,
    student_phone,
    student_user_id,
    student_class
   FROM public.students;


ALTER VIEW public.vws_students OWNER TO postgres;

--
-- Name: vws_subjects; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_subjects AS
 SELECT subject_id,
    subject_name,
    subject_program,
    cabinet
   FROM public.subjects;


ALTER VIEW public.vws_subjects OWNER TO postgres;

--
-- Name: vws_teacher_profile; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_teacher_profile AS
SELECT
    NULL::integer AS teacher_id,
    NULL::character varying(50) AS teacher_name,
    NULL::character varying(50) AS teacher_surname,
    NULL::character varying(50) AS teacher_patronym,
    NULL::character varying(20) AS teacher_phone,
    NULL::character varying(60) AS email,
    NULL::bigint AS classes_managed;


ALTER VIEW public.vws_teacher_profile OWNER TO postgres;

--
-- Name: vws_teachers; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_teachers AS
 SELECT teacher_id,
    teacher_name,
    teacher_surname,
    teacher_patronym,
    teacher_phone,
    teacher_user_id
   FROM public.teacher;


ALTER VIEW public.vws_teachers OWNER TO postgres;

--
-- Name: vws_timetables; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_timetables AS
 SELECT timetable_id,
    timetable_name,
    timetable_class
   FROM public.timetable;


ALTER VIEW public.vws_timetables OWNER TO postgres;

--
-- Name: vws_user_auth_info; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_user_auth_info AS
 SELECT user_id,
    username,
    password,
    email
   FROM public.users u;


ALTER VIEW public.vws_user_auth_info OWNER TO postgres;

--
-- Name: vws_user_roles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_user_roles AS
 SELECT user_id,
    role_id
   FROM public.userrole;


ALTER VIEW public.vws_user_roles OWNER TO postgres;

--
-- Name: vws_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vws_users AS
 SELECT user_id,
    username,
    email
   FROM public.users;


ALTER VIEW public.vws_users OWNER TO postgres;

--
-- Data for Name: auditlog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auditlog (log_id, table_name, operation, record_id, changed_by, changed_at, details) FROM stdin;
3	Users	INSERT	839	defaultuser	2026-01-10 20:43:12.824656	Created user
4	UserRole	INSERT	839,4	defaultuser	2026-01-10 20:43:12.824656	Assigned role to user
5	Student	INSERT	289	defaultuser	2026-01-10 20:43:12.824656	Created student
6	Students	UPDATE	289	defaultuser	2026-01-10 20:43:29.767465	Updated student
7	Lessons	INSERT	196	defaultuser	2026-01-11 01:48:27.040812	Created lesson
8	StudentData	INSERT	1500	defaultuser	2026-01-11 01:53:04.490861	Created student data
9	StudentData	INSERT	1501	defaultuser	2026-01-11 01:53:26.014971	Created student data
10	StudentData	INSERT	1502	defaultuser	2026-01-11 01:56:47.789403	Created student data
11	Lessons	INSERT	198	defaultuser	2026-01-11 01:57:26.153134	Created lesson
12	StudentData	INSERT	1503	defaultuser	2026-01-11 01:57:26.174678	Created student data
13	Lessons	INSERT	203	defaultuser	2026-01-11 01:59:57.506608	Created lesson
14	StudentData	INSERT	1504	defaultuser	2026-01-11 01:59:57.531988	Created student data
15	Lessons	INSERT	204	defaultuser	2026-01-11 16:42:35.6226	Created lesson
16	Lessons	UPDATE	204	defaultuser	2026-01-11 16:43:34.125062	Updated lesson
17	Lessons	INSERT	205	defaultuser	2026-01-11 16:44:20.709614	Created lesson
18	Lessons	DELETE	204	postgres	2026-01-11 17:10:28.202526	Deleted lesson
19	Lessons	UPDATE	203	defaultuser	2026-01-11 17:10:33.970624	Updated lesson
20	Lessons	INSERT	206	defaultuser	2026-01-11 17:10:45.316144	Created lesson
21	Students	UPDATE	4	postgres	2026-01-11 18:20:19.956766	Updated student
22	Students	UPDATE	4	postgres	2026-01-11 18:28:14.657708	Updated student
23	Users	INSERT	840	postgres	2026-01-11 18:28:50.705353	Created user
24	UserRole	INSERT	840,4	postgres	2026-01-11 18:28:50.705353	Assigned role to user
25	Students	INSERT	290	postgres	2026-01-11 18:28:50.705353	Created student
26	Students	UPDATE	290	postgres	2026-01-11 18:28:55.854646	Updated student
27	StudentData	INSERT	1506	postgres	2026-01-11 18:59:58.648905	Created student data
28	Homework	INSERT	127	postgres	2026-01-11 19:02:05.434211	Created homework
29	Homework	UPDATE	127	postgres	2026-01-11 19:02:22.68721	Updated homework
30	Homework	DELETE	127	postgres	2026-01-11 19:02:30.907177	Deleted homework
31	Lessons	INSERT	207	defaultuser	2026-01-11 19:04:29.412859	Created lesson
32	StudentData	INSERT	1507	postgres	2026-01-11 19:05:23.556873	Created student data
33	Lessons	UPDATE	207	defaultuser	2026-01-11 19:13:59.080312	Updated lesson
34	Lessons	DELETE	207	postgres	2026-01-11 19:14:21.019179	Deleted lesson
35	StudentData	INSERT	1508	postgres	2026-01-11 19:14:55.780181	Created student data
36	Lessons	INSERT	208	defaultuser	2026-01-11 19:16:33.99458	Created lesson
37	Lessons	UPDATE	208	defaultuser	2026-01-11 19:17:14.000113	Updated lesson
38	StudentData	INSERT	1509	postgres	2026-01-11 19:17:28.10125	Created student data
39	StudentData	UPDATE	1509	postgres	2026-01-11 19:25:07.564944	Updated student data
40	StudentData	UPDATE	1509	postgres	2026-01-11 19:25:10.913231	Updated student data
41	StudentData	UPDATE	1509	postgres	2026-01-11 19:25:43.876758	Updated student data
42	StudentData	UPDATE	1509	postgres	2026-01-11 19:25:49.242302	Updated student data
43	StudentData	INSERT	1510	postgres	2026-01-11 19:26:16.746776	Created student data
44	StudentData	DELETE	1510	postgres	2026-01-11 19:26:23.306932	Deleted student data
45	StudentData	DELETE	1509	postgres	2026-01-11 19:26:28.547095	Deleted student data
46	Homework	INSERT	128	postgres	2026-01-11 19:26:59.779687	Created homework
47	Homework	UPDATE	128	postgres	2026-01-11 19:27:06.427106	Updated homework
48	Homework	DELETE	128	postgres	2026-01-11 19:27:13.628519	Deleted homework
49	Lessons	UPDATE	208	defaultuser	2026-01-11 19:27:26.643299	Updated lesson
50	Lessons	DELETE	208	postgres	2026-01-11 19:27:29.168094	Deleted lesson
51	Lessons	INSERT	209	defaultuser	2026-01-11 19:28:04.593152	Created lesson
52	Homework	INSERT	129	postgres	2026-01-11 19:28:23.284502	Created homework
53	Homework	UPDATE	129	postgres	2026-01-11 19:28:27.651595	Updated homework
54	Homework	DELETE	129	postgres	2026-01-11 19:28:30.726495	Deleted homework
55	StudentData	INSERT	1512	postgres	2026-01-11 19:28:45.713952	Created student data
56	StudentData	DELETE	1512	postgres	2026-01-11 19:28:51.915402	Deleted student data
57	Lessons	DELETE	209	postgres	2026-01-11 19:29:00.18338	Deleted lesson
58	StudentData	INSERT	1513	postgres	2026-01-11 21:23:44.18991	Created student data
59	Lessons	INSERT	210	defaultuser	2026-01-11 21:25:08.815885	Created lesson
60	StudentData	INSERT	1514	postgres	2026-01-11 21:25:24.356719	Created student data
61	StudentData	UPDATE	1514	postgres	2026-01-11 21:25:33.207343	Updated student data
62	StudentData	UPDATE	1514	postgres	2026-01-11 21:25:40.658225	Updated student data
63	StudentData	UPDATE	1514	postgres	2026-01-11 21:25:46.60316	Updated student data
64	StudentData	UPDATE	1514	postgres	2026-01-11 21:26:41.049282	Updated student data
65	StudentData	UPDATE	1	postgres	2026-01-11 21:29:16.315077	Updated student data
66	StudentData	UPDATE	1514	postgres	2026-01-11 21:30:07.496883	Updated student data
67	StudentData	UPDATE	1500	postgres	2026-01-11 22:05:53.835693	Updated student data
\.


--
-- Data for Name: class; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.class (class_name, class_journal_id, class_mainteacher) FROM stdin;
1-А	1	1
1-Б	2	2
1-В	3	3
2-А	4	4
2-Б	5	5
2-В	6	6
3-А	7	7
3-Б	8	8
3-В	9	9
4-А	10	10
4-Б	11	11
4-В	12	12
5-А	13	13
5-Б	14	14
6-А	15	15
6-Б	16	16
7-А	17	17
7-Б	18	18
8-А	19	19
8-Б	20	20
9-А	21	21
9-Б	22	22
10-А	23	23
10-Б	24	24
11-А	25	25
11-Б	26	26
12-А	27	27
12-Б	28	28
12-Г	29	36
\.


--
-- Data for Name: days; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.days (day_id, day_subject, day_time, day_weekday, day_timetable) FROM stdin;
1	9	08:30:00	Понеділок	1
2	15	09:30:00	Понеділок	1
3	10	10:30:00	Понеділок	1
4	8	11:30:00	Понеділок	1
5	1	12:30:00	Понеділок	1
6	10	08:30:00	Вівторок	1
7	9	09:30:00	Вівторок	1
8	19	10:30:00	Вівторок	1
9	15	11:30:00	Вівторок	1
10	3	12:30:00	Вівторок	1
11	9	08:30:00	Середа	1
12	18	09:30:00	Середа	1
13	1	10:30:00	Середа	1
14	20	11:30:00	Середа	1
15	10	12:30:00	Середа	1
16	2	08:30:00	Четвер	1
17	6	09:30:00	Четвер	1
18	9	10:30:00	Четвер	1
19	14	11:30:00	Четвер	1
20	1	12:30:00	Четвер	1
21	13	08:30:00	П’ятниця	1
22	3	09:30:00	П’ятниця	1
23	2	10:30:00	П’ятниця	1
24	1	11:30:00	П’ятниця	1
25	10	12:30:00	П’ятниця	1
26	4	08:30:00	Понеділок	2
27	1	09:30:00	Понеділок	2
28	2	10:30:00	Понеділок	2
29	10	11:30:00	Понеділок	2
30	18	12:30:00	Понеділок	2
31	19	08:30:00	Вівторок	2
32	9	09:30:00	Вівторок	2
33	12	10:30:00	Вівторок	2
34	10	11:30:00	Вівторок	2
35	15	12:30:00	Вівторок	2
36	10	08:30:00	Середа	2
37	4	09:30:00	Середа	2
38	2	10:30:00	Середа	2
39	1	11:30:00	Середа	2
40	8	12:30:00	Середа	2
41	7	08:30:00	Четвер	2
42	9	09:30:00	Четвер	2
43	15	10:30:00	Четвер	2
44	2	11:30:00	Четвер	2
45	1	12:30:00	Четвер	2
46	18	08:30:00	П’ятниця	2
47	9	09:30:00	П’ятниця	2
48	1	10:30:00	П’ятниця	2
49	15	11:30:00	П’ятниця	2
50	2	12:30:00	П’ятниця	2
51	9	08:30:00	Понеділок	3
52	13	09:30:00	Понеділок	3
53	2	10:30:00	Понеділок	3
54	1	11:30:00	Понеділок	3
55	10	12:30:00	Понеділок	3
56	5	08:30:00	Вівторок	3
57	13	09:30:00	Вівторок	3
58	1	10:30:00	Вівторок	3
59	15	11:30:00	Вівторок	3
60	2	12:30:00	Вівторок	3
61	13	08:30:00	Середа	3
62	19	09:30:00	Середа	3
63	15	10:30:00	Середа	3
64	9	11:30:00	Середа	3
65	2	12:30:00	Середа	3
66	6	08:30:00	Четвер	3
67	15	09:30:00	Четвер	3
68	10	10:30:00	Четвер	3
69	1	11:30:00	Четвер	3
70	5	12:30:00	Четвер	3
71	1	08:30:00	П’ятниця	3
72	2	09:30:00	П’ятниця	3
73	18	10:30:00	П’ятниця	3
74	10	11:30:00	П’ятниця	3
75	9	12:30:00	П’ятниця	3
76	2	08:30:00	Понеділок	4
77	15	09:30:00	Понеділок	4
78	6	10:30:00	Понеділок	4
79	2	11:30:00	Понеділок	4
80	1	12:30:00	Понеділок	4
81	2	08:30:00	Вівторок	4
82	9	09:30:00	Вівторок	4
83	17	10:30:00	Вівторок	4
84	20	11:30:00	Вівторок	4
85	1	12:30:00	Вівторок	4
86	1	08:30:00	Середа	4
87	10	09:30:00	Середа	4
88	11	10:30:00	Середа	4
89	9	11:30:00	Середа	4
90	20	12:30:00	Середа	4
91	8	08:30:00	Четвер	4
92	2	09:30:00	Четвер	4
93	1	10:30:00	Четвер	4
94	19	11:30:00	Четвер	4
95	10	12:30:00	Четвер	4
96	10	08:30:00	П’ятниця	4
97	9	09:30:00	П’ятниця	4
98	5	10:30:00	П’ятниця	4
99	1	11:30:00	П’ятниця	4
100	16	12:30:00	П’ятниця	4
101	9	08:30:00	Понеділок	5
102	10	09:30:00	Понеділок	5
103	1	10:30:00	Понеділок	5
104	12	11:30:00	Понеділок	5
105	13	12:30:00	Понеділок	5
106	19	08:30:00	Вівторок	5
107	2	09:30:00	Вівторок	5
108	1	10:30:00	Вівторок	5
109	18	11:30:00	Вівторок	5
110	1	12:30:00	Вівторок	5
111	10	08:30:00	Середа	5
112	8	09:30:00	Середа	5
113	3	10:30:00	Середа	5
114	1	11:30:00	Середа	5
115	15	12:30:00	Середа	5
116	2	08:30:00	Четвер	5
117	18	09:30:00	Четвер	5
118	2	10:30:00	Четвер	5
119	7	11:30:00	Четвер	5
120	15	12:30:00	Четвер	5
121	10	08:30:00	П’ятниця	5
122	14	09:30:00	П’ятниця	5
123	2	10:30:00	П’ятниця	5
124	4	11:30:00	П’ятниця	5
125	1	12:30:00	П’ятниця	5
126	15	08:30:00	Понеділок	6
127	2	09:30:00	Понеділок	6
128	10	10:30:00	Понеділок	6
129	1	11:30:00	Понеділок	6
130	4	12:30:00	Понеділок	6
131	1	08:30:00	Вівторок	6
132	9	09:30:00	Вівторок	6
133	5	10:30:00	Вівторок	6
134	10	11:30:00	Вівторок	6
135	15	12:30:00	Вівторок	6
136	1	08:30:00	Середа	6
137	2	09:30:00	Середа	6
138	18	10:30:00	Середа	6
139	4	11:30:00	Середа	6
140	1	12:30:00	Середа	6
141	15	08:30:00	Четвер	6
142	2	09:30:00	Четвер	6
143	7	10:30:00	Четвер	6
144	1	11:30:00	Четвер	6
145	16	12:30:00	Четвер	6
146	2	08:30:00	П’ятниця	6
147	2	09:30:00	П’ятниця	6
148	1	10:30:00	П’ятниця	6
149	10	11:30:00	П’ятниця	6
150	15	12:30:00	П’ятниця	6
151	1	08:30:00	Понеділок	7
152	19	09:30:00	Понеділок	7
153	18	10:30:00	Понеділок	7
154	1	11:30:00	Понеділок	7
155	2	12:30:00	Понеділок	7
156	2	08:30:00	Вівторок	7
157	10	09:30:00	Вівторок	7
158	17	10:30:00	Вівторок	7
159	6	11:30:00	Вівторок	7
160	9	12:30:00	Вівторок	7
161	13	08:30:00	Середа	7
162	9	09:30:00	Середа	7
163	1	10:30:00	Середа	7
164	1	11:30:00	Середа	7
165	4	12:30:00	Середа	7
166	19	08:30:00	Четвер	7
167	1	09:30:00	Четвер	7
168	9	10:30:00	Четвер	7
169	17	11:30:00	Четвер	7
170	2	12:30:00	Четвер	7
171	2	08:30:00	П’ятниця	7
172	10	09:30:00	П’ятниця	7
173	1	10:30:00	П’ятниця	7
174	2	11:30:00	П’ятниця	7
175	5	12:30:00	П’ятниця	7
176	2	08:30:00	Понеділок	8
177	4	09:30:00	Понеділок	8
178	15	10:30:00	Понеділок	8
179	9	11:30:00	Понеділок	8
180	3	12:30:00	Понеділок	8
181	1	08:30:00	Вівторок	8
182	12	09:30:00	Вівторок	8
183	8	10:30:00	Вівторок	8
184	2	11:30:00	Вівторок	8
185	1	12:30:00	Вівторок	8
186	18	08:30:00	Середа	8
187	15	09:30:00	Середа	8
188	1	10:30:00	Середа	8
189	9	11:30:00	Середа	8
190	10	12:30:00	Середа	8
191	5	08:30:00	Четвер	8
192	20	09:30:00	Четвер	8
193	1	10:30:00	Четвер	8
194	9	11:30:00	Четвер	8
195	10	12:30:00	Четвер	8
196	14	08:30:00	П’ятниця	8
197	2	09:30:00	П’ятниця	8
198	3	10:30:00	П’ятниця	8
199	9	11:30:00	П’ятниця	8
200	2	12:30:00	П’ятниця	8
201	1	08:30:00	Понеділок	9
202	10	09:30:00	Понеділок	9
203	2	10:30:00	Понеділок	9
204	6	11:30:00	Понеділок	9
205	15	12:30:00	Понеділок	9
206	2	08:30:00	Вівторок	9
207	1	09:30:00	Вівторок	9
208	18	10:30:00	Вівторок	9
209	10	11:30:00	Вівторок	9
210	1	12:30:00	Вівторок	9
211	12	08:30:00	Середа	9
212	15	09:30:00	Середа	9
213	7	10:30:00	Середа	9
214	1	11:30:00	Середа	9
215	2	12:30:00	Середа	9
216	6	08:30:00	Четвер	9
217	1	09:30:00	Четвер	9
218	9	10:30:00	Четвер	9
219	8	11:30:00	Четвер	9
220	15	12:30:00	Четвер	9
221	2	08:30:00	П’ятниця	9
222	8	09:30:00	П’ятниця	9
223	9	10:30:00	П’ятниця	9
224	15	11:30:00	П’ятниця	9
225	2	12:30:00	П’ятниця	9
226	2	08:30:00	Понеділок	10
227	7	09:30:00	Понеділок	10
228	10	10:30:00	Понеділок	10
229	15	11:30:00	Понеділок	10
230	1	12:30:00	Понеділок	10
231	13	08:30:00	Вівторок	10
232	11	09:30:00	Вівторок	10
233	15	10:30:00	Вівторок	10
234	1	11:30:00	Вівторок	10
235	1	12:30:00	Вівторок	10
236	2	08:30:00	Середа	10
237	18	09:30:00	Середа	10
238	9	10:30:00	Середа	10
239	11	11:30:00	Середа	10
240	15	12:30:00	Середа	10
241	9	08:30:00	Четвер	10
242	2	09:30:00	Четвер	10
243	20	10:30:00	Четвер	10
244	1	11:30:00	Четвер	10
245	4	12:30:00	Четвер	10
246	15	08:30:00	П’ятниця	10
247	2	09:30:00	П’ятниця	10
248	4	10:30:00	П’ятниця	10
249	9	11:30:00	П’ятниця	10
250	13	12:30:00	П’ятниця	10
251	17	08:30:00	Понеділок	11
252	15	09:30:00	Понеділок	11
253	18	10:30:00	Понеділок	11
254	1	11:30:00	Понеділок	11
255	2	12:30:00	Понеділок	11
256	15	08:30:00	Вівторок	11
257	2	09:30:00	Вівторок	11
258	11	10:30:00	Вівторок	11
259	4	11:30:00	Вівторок	11
260	9	12:30:00	Вівторок	11
261	2	08:30:00	Середа	11
262	5	09:30:00	Середа	11
263	10	10:30:00	Середа	11
264	18	11:30:00	Середа	11
265	2	12:30:00	Середа	11
266	10	08:30:00	Четвер	11
267	15	09:30:00	Четвер	11
268	19	10:30:00	Четвер	11
269	20	11:30:00	Четвер	11
270	1	12:30:00	Четвер	11
271	2	08:30:00	П’ятниця	11
272	14	09:30:00	П’ятниця	11
273	10	10:30:00	П’ятниця	11
274	1	11:30:00	П’ятниця	11
275	19	12:30:00	П’ятниця	11
276	17	08:30:00	Понеділок	12
277	1	09:30:00	Понеділок	12
278	16	10:30:00	Понеділок	12
279	2	11:30:00	Понеділок	12
280	15	12:30:00	Понеділок	12
281	7	08:30:00	Вівторок	12
282	2	09:30:00	Вівторок	12
283	8	10:30:00	Вівторок	12
284	1	11:30:00	Вівторок	12
285	1	12:30:00	Вівторок	12
286	2	08:30:00	Середа	12
287	15	09:30:00	Середа	12
288	1	10:30:00	Середа	12
289	9	11:30:00	Середа	12
290	14	12:30:00	Середа	12
291	1	08:30:00	Четвер	12
292	4	09:30:00	Четвер	12
293	2	10:30:00	Четвер	12
294	10	11:30:00	Четвер	12
295	5	12:30:00	Четвер	12
296	1	08:30:00	П’ятниця	12
297	15	09:30:00	П’ятниця	12
298	1	10:30:00	П’ятниця	12
299	4	11:30:00	П’ятниця	12
300	9	12:30:00	П’ятниця	12
301	9	08:30:00	Понеділок	13
302	2	09:30:00	Понеділок	13
303	15	10:30:00	Понеділок	13
304	17	11:30:00	Понеділок	13
305	14	12:30:00	Понеділок	13
306	8	08:30:00	Вівторок	13
307	17	09:30:00	Вівторок	13
308	15	10:30:00	Вівторок	13
309	9	11:30:00	Вівторок	13
310	16	12:30:00	Вівторок	13
311	11	08:30:00	Середа	13
312	10	09:30:00	Середа	13
313	18	10:30:00	Середа	13
314	17	11:30:00	Середа	13
315	17	12:30:00	Середа	13
316	10	08:30:00	Четвер	13
317	16	09:30:00	Четвер	13
318	9	10:30:00	Четвер	13
319	3	11:30:00	Четвер	13
320	7	12:30:00	Четвер	13
321	14	08:30:00	П’ятниця	13
322	16	09:30:00	П’ятниця	13
323	16	10:30:00	П’ятниця	13
324	10	11:30:00	П’ятниця	13
325	13	12:30:00	П’ятниця	13
326	17	08:30:00	Понеділок	14
327	15	09:30:00	Понеділок	14
328	13	10:30:00	Понеділок	14
329	16	11:30:00	Понеділок	14
330	10	12:30:00	Понеділок	14
331	17	08:30:00	Вівторок	14
332	2	09:30:00	Вівторок	14
333	13	10:30:00	Вівторок	14
334	1	11:30:00	Вівторок	14
335	10	12:30:00	Вівторок	14
336	2	08:30:00	Середа	14
337	16	09:30:00	Середа	14
338	1	10:30:00	Середа	14
339	15	11:30:00	Середа	14
340	18	12:30:00	Середа	14
341	2	08:30:00	Четвер	14
342	17	09:30:00	Четвер	14
343	10	10:30:00	Четвер	14
344	6	11:30:00	Четвер	14
345	17	12:30:00	Четвер	14
346	9	08:30:00	П’ятниця	14
347	17	09:30:00	П’ятниця	14
348	15	10:30:00	П’ятниця	14
349	10	11:30:00	П’ятниця	14
350	13	12:30:00	П’ятниця	14
351	9	08:30:00	Понеділок	15
352	2	09:30:00	Понеділок	15
353	12	10:30:00	Понеділок	15
354	8	11:30:00	Понеділок	15
355	16	12:30:00	Понеділок	15
356	16	08:30:00	Вівторок	15
357	17	09:30:00	Вівторок	15
358	20	10:30:00	Вівторок	15
359	5	11:30:00	Вівторок	15
360	10	12:30:00	Вівторок	15
361	9	08:30:00	Середа	15
362	15	09:30:00	Середа	15
363	12	10:30:00	Середа	15
364	17	11:30:00	Середа	15
365	6	12:30:00	Середа	15
366	2	08:30:00	Четвер	15
367	16	09:30:00	Четвер	15
368	16	10:30:00	Четвер	15
369	19	11:30:00	Четвер	15
370	10	12:30:00	Четвер	15
371	2	08:30:00	П’ятниця	15
372	8	09:30:00	П’ятниця	15
373	4	10:30:00	П’ятниця	15
374	16	11:30:00	П’ятниця	15
375	9	12:30:00	П’ятниця	15
376	12	08:30:00	Понеділок	16
377	2	09:30:00	Понеділок	16
378	9	10:30:00	Понеділок	16
379	17	11:30:00	Понеділок	16
380	3	12:30:00	Понеділок	16
381	15	08:30:00	Вівторок	16
382	5	09:30:00	Вівторок	16
383	17	10:30:00	Вівторок	16
384	16	11:30:00	Вівторок	16
385	12	12:30:00	Вівторок	16
386	9	08:30:00	Середа	16
387	19	09:30:00	Середа	16
388	15	10:30:00	Середа	16
389	17	11:30:00	Середа	16
390	10	12:30:00	Середа	16
391	20	08:30:00	Четвер	16
392	16	09:30:00	Четвер	16
393	15	10:30:00	Четвер	16
394	17	11:30:00	Четвер	16
395	19	12:30:00	Четвер	16
396	9	08:30:00	П’ятниця	16
397	7	09:30:00	П’ятниця	16
398	16	10:30:00	П’ятниця	16
399	12	11:30:00	П’ятниця	16
400	17	12:30:00	П’ятниця	16
401	2	08:30:00	Понеділок	17
402	16	09:30:00	Понеділок	17
403	16	10:30:00	Понеділок	17
404	8	11:30:00	Понеділок	17
405	3	12:30:00	Понеділок	17
406	16	08:30:00	Вівторок	17
407	9	09:30:00	Вівторок	17
408	1	10:30:00	Вівторок	17
409	10	11:30:00	Вівторок	17
410	15	12:30:00	Вівторок	17
411	17	08:30:00	Середа	17
412	12	09:30:00	Середа	17
413	17	10:30:00	Середа	17
414	9	11:30:00	Середа	17
415	19	12:30:00	Середа	17
416	17	08:30:00	Четвер	17
417	8	09:30:00	Четвер	17
418	10	10:30:00	Четвер	17
419	15	11:30:00	Четвер	17
420	9	12:30:00	Четвер	17
421	16	08:30:00	П’ятниця	17
422	9	09:30:00	П’ятниця	17
423	17	10:30:00	П’ятниця	17
424	10	11:30:00	П’ятниця	17
425	19	12:30:00	П’ятниця	17
426	17	08:30:00	Понеділок	18
427	10	09:30:00	Понеділок	18
428	6	10:30:00	Понеділок	18
429	16	11:30:00	Понеділок	18
430	2	12:30:00	Понеділок	18
431	4	08:30:00	Вівторок	18
432	5	09:30:00	Вівторок	18
433	2	10:30:00	Вівторок	18
434	17	11:30:00	Вівторок	18
435	16	12:30:00	Вівторок	18
436	16	08:30:00	Середа	18
437	17	09:30:00	Середа	18
438	9	10:30:00	Середа	18
439	15	11:30:00	Середа	18
440	2	12:30:00	Середа	18
441	16	08:30:00	Четвер	18
442	19	09:30:00	Четвер	18
443	5	10:30:00	Четвер	18
444	15	11:30:00	Четвер	18
445	2	12:30:00	Четвер	18
446	10	08:30:00	П’ятниця	18
447	15	09:30:00	П’ятниця	18
448	2	10:30:00	П’ятниця	18
449	20	11:30:00	П’ятниця	18
450	8	12:30:00	П’ятниця	18
451	10	08:30:00	Понеділок	19
452	14	09:30:00	Понеділок	19
453	15	10:30:00	Понеділок	19
454	2	11:30:00	Понеділок	19
455	19	12:30:00	Понеділок	19
456	3	08:30:00	Вівторок	19
457	17	09:30:00	Вівторок	19
458	16	10:30:00	Вівторок	19
459	6	11:30:00	Вівторок	19
460	9	12:30:00	Вівторок	19
461	16	08:30:00	Середа	19
462	20	09:30:00	Середа	19
463	17	10:30:00	Середа	19
464	17	11:30:00	Середа	19
465	15	12:30:00	Середа	19
466	3	08:30:00	Четвер	19
467	2	09:30:00	Четвер	19
468	15	10:30:00	Четвер	19
469	17	11:30:00	Четвер	19
470	9	12:30:00	Четвер	19
471	8	08:30:00	П’ятниця	19
472	5	09:30:00	П’ятниця	19
473	10	10:30:00	П’ятниця	19
474	16	11:30:00	П’ятниця	19
475	2	12:30:00	П’ятниця	19
476	19	08:30:00	Понеділок	20
477	10	09:30:00	Понеділок	20
478	17	10:30:00	Понеділок	20
479	20	11:30:00	Понеділок	20
480	15	12:30:00	Понеділок	20
481	9	08:30:00	Вівторок	20
482	16	09:30:00	Вівторок	20
483	17	10:30:00	Вівторок	20
484	2	11:30:00	Вівторок	20
485	18	12:30:00	Вівторок	20
486	20	08:30:00	Середа	20
487	1	09:30:00	Середа	20
488	17	10:30:00	Середа	20
489	9	11:30:00	Середа	20
490	10	12:30:00	Середа	20
491	17	08:30:00	Четвер	20
492	15	09:30:00	Четвер	20
493	2	10:30:00	Четвер	20
494	16	11:30:00	Четвер	20
495	6	12:30:00	Четвер	20
496	16	08:30:00	П’ятниця	20
497	15	09:30:00	П’ятниця	20
498	12	10:30:00	П’ятниця	20
499	14	11:30:00	П’ятниця	20
500	17	12:30:00	П’ятниця	20
501	17	08:30:00	Понеділок	21
502	10	09:30:00	Понеділок	21
503	15	10:30:00	Понеділок	21
504	17	11:30:00	Понеділок	21
505	16	12:30:00	Понеділок	21
506	4	08:30:00	Вівторок	21
507	17	09:30:00	Вівторок	21
508	10	10:30:00	Вівторок	21
509	9	11:30:00	Вівторок	21
510	13	12:30:00	Вівторок	21
511	10	08:30:00	Середа	21
512	16	09:30:00	Середа	21
513	16	10:30:00	Середа	21
514	17	11:30:00	Середа	21
515	12	12:30:00	Середа	21
516	16	08:30:00	Четвер	21
517	16	09:30:00	Четвер	21
518	5	10:30:00	Четвер	21
519	18	11:30:00	Четвер	21
520	17	12:30:00	Четвер	21
521	8	08:30:00	П’ятниця	21
522	16	09:30:00	П’ятниця	21
523	20	10:30:00	П’ятниця	21
524	9	11:30:00	П’ятниця	21
525	16	12:30:00	П’ятниця	21
526	15	08:30:00	Понеділок	22
527	16	09:30:00	Понеділок	22
528	4	10:30:00	Понеділок	22
529	16	11:30:00	Понеділок	22
530	10	12:30:00	Понеділок	22
531	10	08:30:00	Вівторок	22
532	2	09:30:00	Вівторок	22
533	8	10:30:00	Вівторок	22
534	17	11:30:00	Вівторок	22
535	16	12:30:00	Вівторок	22
536	9	08:30:00	Середа	22
537	10	09:30:00	Середа	22
538	17	10:30:00	Середа	22
539	14	11:30:00	Середа	22
540	16	12:30:00	Середа	22
541	2	08:30:00	Четвер	22
542	16	09:30:00	Четвер	22
543	15	10:30:00	Четвер	22
544	19	11:30:00	Четвер	22
545	10	12:30:00	Четвер	22
546	17	08:30:00	П’ятниця	22
547	13	09:30:00	П’ятниця	22
548	9	10:30:00	П’ятниця	22
549	2	11:30:00	П’ятниця	22
550	18	12:30:00	П’ятниця	22
551	17	08:30:00	Понеділок	23
552	10	09:30:00	Понеділок	23
553	16	10:30:00	Понеділок	23
554	11	11:30:00	Понеділок	23
555	2	12:30:00	Понеділок	23
556	19	08:30:00	Вівторок	23
557	17	09:30:00	Вівторок	23
558	16	10:30:00	Вівторок	23
559	15	11:30:00	Вівторок	23
560	16	12:30:00	Вівторок	23
561	5	08:30:00	Середа	23
562	9	09:30:00	Середа	23
563	14	10:30:00	Середа	23
564	15	11:30:00	Середа	23
565	16	12:30:00	Середа	23
566	9	08:30:00	Четвер	23
567	3	09:30:00	Четвер	23
568	2	10:30:00	Четвер	23
569	13	11:30:00	Четвер	23
570	15	12:30:00	Четвер	23
571	15	08:30:00	П’ятниця	23
572	8	09:30:00	П’ятниця	23
573	10	10:30:00	П’ятниця	23
574	16	11:30:00	П’ятниця	23
575	2	12:30:00	П’ятниця	23
576	10	08:30:00	Понеділок	24
577	17	09:30:00	Понеділок	24
578	1	10:30:00	Понеділок	24
579	15	11:30:00	Понеділок	24
580	16	12:30:00	Понеділок	24
581	17	08:30:00	Вівторок	24
582	9	09:30:00	Вівторок	24
583	17	10:30:00	Вівторок	24
584	5	11:30:00	Вівторок	24
585	8	12:30:00	Вівторок	24
586	16	08:30:00	Середа	24
587	17	09:30:00	Середа	24
588	20	10:30:00	Середа	24
589	16	11:30:00	Середа	24
590	13	12:30:00	Середа	24
591	9	08:30:00	Четвер	24
592	1	09:30:00	Четвер	24
593	17	10:30:00	Четвер	24
594	15	11:30:00	Четвер	24
595	10	12:30:00	Четвер	24
596	9	08:30:00	П’ятниця	24
597	15	09:30:00	П’ятниця	24
598	14	10:30:00	П’ятниця	24
599	2	11:30:00	П’ятниця	24
600	17	12:30:00	П’ятниця	24
601	16	08:30:00	Понеділок	25
602	15	09:30:00	Понеділок	25
603	19	10:30:00	Понеділок	25
604	17	11:30:00	Понеділок	25
605	12	12:30:00	Понеділок	25
606	13	08:30:00	Вівторок	25
607	10	09:30:00	Вівторок	25
608	9	10:30:00	Вівторок	25
609	16	11:30:00	Вівторок	25
610	1	12:30:00	Вівторок	25
611	2	08:30:00	Середа	25
612	20	09:30:00	Середа	25
613	16	10:30:00	Середа	25
614	12	11:30:00	Середа	25
615	10	12:30:00	Середа	25
616	10	08:30:00	Четвер	25
617	9	09:30:00	Четвер	25
618	16	10:30:00	Четвер	25
619	17	11:30:00	Четвер	25
620	2	12:30:00	Четвер	25
621	15	08:30:00	П’ятниця	25
622	11	09:30:00	П’ятниця	25
623	17	10:30:00	П’ятниця	25
624	14	11:30:00	П’ятниця	25
625	16	12:30:00	П’ятниця	25
626	10	08:30:00	Понеділок	26
627	16	09:30:00	Понеділок	26
628	11	10:30:00	Понеділок	26
629	9	11:30:00	Понеділок	26
630	2	12:30:00	Понеділок	26
631	18	08:30:00	Вівторок	26
632	13	09:30:00	Вівторок	26
633	10	10:30:00	Вівторок	26
634	17	11:30:00	Вівторок	26
635	9	12:30:00	Вівторок	26
636	2	08:30:00	Середа	26
637	15	09:30:00	Середа	26
638	16	10:30:00	Середа	26
639	12	11:30:00	Середа	26
640	9	12:30:00	Середа	26
641	9	08:30:00	Четвер	26
642	16	09:30:00	Четвер	26
643	1	10:30:00	Четвер	26
644	15	11:30:00	Четвер	26
645	20	12:30:00	Четвер	26
646	10	08:30:00	П’ятниця	26
647	17	09:30:00	П’ятниця	26
648	14	10:30:00	П’ятниця	26
649	9	11:30:00	П’ятниця	26
650	16	12:30:00	П’ятниця	26
651	2	08:30:00	Понеділок	27
652	16	09:30:00	Понеділок	27
653	4	10:30:00	Понеділок	27
654	17	11:30:00	Понеділок	27
655	8	12:30:00	Понеділок	27
656	10	08:30:00	Вівторок	27
657	9	09:30:00	Вівторок	27
658	18	10:30:00	Вівторок	27
659	15	11:30:00	Вівторок	27
660	14	12:30:00	Вівторок	27
661	17	08:30:00	Середа	27
662	15	09:30:00	Середа	27
663	12	10:30:00	Середа	27
664	9	11:30:00	Середа	27
665	2	12:30:00	Середа	27
666	12	08:30:00	Четвер	27
667	18	09:30:00	Четвер	27
668	16	10:30:00	Четвер	27
669	9	11:30:00	Четвер	27
670	15	12:30:00	Четвер	27
671	15	08:30:00	П’ятниця	27
672	16	09:30:00	П’ятниця	27
673	3	10:30:00	П’ятниця	27
674	17	11:30:00	П’ятниця	27
675	7	12:30:00	П’ятниця	27
676	7	08:30:00	Понеділок	28
677	17	09:30:00	Понеділок	28
678	2	10:30:00	Понеділок	28
679	16	11:30:00	Понеділок	28
680	3	12:30:00	Понеділок	28
681	1	08:30:00	Вівторок	28
682	20	09:30:00	Вівторок	28
683	17	10:30:00	Вівторок	28
684	17	11:30:00	Вівторок	28
685	16	12:30:00	Вівторок	28
686	1	08:30:00	Середа	28
687	16	09:30:00	Середа	28
688	5	10:30:00	Середа	28
689	9	11:30:00	Середа	28
690	17	12:30:00	Середа	28
691	16	08:30:00	Четвер	28
692	5	09:30:00	Четвер	28
693	17	10:30:00	Четвер	28
694	16	11:30:00	Четвер	28
695	2	12:30:00	Четвер	28
696	4	08:30:00	П’ятниця	28
697	15	09:30:00	П’ятниця	28
698	17	10:30:00	П’ятниця	28
699	17	11:30:00	П’ятниця	28
700	19	12:30:00	П’ятниця	28
701	1	08:00:00	Понеділок	32
702	1	08:00:00	Вівторок	32
\.


--
-- Data for Name: homework; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.homework (homework_id, homework_name, homework_teacher, homework_lesson, homework_duedate, homework_created_at, homework_desc, homework_class) FROM stdin;
1	Практична робота	4	29	2025-09-06	2025-09-04	Написати реферат на тему уроку.	8-Б
2	Проект	5	7	2025-09-21	2025-09-17	Написати реферат на тему уроку.	7-А
3	Домашнє завдання	17	71	2025-09-25	2025-09-24	Розв’язати вправи з прикладами та завданнями.	11-А
4	Домашнє завдання	18	63	2026-03-30	2026-03-27	Виконати завдання з підручника на сторінках 10-15.	5-Б
5	Тестове завдання	11	58	2025-09-20	2025-09-19	Розв’язати вправи з прикладами та завданнями.	11-А
6	Тестове завдання	12	36	2025-09-24	2025-09-23	Розв’язати вправи з прикладами та завданнями.	8-Б
7	Практична робота	13	27	2025-09-08	2025-09-05	Розв’язати вправи з прикладами та завданнями.	11-А
8	Контрольна робота	1	140	2025-09-29	2025-09-26	Опрацювати відповідний матеріал підручника.	2-А
9	Домашнє завдання	24	23	2025-09-14	2025-09-12	Підготувати презентацію на тему уроку.	8-А
10	Домашнє завдання	6	109	2025-09-07	2025-09-03	Розв’язати вправи з прикладами та завданнями.	11-А
11	Проект	9	9	2025-09-09	2025-09-05	Підготувати презентацію на тему уроку.	3-В
12	Практична робота	28	8	2025-09-14	2025-09-09	Виконати завдання з підручника на сторінках 10-15.	5-А
13	Контрольна робота	24	24	2025-09-24	2025-09-19	Опрацювати відповідний матеріал підручника.	3-Б
14	Домашнє завдання	15	56	2025-09-06	2025-09-03	Розв’язати вправи з прикладами та завданнями.	7-Б
15	Домашнє завдання	15	60	2025-09-27	2025-09-25	Опрацювати відповідний матеріал підручника.	10-А
16	Домашнє завдання	4	130	2025-09-11	2025-09-10	Виконати завдання з підручника на сторінках 10-15.	1-В
17	Практична робота	16	149	2025-09-15	2025-09-11	Розв’язати вправи з прикладами та завданнями.	2-Б
18	Контрольна робота	31	51	2025-09-14	2025-09-10	Підготувати презентацію на тему уроку.	2-А
19	Контрольна робота	7	108	2025-09-21	2025-09-18	Написати реферат на тему уроку.	6-А
20	Домашнє завдання	4	57	2026-03-28	2026-03-27	Написати реферат на тему уроку.	10-Б
21	Практична робота	22	115	2025-09-06	2025-09-04	Підготувати презентацію на тему уроку.	7-Б
22	Практична робота	29	72	2025-09-09	2025-09-05	Виконати завдання з підручника на сторінках 10-15.	6-А
23	Проект	16	2	2025-09-07	2025-09-03	Опрацювати відповідний матеріал підручника.	1-Б
24	Практична робота	1	98	2025-09-05	2025-09-03	Написати реферат на тему уроку.	6-Б
25	Домашнє завдання	31	104	2025-09-13	2025-09-09	Підготувати презентацію на тему уроку.	5-А
26	Контрольна робота	1	21	2025-09-20	2025-09-17	Виконати завдання з підручника на сторінках 10-15.	5-Б
27	Тестове завдання	32	90	2025-09-07	2025-09-05	Підготувати презентацію на тему уроку.	1-Б
28	Домашнє завдання	4	55	2025-09-16	2025-09-15	Розв’язати вправи з прикладами та завданнями.	6-Б
29	Домашнє завдання	11	44	2025-09-07	2025-09-02	Підготувати презентацію на тему уроку.	1-В
30	Домашнє завдання	5	145	2025-09-14	2025-09-10	Розв’язати вправи з прикладами та завданнями.	3-Б
31	Контрольна робота	3	20	2025-09-27	2025-09-26	Розв’язати вправи з прикладами та завданнями.	8-А
32	Тестове завдання	21	28	2025-09-13	2025-09-11	Підготувати презентацію на тему уроку.	3-В
33	Контрольна робота	26	127	2025-09-08	2025-09-05	Виконати завдання з підручника на сторінках 10-15.	11-А
34	Проект	5	122	2025-09-05	2025-09-01	Розв’язати вправи з прикладами та завданнями.	2-А
35	Проект	5	14	2025-09-26	2025-09-24	Виконати завдання з підручника на сторінках 10-15.	2-Б
36	Тестове завдання	23	12	2025-09-05	2025-09-03	Виконати завдання з підручника на сторінках 10-15.	2-В
37	Проект	29	49	2025-09-27	2025-09-24	Розв’язати вправи з прикладами та завданнями.	1-А
38	Тестове завдання	20	13	2025-09-06	2025-09-04	Опрацювати відповідний матеріал підручника.	2-А
39	Проект	10	46	2025-09-14	2025-09-11	Підготувати презентацію на тему уроку.	10-А
40	Проект	22	141	2025-09-12	2025-09-09	Написати реферат на тему уроку.	3-В
41	Тестове завдання	4	45	2025-09-07	2025-09-03	Опрацювати відповідний матеріал підручника.	1-А
42	Практична робота	22	78	2025-09-08	2025-09-05	Написати реферат на тему уроку.	7-Б
43	Домашнє завдання	28	34	2025-09-25	2025-09-24	Опрацювати відповідний матеріал підручника.	10-А
44	Тестове завдання	10	126	2025-09-25	2025-09-24	Розв’язати вправи з прикладами та завданнями.	7-Б
45	Домашнє завдання	10	6	2025-09-20	2025-09-18	Виконати завдання з підручника на сторінках 10-15.	4-В
46	Практична робота	3	94	2025-09-18	2025-09-16	Опрацювати відповідний матеріал підручника.	4-В
47	Практична робота	27	59	2025-09-28	2025-09-26	Підготувати презентацію на тему уроку.	11-Б
48	Практична робота	12	69	2025-09-19	2025-09-18	Виконати завдання з підручника на сторінках 10-15.	11-Б
49	Практична робота	27	16	2025-09-13	2025-09-10	Опрацювати відповідний матеріал підручника.	5-А
50	Практична робота	3	114	2025-09-24	2025-09-22	Написати реферат на тему уроку.	4-В
51	Домашнє завдання	20	11	2025-09-12	2025-09-10	Підготувати презентацію на тему уроку.	5-А
52	Тестове завдання	22	148	2025-09-12	2025-09-11	Виконати завдання з підручника на сторінках 10-15.	9-А
53	Домашнє завдання	26	38	2025-09-27	2025-09-24	Опрацювати відповідний матеріал підручника.	3-В
54	Домашнє завдання	12	81	2025-09-28	2025-09-25	Опрацювати відповідний матеріал підручника.	8-Б
55	Контрольна робота	28	80	2025-09-19	2025-09-16	Розв’язати вправи з прикладами та завданнями.	7-А
56	Практична робота	8	47	2025-09-22	2025-09-17	Виконати завдання з підручника на сторінках 10-15.	1-Б
57	Проект	28	74	2025-09-06	2025-09-01	Підготувати презентацію на тему уроку.	4-В
58	Проект	28	25	2025-09-06	2025-09-03	Виконати завдання з підручника на сторінках 10-15.	9-Б
59	Тестове завдання	8	91	2025-09-17	2025-09-12	Написати реферат на тему уроку.	4-Б
60	Практична робота	26	143	2025-09-17	2025-09-12	Підготувати презентацію на тему уроку.	5-Б
61	Проект	25	106	2025-09-13	2025-09-08	Виконати завдання з підручника на сторінках 10-15.	5-А
62	Практична робота	1	85	2025-09-15	2025-09-12	Написати реферат на тему уроку.	11-Б
63	Контрольна робота	21	30	2025-09-23	2025-09-19	Підготувати презентацію на тему уроку.	7-А
64	Тестове завдання	31	118	2025-09-09	2025-09-08	Розв’язати вправи з прикладами та завданнями.	9-Б
65	Тестове завдання	22	100	2025-09-05	2025-09-03	Підготувати презентацію на тему уроку.	11-Б
66	Домашнє завдання	13	88	2025-09-06	2025-09-05	Підготувати презентацію на тему уроку.	6-Б
67	Проект	5	113	2025-09-23	2025-09-19	Підготувати презентацію на тему уроку.	10-А
68	Практична робота	25	101	2025-09-26	2025-09-22	Підготувати презентацію на тему уроку.	9-А
69	Практична робота	1	121	2025-09-08	2025-09-04	Підготувати презентацію на тему уроку.	11-Б
70	Практична робота	30	107	2025-09-07	2025-09-02	Опрацювати відповідний матеріал підручника.	6-А
71	Проект	9	95	2025-09-24	2025-09-19	Розв’язати вправи з прикладами та завданнями.	4-Б
72	Контрольна робота	29	125	2025-10-01	2025-09-26	Розв’язати вправи з прикладами та завданнями.	6-А
73	Тестове завдання	11	48	2025-09-26	2025-09-22	Підготувати презентацію на тему уроку.	12-А
74	Практична робота	18	112	2025-09-27	2025-09-23	Виконати завдання з підручника на сторінках 10-15.	6-А
75	Тестове завдання	5	144	2025-09-14	2025-09-12	Виконати завдання з підручника на сторінках 10-15.	4-Б
76	Практична робота	6	35	2025-09-07	2025-09-05	Написати реферат на тему уроку.	10-А
77	Контрольна робота	10	10	2025-09-10	2025-09-09	Написати реферат на тему уроку.	4-Б
78	Практична робота	30	22	2025-09-19	2025-09-18	Написати реферат на тему уроку.	5-А
79	Контрольна робота	2	103	2025-09-29	2025-09-25	Опрацювати відповідний матеріал підручника.	4-В
80	Проект	20	32	2025-09-21	2025-09-17	Розв’язати вправи з прикладами та завданнями.	11-Б
81	Тестове завдання	15	79	2025-09-24	2025-09-22	Написати реферат на тему уроку.	6-Б
82	Контрольна робота	2	136	2025-09-20	2025-09-17	Підготувати презентацію на тему уроку.	12-А
83	Проект	30	83	2025-09-10	2025-09-05	Опрацювати відповідний матеріал підручника.	5-А
84	Практична робота	2	75	2025-09-07	2025-09-03	Написати реферат на тему уроку.	2-В
85	Тестове завдання	4	150	2025-09-15	2025-09-11	Підготувати презентацію на тему уроку.	6-А
86	Тестове завдання	21	42	2025-09-19	2025-09-15	Написати реферат на тему уроку.	3-В
87	Проект	6	139	2025-09-23	2025-09-22	Опрацювати відповідний матеріал підручника.	4-В
88	Домашнє завдання	15	15	2026-03-28	2026-03-27	Опрацювати відповідний матеріал підручника.	3-Б
89	Практична робота	13	53	2025-09-06	2025-09-01	Підготувати презентацію на тему уроку.	2-Б
90	Практична робота	31	3	2025-09-09	2025-09-04	Написати реферат на тему уроку.	10-А
91	Проект	17	52	2025-09-18	2025-09-16	Розв’язати вправи з прикладами та завданнями.	10-Б
92	Домашнє завдання	8	70	2025-09-11	2025-09-08	Розв’язати вправи з прикладами та завданнями.	1-А
93	Контрольна робота	20	26	2025-09-29	2025-09-25	Підготувати презентацію на тему уроку.	1-В
94	Проект	16	18	2025-09-07	2025-09-04	Опрацювати відповідний матеріал підручника.	11-Б
95	Контрольна робота	3	5	2025-09-21	2025-09-16	Виконати завдання з підручника на сторінках 10-15.	1-В
96	Контрольна робота	22	116	2025-09-05	2025-09-01	Опрацювати відповідний матеріал підручника.	5-Б
97	Практична робота	24	37	2026-03-31	2026-03-27	Написати реферат на тему уроку.	2-В
98	Контрольна робота	18	77	2025-10-01	2025-09-26	Написати реферат на тему уроку.	5-Б
99	Домашнє завдання	18	97	2025-09-17	2025-09-15	Виконати завдання з підручника на сторінках 10-15.	6-А
100	Проект	16	123	2025-09-24	2025-09-19	Написати реферат на тему уроку.	4-Б
101	Практична робота	2	65	2025-09-25	2025-09-22	Написати реферат на тему уроку.	3-А
102	Тестове завдання	23	99	2025-09-14	2025-09-11	Розв’язати вправи з прикладами та завданнями.	10-А
103	Проект	18	146	2025-09-25	2025-09-24	Підготувати презентацію на тему уроку.	1-В
104	Проект	16	50	2025-09-22	2025-09-18	Підготувати презентацію на тему уроку.	10-А
105	Контрольна робота	31	89	2026-03-31	2026-03-27	Опрацювати відповідний матеріал підручника.	1-В
106	Практична робота	19	105	2025-09-14	2025-09-10	Виконати завдання з підручника на сторінках 10-15.	9-Б
107	Проект	24	17	2025-09-27	2025-09-22	Виконати завдання з підручника на сторінках 10-15.	5-Б
108	Тестове завдання	22	92	2025-09-20	2025-09-16	Виконати завдання з підручника на сторінках 10-15.	3-В
109	Тестове завдання	15	102	2025-09-06	2025-09-04	Опрацювати відповідний матеріал підручника.	10-Б
110	Контрольна робота	12	82	2025-09-11	2025-09-09	Виконати завдання з підручника на сторінках 10-15.	10-Б
111	Тестове завдання	19	67	2025-09-06	2025-09-04	Підготувати презентацію на тему уроку.	4-В
112	Проект	12	117	2025-09-13	2025-09-12	Підготувати презентацію на тему уроку.	3-В
113	Тестове завдання	3	87	2025-09-07	2025-09-02	Підготувати презентацію на тему уроку.	9-А
114	Проект	32	119	2025-09-05	2025-09-04	Виконати завдання з підручника на сторінках 10-15.	6-Б
115	Практична робота	31	111	2025-09-22	2025-09-19	Опрацювати відповідний матеріал підручника.	3-В
116	Контрольна робота	31	138	2025-09-05	2025-09-04	Написати реферат на тему уроку.	1-В
117	Проект	4	147	2025-09-07	2025-09-05	Виконати завдання з підручника на сторінках 10-15.	1-В
118	Контрольна робота	16	43	2025-09-09	2025-09-04	Розв’язати вправи з прикладами та завданнями.	8-Б
119	Контрольна робота	15	68	2025-09-27	2025-09-23	Написати реферат на тему уроку.	4-А
120	Проект	28	61	2025-09-17	2025-09-12	Опрацювати відповідний матеріал підручника.	8-Б
121	Геометрія — Конспект	5	12	2025-12-20	2025-12-11	Прочитати параграф 4	7-А
126	TESTS	1	185	2025-12-24	2025-12-23	TESTS	12-Г
\.


--
-- Data for Name: journal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.journal (journal_id, journal_teacher, journal_name) FROM stdin;
1	1	Журнал класу 1-А
2	2	Журнал класу 1-Б
3	3	Журнал класу 1-В
4	4	Журнал класу 2-А
5	5	Журнал класу 2-Б
6	6	Журнал класу 2-В
7	7	Журнал класу 3-А
8	8	Журнал класу 3-Б
9	9	Журнал класу 3-В
10	10	Журнал класу 4-А
11	11	Журнал класу 4-Б
12	12	Журнал класу 4-В
13	13	Журнал класу 5-А
14	14	Журнал класу 5-Б
15	15	Журнал класу 6-А
16	16	Журнал класу 6-Б
17	17	Журнал класу 7-А
18	18	Журнал класу 7-Б
19	19	Журнал класу 8-А
20	20	Журнал класу 8-Б
21	21	Журнал класу 9-А
22	22	Журнал класу 9-Б
23	23	Журнал класу 10-А
24	24	Журнал класу 10-Б
25	25	Журнал класу 11-А
26	26	Журнал класу 11-Б
27	27	Журнал класу 12-А
28	28	Журнал класу 12-Б
29	1	TEST
30	1	TEST2
31	\N	TEST3
\.


--
-- Data for Name: lessons; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lessons (lesson_id, lesson_name, lesson_class, lesson_subject, lesson_material, lesson_teacher, lesson_date) FROM stdin;
1	Практичне заняття: архітектурні стилі	1-А	9	18	7	2025-09-01 00:00:00
2	Повторення: міграція населення	1-В	19	4	6	2025-09-02 00:00:00
3	Тема уроку: фотосинтез	7-А	20	\N	13	2025-09-03 00:00:00
4	Повторення: кліматичні зони	5-Б	8	36	1	2025-09-04 00:00:00
5	Лекція: квадратні рівняння	10-А	14	20	14	2025-09-05 00:00:00
6	Лабораторна: квадратні рівняння	2-А	3	46	23	2025-09-08 00:00:00
7	Контрольна робота: кібербезпека	11-Б	2	69	8	2025-09-09 00:00:00
8	Обговорення: фінансова грамотність	1-В	18	81	24	2025-09-10 00:00:00
9	Тема уроку: основи програмування	10-А	3	\N	15	2025-09-11 00:00:00
10	Контрольна робота: квадратні рівняння	1-В	8	49	18	2025-09-12 00:00:00
11	Лабораторна: історія Київської Русі	2-В	12	86	18	2025-09-15 00:00:00
12	Практичне заняття: кліматичні зони	8-Б	6	32	11	2025-09-16 00:00:00
13	Обговорення: історія Київської Русі	3-В	18	42	4	2025-09-17 00:00:00
14	Введення в тему: тригонометрія	11-Б	11	9	14	2025-09-18 00:00:00
15	Домашнє завдання: фінансова грамотність	10-А	11	64	26	2025-09-19 00:00:00
16	Розв'язування задач: модернізм в літературі	2-Б	9	\N	17	2025-09-22 00:00:00
17	Домашнє завдання: функції	5-Б	19	29	9	2025-09-23 00:00:00
18	Розв'язування задач: механічна енергія	1-В	2	20	11	2025-09-24 00:00:00
19	Обговорення: хімія органічних сполук	8-Б	3	77	30	2025-09-25 00:00:00
20	Контрольна робота: механічна енергія	7-Б	1	15	18	2025-09-26 00:00:00
21	Лабораторна: квадратні рівняння	2-А	10	59	1	2025-09-29 00:00:00
22	Контрольна робота: функції	7-А	6	14	20	2025-09-30 00:00:00
23	Повторення: оптика	8-Б	7	\N	11	2025-10-01 00:00:00
24	Повторення: попит і пропозиція	1-А	20	3	8	2025-10-02 00:00:00
25	Лабораторна: фінансова грамотність	12-А	10	31	6	2025-10-03 00:00:00
26	Розв'язування задач: клітина	12-А	3	69	9	2025-10-06 00:00:00
27	Розв'язування задач: права людини	7-Б	6	78	28	2025-10-07 00:00:00
28	Повторення: фотосинтез	11-А	7	52	24	2025-10-08 00:00:00
29	Повторення: історія Київської Русі	6-А	4	9	22	2025-10-09 00:00:00
30	Домашнє завдання: лінійні рівняння	7-Б	8	1	5	2025-10-10 00:00:00
31	Введення в тему: кліматичні зони	3-Б	3	43	5	2025-10-13 00:00:00
32	Тема уроку: механічна енергія	3-В	16	17	31	2025-10-14 00:00:00
33	Розв'язування задач: тригонометрія	11-Б	14	\N	7	2025-10-15 00:00:00
34	Обговорення: міграція населення	4-В	14	94	4	2025-10-16 00:00:00
35	Практичне заняття: міграція населення	1-Б	13	14	16	2025-10-17 00:00:00
36	Тема уроку: фотосинтез	7-Б	15	\N	12	2025-10-20 00:00:00
37	Розв'язування задач: генетика	3-Б	3	71	7	2025-10-21 00:00:00
38	Повторення: геометричні фігури	12-А	1	97	16	2025-10-22 00:00:00
39	Обговорення: хімічні реакції	6-Б	16	52	4	2025-10-23 00:00:00
40	Обговорення: хімічні реакції	1-А	13	59	19	2025-10-24 00:00:00
41	Повторення: екосистеми	9-Б	16	\N	19	2025-10-27 00:00:00
42	Введення в тему: фотосинтез	8-А	18	\N	21	2025-10-28 00:00:00
43	Введення в тему: геометричні фігури	8-А	16	68	11	2025-10-29 00:00:00
44	Повторення: геометричні фігури	1-В	6	\N	5	2025-10-30 00:00:00
45	Тема уроку: міграція населення	5-А	4	73	16	2025-10-31 00:00:00
46	Домашнє завдання: основи програмування	1-Б	20	\N	21	2025-11-03 00:00:00
47	Контрольна робота: фінансова грамотність	3-А	11	51	9	2025-11-04 00:00:00
48	Контрольна робота: міграція населення	6-А	11	10	1	2025-11-05 00:00:00
49	Домашнє завдання: історія Київської Русі	8-А	4	\N	14	2025-11-06 00:00:00
50	Контрольна робота: механічна енергія	2-Б	12	32	24	2025-11-07 00:00:00
51	Лекція: електричний струм	6-А	18	79	1	2025-11-10 00:00:00
52	Повторення: міграція населення	4-А	4	18	17	2025-11-11 00:00:00
53	Практичне заняття: Сонячна система	10-Б	18	\N	19	2025-11-12 00:00:00
54	Тема уроку: кібербезпека	10-А	11	82	17	2025-11-13 00:00:00
55	Розв'язування задач: механічна енергія	3-В	2	\N	28	2025-11-14 00:00:00
56	Контрольна робота: оптика	1-Б	1	17	17	2025-11-17 00:00:00
57	Розв'язування задач: хімічні реакції	7-Б	14	15	5	2025-11-18 00:00:00
58	Лекція: модернізм в літературі	7-Б	2	75	10	2025-11-19 00:00:00
59	Лекція: екосистеми	1-Б	10	6	23	2025-11-20 00:00:00
60	Тема уроку: фотосинтез	9-Б	4	72	27	2025-11-21 00:00:00
61	Лекція: кібербезпека	3-Б	6	23	27	2025-11-24 00:00:00
62	Лекція: лінійні рівняння	10-Б	11	53	16	2025-11-25 00:00:00
63	Лекція: генетика	11-Б	4	5	31	2025-11-26 00:00:00
64	Тема уроку: тригонометрія	12-А	15	30	15	2025-11-27 00:00:00
65	Тема уроку: лінійні рівняння	5-А	11	9	18	2025-11-28 00:00:00
66	Повторення: вектори	5-А	18	4	8	2025-12-01 00:00:00
67	Контрольна робота: модернізм в літературі	2-В	19	34	3	2025-12-02 00:00:00
68	Домашнє завдання: Сонячна система	5-Б	12	41	28	2025-12-03 00:00:00
69	Повторення: кібербезпека	2-А	13	25	17	2025-12-04 00:00:00
70	Обговорення: геометричні фігури	1-А	17	69	13	2025-12-05 00:00:00
71	Обговорення: вектори	1-В	11	85	8	2025-12-08 00:00:00
72	Контрольна робота: функції	7-А	10	42	26	2025-12-09 00:00:00
73	Контрольна робота: кліматичні зони	7-Б	5	\N	25	2025-12-10 00:00:00
74	Лекція: міграція населення	8-Б	19	71	1	2025-12-11 00:00:00
75	Контрольна робота: електричний струм	3-А	14	78	21	2025-12-12 00:00:00
76	Розв'язування задач: історія Київської Русі	6-А	7	95	11	2025-12-15 00:00:00
77	Практичне заняття: міграція населення	4-А	17	80	22	2025-12-16 00:00:00
78	Тема уроку: клітина	9-Б	10	26	10	2025-12-17 00:00:00
79	Введення в тему: лінійні рівняння	3-Б	16	99	5	2025-12-18 00:00:00
80	Обговорення: історія Київської Русі	9-А	19	\N	25	2025-12-19 00:00:00
81	Обговорення: гідросфера	3-Б	5	1	7	2025-12-22 00:00:00
82	Обговорення: квадратні рівняння	3-Б	6	90	30	2025-12-23 00:00:00
83	Повторення: геометричні фігури	3-Б	4	60	21	2025-12-24 00:00:00
84	Розв'язування задач: квадратні рівняння	8-Б	17	71	29	2025-12-25 00:00:00
85	Лекція: модернізм в літературі	10-Б	16	97	16	2025-12-26 00:00:00
86	Контрольна робота: оптика	11-А	17	31	18	2025-12-29 00:00:00
87	Практичне заняття: історія Київської Русі	10-А	10	43	21	2025-12-30 00:00:00
88	Повторення: модернізм в літературі	1-В	5	\N	25	2025-12-31 00:00:00
89	Лекція: кліматичні зони	10-А	7	\N	27	2026-01-01 00:00:00
90	Повторення: відсоткові розрахунки	6-А	14	\N	27	2026-01-02 00:00:00
91	Домашнє завдання: логарифми	10-А	1	98	25	2026-01-05 00:00:00
92	Введення в тему: гідросфера	4-В	10	54	15	2026-01-06 00:00:00
93	Тема уроку: гідросфера	3-В	14	50	22	2026-01-07 00:00:00
94	Обговорення: міграція населення	10-Б	6	17	2	2026-01-08 00:00:00
95	Обговорення: фінансова грамотність	8-А	19	11	28	2026-01-09 00:00:00
96	Розв'язування задач: права людини	2-В	2	42	14	2026-01-12 00:00:00
97	Лабораторна: історія Київської Русі	4-Б	13	54	17	2026-01-13 00:00:00
98	Практичне заняття: оптика	6-Б	1	7	23	2026-01-14 00:00:00
99	Практичне заняття: тригонометрія	11-А	2	32	13	2026-01-15 00:00:00
100	Введення в тему: оптика	8-Б	5	61	8	2026-01-16 00:00:00
101	Тема уроку: основи програмування	6-А	9	22	8	2026-01-19 00:00:00
102	Лекція: квадратні рівняння	4-А	4	40	25	2026-01-20 00:00:00
103	Тема уроку: логарифми	1-В	19	81	16	2026-01-21 00:00:00
104	Контрольна робота: Сонячна система	12-Б	20	73	3	2026-01-22 00:00:00
105	Повторення: вектори	5-Б	12	\N	22	2026-01-23 00:00:00
106	Обговорення: лінійні рівняння	12-А	16	\N	24	2026-01-26 00:00:00
107	Розв'язування задач: архітектурні стилі	10-А	5	94	18	2026-01-27 00:00:00
108	Повторення: кібербезпека	11-А	16	94	18	2026-01-28 00:00:00
109	Тема уроку: відсоткові розрахунки	12-А	3	58	16	2026-01-29 00:00:00
110	Розв'язування задач: квадратні рівняння	8-А	20	44	2	2026-01-30 00:00:00
111	Лабораторна: гідросфера	2-В	16	34	22	2026-02-02 00:00:00
112	Домашнє завдання: генетика	10-А	9	67	13	2026-02-03 00:00:00
113	Тема уроку: клітина	10-Б	14	98	16	2026-02-04 00:00:00
114	Розв'язування задач: кліматичні зони	9-А	16	3	6	2026-02-05 00:00:00
115	Тема уроку: електричний струм	5-А	8	75	24	2026-02-06 00:00:00
116	Повторення: гідросфера	7-А	12	96	22	2026-02-09 00:00:00
117	Розв'язування задач: вектори	3-В	10	16	13	2026-02-10 00:00:00
118	Практичне заняття: відсоткові розрахунки	10-Б	18	89	12	2026-02-11 00:00:00
119	Тема уроку: фотосинтез	10-Б	16	76	19	2026-02-12 00:00:00
120	Тема уроку: Сонячна система	4-А	8	39	1	2026-02-13 00:00:00
121	Повторення: кліматичні зони	2-Б	9	\N	4	2026-02-16 00:00:00
122	Контрольна робота: попит і пропозиція	10-А	5	97	32	2026-02-17 00:00:00
123	Введення в тему: Сонячна система	8-А	10	57	22	2026-02-18 00:00:00
124	Введення в тему: хімічні реакції	3-В	16	\N	5	2026-02-19 00:00:00
125	Розв'язування задач: логарифми	1-В	19	7	10	2026-02-20 00:00:00
126	Домашнє завдання: права людини	4-А	3	16	27	2026-02-23 00:00:00
127	Домашнє завдання: кібербезпека	11-Б	20	67	25	2026-02-24 00:00:00
128	Розв'язування задач: історія Київської Русі	4-А	19	40	4	2026-02-25 00:00:00
129	Практичне заняття: кібербезпека	11-А	7	34	6	2026-02-26 00:00:00
130	Тема уроку: хімічні реакції	2-В	18	\N	1	2026-02-27 00:00:00
131	Розв'язування задач: екосистеми	10-А	20	5	15	2026-03-02 00:00:00
132	Контрольна робота: електричний струм	10-А	15	\N	15	2026-03-03 00:00:00
133	Контрольна робота: фінансова грамотність	11-Б	19	26	28	2026-03-04 00:00:00
134	Повторення: Сонячна система	3-Б	5	19	5	2026-03-05 00:00:00
135	Лекція: геометричні фігури	11-Б	10	73	19	2026-03-06 00:00:00
136	Практичне заняття: історія Київської Русі	6-А	10	35	32	2026-03-09 00:00:00
137	Практичне заняття: історія Київської Русі	8-Б	2	95	21	2026-03-10 00:00:00
138	Контрольна робота: кібербезпека	1-А	3	87	2	2026-03-11 00:00:00
139	Контрольна робота: квадратні рівняння	8-А	2	23	31	2026-03-12 00:00:00
140	Розв'язування задач: механічна енергія	3-В	6	56	32	2026-03-13 00:00:00
141	Розв'язування задач: клітина	4-В	14	86	7	2026-03-16 00:00:00
142	Лекція: атомна структура	4-Б	14	37	26	2026-03-17 00:00:00
143	Повторення: оптика	1-Б	15	\N	17	2026-03-18 00:00:00
144	Практичне заняття: відсоткові розрахунки	11-А	13	1	30	2026-03-19 00:00:00
145	Введення в тему: екосистеми	3-А	17	97	32	2026-03-20 00:00:00
146	Розв'язування задач: архітектурні стилі	11-А	2	71	9	2026-03-23 00:00:00
147	Контрольна робота: фінансова грамотність	6-А	16	\N	16	2026-03-24 00:00:00
148	Лекція: кліматичні зони	4-А	18	\N	27	2026-03-25 00:00:00
149	Тема уроку: клітина	12-А	4	16	10	2026-03-26 00:00:00
150	Контрольна робота: гідросфера	7-А	9	62	31	2026-03-27 00:00:00
151	Conflict Test Lesson	5-А	1	\N	1	2025-09-01 08:30:00
153	\N	9-Б	4	\N	12	2025-02-01 00:00:00
163	Math_15_12	1-А	1	\N	1	2025-12-15 00:00:00
164	UA_16_12	1-А	2	\N	1	2025-12-16 00:00:00
165	HistUA_17_12	1-А	15	\N	1	2025-12-17 00:00:00
166	Eng_18_12	1-А	9	\N	1	2025-12-18 00:00:00
167	Phys_19_12	1-А	4	\N	1	2025-12-19 00:00:00
168	Bio_22_12	1-А	6	\N	1	2025-12-22 00:00:00
169	IT_23_12	1-А	13	\N	1	2025-12-23 00:00:00
170	Geo_26_12	1-А	7	\N	1	2025-12-26 00:00:00
171	Lit_30_12	1-А	3	\N	1	2025-12-30 00:00:00
173	Тренер Максим: вибір пива	1-А	10	1	1	2025-12-21 00:00:00
180	Тренер Максим: вибір пива: Deutchebier	10-А	10	6	1	2025-12-20 00:00:00
185	TEST	10-А	6	9	1	2025-11-19 00:00:00
190	TESTS	12-Г	1	12	5	2025-12-19 00:00:00
192	Математика: 2	1-А	1	3	1	2025-12-24 00:00:00
196	ASSSS	1-А	5	1	1	2026-01-10 00:00:00
198	AB	1-А	1	1	1	2026-01-11 00:00:00
205	FUCH	12-Г	19	18	34	2026-01-11 14:00:00
203	ACA	1-А	1	4	1	2026-01-10 08:45:00
206	TEST	1-А	19	18	1	2026-01-11 15:45:00
210	Shittytime	6-А	11	\N	1	2026-01-11 19:24:00
\.


--
-- Data for Name: material; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.material (material_id, material_name, material_desc, material_link) FROM stdin;
1	Тести з математики. Алгебра 7 клас	Тестові запитання для перевірки знань з алгебри 7 класу.	https://naurok.com.ua/files/algebra-7-test.pdf
2	Презентація «Формули скороченого множення»	Слайди для уроку з теми формул скороченого множення.	https://naurok.com.ua/files/formuly-mnozhennya-presentation.pptx
3	Конспект уроку «Лінійні рівняння»	Методичний конспект уроку для вчителя з поясненням рішення лінійних рівнянь.	https://naurok.com.ua/files/linear-equations-concept.docx
4	Математична вікторина «Геометрія 8 клас»	Конкурсна вікторина з геометричних задач для 8 класу.	https://naurok.com.ua/files/geometry-8-quiz.pptx
5	Розробка уроку «Степінь» 9 клас	Урок про степені і властивості степенів для 9-го класу.	https://naurok.com.ua/files/power-lesson-9.pdf
6	Листопадова контрольна робота з географії 6 клас	Тестова контрольна робота з географії, листопад, 6 клас.	https://naurok.com.ua/files/geography-test-6.pdf
7	Практична робота «Процентні розрахунки» 8 клас	Завдання для учнів з обчислення процентів.	https://naurok.com.ua/files/percentage-practice-8.docx
8	Поради для підготовки до ДПА з історії	Методичні поради і матеріали для підготовки до державної підсумкової атестації з історії.	https://naurok.com.ua/files/dpa-history-guide.pdf
9	Презентація «Водні ресурси України»	Слайди з інформацією про водні ресурси та їх використання в Україні.	https://naurok.com.ua/files/water-resources-ukraine.pptx
10	Матеріал «Екосистема біосфери» 10 клас	Тексти, питання та завдання про екосистеми для 10 класу.	https://naurok.com.ua/files/ecosystem-biosphere-10.docx
11	Лабораторна робота «Хімічні реакції» 9 клас	Опис лабораторної роботи з хімії для учнів 9 класу.	https://naurok.com.ua/files/chemistry-lab-9.pdf
12	Тести з біології. Клітина 8 клас	Комплекс тестів про структуру клітини для 8 класу.	https://naurok.com.ua/files/biology-cell-8-test.pdf
13	Конспект уроку «Миттєве та прискорення» Фізика 10 клас	Повний конспект уроку з фізики на тему руху.	https://naurok.com.ua/files/physics-motion-10.docx
14	Розробка уроку «Подорож Україною» (англійська мова, 6 клас)	Урок англійської з темою «Ukraine» для 6 класу.	https://naurok.com.ua/files/ukraine-lesson-6-english.pptx
15	Презентація «Сонячна система» 7 клас	Слайди про планети сонячної системи для учнів 7 класу.	https://naurok.com.ua/files/solar-system-7.pptx
16	Тест «Українська література: Шевченко» 11 клас	Контрольні запитання про творчість Тараса Шевченка.	https://naurok.com.ua/files/shevchenko-11-test.pdf
17	Матеріал для класу «Інформатика 8» — алгоритми	Тексти та завдання про алгоритми для уроку інформатики.	https://naurok.com.ua/files/algorithms-8.docx
18	Конспект уроку «Правильні дроби» 6 клас	Методичний конспект з математики: правильні дроби.	https://naurok.com.ua/files/proper-fractions-6.docx
19	Розробка уроку «Типи речень» (Українська мова, 7 клас)	Матеріал та вправи для вивчення типів речень.	https://naurok.com.ua/files/sentence-types-7-ukr.pdf
20	Презентація «Громадянська освіта: права та обов’язки» 9 клас	Матеріали для уроку громадянської освіти про права людини.	https://naurok.com.ua/files/civics-rights-9.pptx
21	Практична робота «Генетика» 11 клас	Завдання лабораторної роботи з генетики для старших класів.	https://naurok.com.ua/files/genetics-lab-11.pdf
22	Тести з історії України. XX століття, 10 клас	Контрольні запитання про історію України в XX ст.	https://naurok.com.ua/files/ukraine-history-20th-10-test.pdf
23	Конспект уроку «Електричний струм» 9 клас (фізика)	Урок-конспект з фізики про електричний струм і його властивості.	https://naurok.com.ua/files/electric-current-9.docx
24	Презентація «Кліматичні зони» (географія, 8 клас)	Слайди про кліматичні зони світу та України.	https://naurok.com.ua/files/climate-zones-8.pptx
25	Матеріали «Літературне читання: Лис Микита» 5 клас	Тексти, питання та аналіз твору Лиса Микити для 5 класу.	https://naurok.com.ua/files/fox-mykita-5-literature.docx
26	Тест «Правопис суфіксів» (Українська мова, 9 клас)	Тестові завдання з правопису суфіксів української мови.	https://naurok.com.ua/files/suffix-spelling-9-test.pdf
27	Практичне заняття «Гідросфера» (географія, 7 клас)	Матеріал з гідросфери: водні ресурси, круговорот води.	https://naurok.com.ua/files/hydrosphere-7.docx
28	Розробка уроку «Світові релігії» (історія, 8 клас)	Урок про основні світові релігії для 8 класу.	https://naurok.com.ua/files/world-religions-8.pdf
29	Лабораторна робота «Кислоти та основи» (хімія, 10 клас)	Практична робота про властивості кислот та основ.	https://naurok.com.ua/files/acids-bases-10-lab.pdf
30	Презентація «Фотосинтез» (біологія, 9 клас)	Слайди про процес фотосинтезу для уроку біології.	https://naurok.com.ua/files/photosynthesis-9.pptx
31	Конспект уроку «Тригонометрія — синус і косинус» (математика, 10 клас)	Методичний конспект з тригонометрії.	https://naurok.com.ua/files/trig-sin-cos-10.docx
32	Матеріал «Музичні жанри: класика, джаз, рок» (мистецтво, 9 клас)	Огляд музичних жанрів з аудіо-прикладами.	https://naurok.com.ua/files/music-genres-9.docx
33	Презентація «Здоров’я та спорт» (фізкультура, 8 клас)	Матеріали для обговорення здорового способу життя в класі.	https://naurok.com.ua/files/health-sport-8.pptx
34	Тест «Функції лінійної змінної» (математика, 9 клас)	Контрольні завдання з функцій.	https://naurok.com.ua/files/linear-function-9-test.pdf
35	Практична робота «Закони Ньютона» (фізика, 10 клас)	Завдання лабораторної роботи зі статики та динаміки.	https://naurok.com.ua/files/newtons-laws-10-lab.docx
36	Розробка уроку «Етика взаємодії людей» (громадянська), 9 клас	Урок із вправами на етичні дилеми та обговорення.	https://naurok.com.ua/files/ethics-9-lesson.pdf
37	Матеріал «Стародавній Єгипет» (історія, 6 клас)	Тексти, зображення та питання про Єгипет.	https://naurok.com.ua/files/ancient-egypt-6.docx
38	Презентація «Кровообіг людини» (біологія, 10 клас)	Слайди про систему кровообігу людини.	https://naurok.com.ua/files/circulatory-system-10.pptx
39	Конспект уроку «Сила тяжіння» (фізика, 9 клас)	Урок-конспект про гравітацію та її прояви.	https://naurok.com.ua/files/gravity-9.docx
40	Тест «Фразеологізми в українській мові» (українська, 10 клас)	Перевірка знань про фразеологізми.	https://naurok.com.ua/files/idioms-ukr-10-test.pdf
41	Практична робота «Механічна енергія» (фізика, 11 клас)	Завдання про кінетичну та потенціальну енергію.	https://naurok.com.ua/files/mechanical-energy-11-lab.pdf
42	Матеріал «Середньовічна Україна» (історія, 7 клас)	Тексти і карти про життя в середньовічній Україні.	https://naurok.com.ua/files/medieval-ukraine-7.docx
43	Розробка уроку «Звукові хвилі» (фізика, 10 клас)	Урок про хвилі, частоту та амплітуду.	https://naurok.com.ua/files/sound-waves-10.pdf
44	Презентація «Роль води у природі» (географія, 6 клас)	Слайди про значення води у довкіллі.	https://naurok.com.ua/files/water-role-6.pptx
45	Конспект уроку «Генерація електрики» (фізика, 11 клас)	Матеріали для обговорення генераторів та електростанцій.	https://naurok.com.ua/files/electricity-generation-11.docx
46	Тести з хімії «Газові закони» (хімія, 11 клас)	Перевірка знань про поведінку газів.	https://naurok.com.ua/files/gas-laws-11-test.pdf
47	Практична робота «Опір провідника» (фізика, 9 клас)	Експериментальні завдання про електричний опір.	https://naurok.com.ua/files/resistance-lab-9.docx
48	Розробка уроку «Макроекономіка: попит та пропозиція» (економіка, 11 клас)	Урок з теорією попиту, пропозиції та ринків.	https://naurok.com.ua/files/macro-demand-supply-11.pdf
49	Матеріал «Права людини» (громадянська освіта, 10 клас)	Тексти і ситуаційні задачі про права людини.	https://naurok.com.ua/files/human-rights-10.docx
50	Презентація «Атомна структура» (хімія, 9 клас)	Слайди про атоми, електрони, протони.	https://naurok.com.ua/files/atomic-structure-9.pptx
51	Конспект уроку «Геометричні фігури: коло» (геометрія, 7 клас)	Методичний конспект про коло, радіус, діаметр.	https://naurok.com.ua/files/circle-7.docx
52	Практична робота «Розкладання многочленів» (алгебра, 10 клас)	Завдання на факторизацію многочленів.	https://naurok.com.ua/files/polynomial-factorization-10-lab.pdf
53	Тест «Електромагнітне поле» (фізика, 11 клас)	Контрольні питання про електромагнітні явища.	https://naurok.com.ua/files/em-field-11-test.pdf
54	Матеріал «Найвідоміші українські письменники» (література, 8 клас)	Біографії та аналіз творів видатних письменників.	https://naurok.com.ua/files/ukr-writers-8.docx
55	Розробка уроку «Глобальні зміни клімату» (географія, 11 клас)	Теми: парниковий ефект, зміна клімату, наслідки.	https://naurok.com.ua/files/climate-change-11.pdf
56	Презентація «Скелет людини» (біологія, 8 клас)	Слайди про кісткову систему людини.	https://naurok.com.ua/files/human-skeleton-8.pptx
57	Практична робота «Хімічні зв’язки» (хімія, 10 клас)	Експериментальні завдання про ковалентні та йонні зв’язки.	https://naurok.com.ua/files/chemical-bonds-10-lab.docx
58	Матеріал «Інформатика: введення в програмування» 9 клас	Основи програмування, змінні, цикли.	https://naurok.com.ua/files/programming-9.txt
59	Конспект уроку «Основи демократії» (громадянська, 10 клас)	Урок про демократію, вибори, громадянські права.	https://naurok.com.ua/files/democracy-10.docx
60	Тест «Екосистеми та біорізноманіття» (біологія, 10 клас)	Контрольні запитання про екосистеми.	https://naurok.com.ua/files/ecosystem-test-10.pdf
61	Презентація «Складні речення» (українська мова, 9 клас)	Слайди про складні та прості речення.	https://naurok.com.ua/files/complex-sentences-9.pptx
62	Розробка уроку «Слов’янські мови» (мовознавство, 11 клас)	Тексти і вправи про слов’янські мови та їх зв’язки.	https://naurok.com.ua/files/slavic-languages-11.pdf
63	Практична робота «Періоди напіврозпаду» (хімія, 11 клас)	Завдання на напіврозпад радіоактивних елементів.	https://naurok.com.ua/files/half-life-11-lab.pdf
64	Матеріал «Літературні течії XX століття» (література, 11 клас)	Огляд модернізму, реалізму, авангарду тощо.	https://naurok.com.ua/files/literary-movements-11.docx
65	Тест «Квадратні рівняння» (математика, 10 клас)	Контрольна робота з задач на квадратні рівняння.	https://naurok.com.ua/files/quadratic-equations-10-test.pdf
66	Конспект уроку «Фізика магнітного поля» (фізика, 11 клас)	Методичний конспект для уроку магнітного поля.	https://naurok.com.ua/files/magnetic-field-11.docx
67	Розробка уроку «Світова економіка» (економіка, 12 клас)	Урок про глобалізацію, економічні системи та ринки.	https://naurok.com.ua/files/world-economy-12.pdf
68	Презентація «Генетичне кодування ДНК» (біологія, 11 клас)	Слайди про структуру ДНК і генетичний код.	https://naurok.com.ua/files/dna-genetic-code-11.pptx
69	Матеріал «Методи статистики» (математика, 12 клас)	Вступ до статистичних методів: середнє, мода, дисперсія.	https://naurok.com.ua/files/statistics-methods-12.pdf
70	Практична робота «Енергія фотона» (фізика, 12 клас)	Завдання з розрахунку енергії світла.	https://naurok.com.ua/files/photon-energy-12-lab.docx
71	Тест «Геометричні трансформації» (геометрія, 10 клас)	Контрольні запитання по симетрії, паралельному перенесенню, обертанню.	https://naurok.com.ua/files/geometry-transformations-10-test.pdf
72	Конспект уроку «Типи функцій» (математика, 11 клас)	Огляд лінійних, квадратичних, кубічних функцій.	https://naurok.com.ua/files/function-types-11.docx
73	Розробка уроку «Українська культура та традиції» (історія, 7 клас)	Урок з темами традицій, культури, побуту на території України.	https://naurok.com.ua/files/ukr-culture-7.pdf
74	Матеріал «Основи робототехніки» (інформатика, 12 клас)	Теоретичний матеріал про роботи, сенсори, рух.	https://naurok.com.ua/files/robotics-12.docx
75	Презентація «Права дитини» (громадянська освіта, 7 клас)	Слайди з правами та обов’язками дитини згідно з конвенцією.	https://naurok.com.ua/files/child-rights-7.pptx
76	Тест «Закони концентрації речовин» (хімія, 10 клас)	Завдання на поняття концентрації, молярності, розчинів.	https://naurok.com.ua/files/concentration-laws-10-test.pdf
77	Практична робота «Сила Архімеда» (фізика, 10 клас)	Завдання з архімедовою силою і плавучістю.	https://naurok.com.ua/files/archimedes-force-10-lab.pdf
78	Конспект уроку «Міграція населення» (географія, 12 клас)	Урок про тенденції та причини міграції людей.	https://naurok.com.ua/files/migration-12.docx
79	Розробка уроку «Генератори електромагнітного поля» (фізика, 12 класс)	Матеріал для уроку про генератори, електростанції.	https://naurok.com.ua/files/generators-12.pdf
80	Матеріал «Вплив людини на довкілля» (екологія, 11 клас)	Тексти та завдання про екологічні проблеми.	https://naurok.com.ua/files/human-impact-11.docx
81	Презентація «Мови Східної Європи» (мовознавство, 11 клас)	Слайди про поширення мов у Східній Європі.	https://naurok.com.ua/files/eastern-europe-langs-11.pptx
82	Тест «Енергетичні ресурси України» (географія, 11 клас)	Контрольні запитання про ресурси та енергетику.	https://naurok.com.ua/files/energy-resources-ukraine-11-test.pdf
83	Конспект уроку «Стихії природи» (географія, 7 клас)	Урок-конспект про стихійні лиха, їхні причини та наслідки.	https://naurok.com.ua/files/natural-disasters-7.docx
84	Практична робота «Фотометрія» (фізика, 11 клас)	Завдання для визначення світлових величин та яскравості.	https://naurok.com.ua/files/photometry-11-lab.pdf
85	Матеріал «Серцево-судинна система» (біологія, 10 клас)	Тексти, графіки та вправи про серце та судини.	https://naurok.com.ua/files/cardio-system-10.docx
86	Розробка уроку «Кібербезпека» (інформатика, 11 клас)	Матеріал з основ кібербезпеки, паролів, фішингу.	https://naurok.com.ua/files/cybersecurity-11.pdf
87	Презентація «Сучасні технології» (інформатика, 10 клас)	Слайди про AI, роботи, інтернет речей.	https://naurok.com.ua/files/modern-tech-10.pptx
88	Тест «Арифметичні прогресії» (математика, 11 клас)	Контрольні задачі про прогресії.	https://naurok.com.ua/files/arithmetic-prog-11-test.pdf
89	Практична робота «Магнітна індукція» (фізика, 12 клас)	Завдання з індукцією, силою Лоренца.	https://naurok.com.ua/files/magnetic-induction-12-lab.docx
90	Конспект уроку «Становлення Київської Русі» (історія, 5 клас)	Урок-конспект про формування середньовічної держави.	https://naurok.com.ua/files/kievan-rus-5.docx
91	Матеріал «Молекулярна біологія: РНК і ДНК» (біологія, 12 клас)	Тексти та схеми про РНК, ДНК та їх функції.	https://naurok.com.ua/files/molecular-bio-12.docx
92	Презентація «Гравітаційні хвилі» (фізика, 12 клас)	Слайди про гравітаційні хвилі та їх відкриття.	https://naurok.com.ua/files/gravitational-waves-12.pptx
93	Тест «Економічні кризи» (економіка, 12 клас)	Запитання про кризи, рецесію, інфляцію.	https://naurok.com.ua/files/economic-crisis-12-test.pdf
94	Практична робота «Молекулярні реакції» (хімія, 11 клас)	Завдання на реакції молекул та їх перетворення.	https://naurok.com.ua/files/molecular-reactions-11-lab.pdf
95	Розробка уроку «Міфи та легенди України» (історія, 6 клас)	Матеріал про легенди, міфи та їх значення у культурі.	https://naurok.com.ua/files/myths-ukraine-6.pdf
96	Матеріал «Еволюція організмів» (біологія, 11 клас)	Теорії еволюції, приклади, питання для обговорення.	https://naurok.com.ua/files/evolution-11.docx
97	Презентація «Геометрія простору: куб, циліндр» (геометрія, 9 клас)	Слайди про об’єм, площу поверхні, об’єкти 3D.	https://naurok.com.ua/files/3d-geometry-9.pptx
98	Конспект уроку «Німеччина після Другої світової» (історія, 11 клас)	Урок про повоєнну Європу після 1945 року.	https://naurok.com.ua/files/germany-postwar-11.docx
99	Тест «Хімія органічних сполук» (хімія, 12 клас)	Контрольна з органічної хімії.	https://naurok.com.ua/files/organic-chemistry-12-test.pdf
100	Практична робота «Теплоємність» (фізика, 11 клас)	Завдання на визначення теплоємності речовин.	https://naurok.com.ua/files/specific-heat-11-lab.pdf
101	Розробка уроку «Світове мистецтво» (мистецтво, 8 клас)	Матеріал про течії, стилі і видатних художників світу.	https://naurok.com.ua/files/world-art-8.pdf
102	Матеріал «Уранці духовні поезії» (література, 10 клас)	Збірка віршів, аналіз та питання для учнів.	https://naurok.com.ua/files/spiritual-poems-10.docx
103	Презентація «Вода як розчинник» (хімія, 9 клас)	Слайди про властивості води як розчинника.	https://naurok.com.ua/files/water-solvent-9.pptx
104	Конспект уроку «Паралельні прямі» (геометрія, 7 клас)	Методичний план уроку про паралельні прямі та кути.	https://naurok.com.ua/files/parallel-lines-7.docx
105	Практична робота «Кінематика поверхні» (фізика, 10 клас)	Завдання на рух по кривій поверхні.	https://naurok.com.ua/files/surface-kinematics-10-lab.pdf
106	Тест «Електронна конфігурація атомів» (хімія, 11 клас)	Питання про розподіл електронів в атомах.	https://naurok.com.ua/files/electron-config-11-test.pdf
107	Матеріал «Правознавство: конституція України» (громадянська освіта, 10 клас)	Документи, питання та тести про Конституцію України.	https://naurok.com.ua/files/constitution-ukraine-10.docx
108	Розробка уроку «Фольклорні жанри» (література, 7 клас)	Матеріали про літературні жанри фольклору України.	https://naurok.com.ua/files/folk-genres-7.pdf
109	Презентація «Мікроорганізми» (біологія, 9 класс)	Слайди про бактерії, віруси, гриби.	https://naurok.com.ua/files/microorganisms-9.pptx
110	Практична робота «Оптичні явища» (фізика, 11 клас)	Завдання щодо заломлення світла, лінз.	https://naurok.com.ua/files/optics-11-lab.docx
111	Конспект уроку «Податки та бюджет» (економіка, 11 клас)	Урок-конспект про податкову систему та бюджет держави.	https://naurok.com.ua/files/taxes-budget-11.docx
112	Матеріал «Українська революція 1917-1921» (історія, 10 клас)	Історичні джерела, тексти та запитання.	https://naurok.com.ua/files/ukr-revolution-10.docx
113	Тест «Географія України: регіони» (географія, 9 клас)	Контрольні питання про географічні регіони України.	https://naurok.com.ua/files/ukraine-regions-9-test.pdf
114	Презентація «Психологія підлітка» (освіта, 11 клас)	Матеріали для обговорення особистості та емоцій підлітків.	https://naurok.com.ua/files/teen-psychology-11.pptx
115	Практична робота «Радіоактивність» (фізика, 12 клас)	Завдання на радіоактивний розпад.	https://naurok.com.ua/files/radioactivity-12-lab.pdf
116	Конспект уроку «Електроліти» (хімія, 11 клас)	План уроку під час вивчення електролітів.	https://naurok.com.ua/files/electrolytes-11.docx
117	Матеріал «Антична Греція» (історія, 6 клас)	Тексти, мапи, питання про Грецію.	https://naurok.com.ua/files/ancient-greece-6.docx
118	Розробка уроку «Види мистецтва» (мистецтво, 9 клас)	Сценарій уроку про живопис, скульптуру, архітектуру.	https://naurok.com.ua/files/types-of-art-9.pdf
119	Презентація «Гормони й ендокринна система» (біологія, 11 клас)	Слайди про ендокринні залози та їх функції.	https://naurok.com.ua/files/hormones-endocrine-11.pptx
120	Тест «Синтаксис простого речення» (українська мова, 8 клас)	Перевірка знань про синтаксис простих речень.	https://naurok.com.ua/files/syntax-simple-8-test.pdf
121	Практична робота «Електромагнітна індукція» (фізика, 12 клас)	Вимірювання індукційних струмів.	https://naurok.com.ua/files/em-induction-12-lab.docx
122	Конспект уроку «Сталий розвиток» (екологія, 12 клас)	Урок-конспект про сталий розвиток та екосистеми.	https://naurok.com.ua/files/sustainable-development-12.docx
123	Матеріал «Імена світу: географія та культура» (географія, 11 клас)	Огляд міст, країн та культур світу.	https://naurok.com.ua/files/world-names-11.docx
124	Розробка уроку «Фінансова грамотність» (економіка, 10 клас)	Матеріал про гроші, банківські рахунки і бюджет сім’ї.	https://naurok.com.ua/files/financial-literacy-10.pdf
\.


--
-- Data for Name: parents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parents (parent_id, parent_name, parent_surname, parent_patronym, parent_phone, parent_user_id) FROM stdin;
12	Віра	Козак	Петроівна	063-002-2011	12
5	Світлана	Бойко	Дмитроівна	050-002-2004	5
18	Степан	Сидоренко	Тарасович	096-002-2017	18
20	Аліна	Кравченко	Віталійівна	063-002-2019	20
21	Данило	Петренко	Віталийович	068-002-2020	21
19	Лілія	Сидоренко	Віталийівна	097-002-2018	19
22	Еліна	Петренко	Левівна	063-002-2021	22
24	Меланія	Дмитренко	Максимівна	067-002-2023	24
23	Арсен	Дмитренко	Геннадійович	050-002-2022	23
25	Дарина	Микитенко	Віталийівна	095-002-2024	25
26	Вадим	Литвин	Максимович	066-002-2025	26
28	Богдан	Савченко	Ярославович	096-002-2027	28
27	Поліна	Литвин	Степанівна	039-002-2026	27
29	Карина	Савченко	Борисівна	097-002-2028	29
30	Анна	Кравчук	Максимівна	096-002-2029	30
31	Єгор	Ткач	Борисович	068-002-2030	31
32	Марія	Ткач	Арсенівна	063-002-2031	32
33	Федір	Шевчук	Данилоович	050-002-2032	33
36	Олександр	Коцюбинська	Ростиславович	066-002-2035	36
34	Наталія	Шевчук	Ростиславівна	067-002-2033	34
35	Марта	Грищенко	Борисівна	068-002-2034	35
37	Олена	Коцюбинська	Богданівна	039-002-2036	37
40	Яна	Поліщук	Ростиславівна	067-002-2039	40
39	Тетяна	Черненко	Костянтинівна	097-002-2038	39
38	Володимир	Черненко	Вадимович	096-002-2037	38
41	Сергій	Бондаренко	Костянтинович	068-002-2040	41
42	Людмила	Бондаренко	Федірівна	063-002-2041	42
43	Дмитро	Соловйова	Єгорович	050-002-2042	43
46	Юрій	Іваненко	Артемович	066-002-2045	46
45	Ірина	Мацюк	Костянтинівна	039-002-2044	45
47	Надія	Іваненко	Володимирівна	039-002-2046	47
49	Світлана	Левченко	Андрійівна	097-002-2048	49
50	Ганна	Демченко	Артемівна	098-002-2049	50
51	Євген	Коваль	Андрійович	068-002-2050	51
52	Марина	Коваль	Дмитроівна	063-002-2051	52
53	Роман	Романенко	Сергійович	050-002-2052	53
54	Тамара	Романенко	Миколаівна	067-002-2053	54
55	Вікторія	Ковальський	Андрійівна	050-002-2054	55
56	Петро	Бойченко	Миколаович	066-002-2055	56
57	Валентина	Бойченко	Павлоівна	039-002-2056	57
59	Зоряна	Павленко	Ігорівна	097-002-2058	59
58	Віталій	Павленко	Юрійович	096-002-2057	58
61	Василь	Клименко	Ігорович	068-002-2060	61
60	Люба	Пономаренко	Миколаівна	066-002-2059	60
62	Катерина	Клименко	Романівна	063-002-2061	62
63	Віталий	Кириченко	Євгенович	050-002-2062	63
65	Роксолана	Мартинюк	Ігорівна	097-002-2064	65
64	Аліна	Кириченко	Олегівна	067-002-2063	64
66	Лев	Зайцев	Олегович	066-002-2065	66
67	Єва	Зайцев	Віталійівна	039-002-2066	67
69	Дарина	Мартиненко	Тарасівна	097-002-2068	69
68	Максим	Мартиненко	Петроович	096-002-2067	68
70	Орися	Остапенко	Олегівна	063-002-2069	70
71	Степан	Кузьменко	Тарасович	068-002-2070	71
72	Лілія	Кузьменко	Віталийівна	063-002-2071	72
73	Борис	Пилипчук	Васильович	050-002-2072	73
74	Анна	Пилипчук	Геннадійівна	067-002-2073	74
75	Віра	Симоненко	Тарасівна	095-002-2074	75
76	Арсен	Проценко	Геннадійович	066-002-2075	76
77	Меланія	Проценко	Максимівна	039-002-2076	77
78	Ростислав	Олексієнко	Левович	096-002-2077	78
79	Марта	Олексієнко	Ярославівна	097-002-2078	79
80	Софія	Корсун	Геннадійівна	096-002-2079	80
82	Карина	Нечипоренко	Борисівна	063-002-2081	82
83	Костянтин	Мірошниченко	Степанович	050-002-2082	83
93	Андрій	Ткаченко	Богданович	050-002-2092	93
94	Ганна	Ткаченко	Єгорівна	067-002-2093	94
95	Марія	Козак	Вадимівна	039-002-2094	95
96	Дмитро	Руденко	Єгорович	066-002-2095	96
97	Оксана	Руденко	Артемівна	039-002-2096	97
98	Микола	Федоренко	Федірович	096-002-2097	98
99	Вікторія	Федоренко	Олександрівна	097-002-2098	99
100	Олена	Білик	Єгорівна	098-002-2099	100
102	Світлана	Сидоренко	Андрійівна	063-002-2101	102
103	Ігор	Кравченко	Володимирович	050-002-2102	103
104	Люба	Кравченко	Сергійівна	067-002-2103	104
106	Роман	Дмитренко	Сергійович	066-002-2105	106
11	Геннадій	Козак	Романович	068-002-2010	828
105	Людмила	Петренко	Олександрівна	050-002-2104	105
107	Тамара	Дмитренко	Миколаівна	039-002-2106	107
108	Олег	Микитенко	Дмитроович	096-002-2107	108
109	Роксолана	Микитенко	Юрійівна	097-002-2108	109
111	Віталій	Савченко	Юрійович	068-002-2110	111
112	Зоряна	Савченко	Ігорівна	063-002-2111	112
113	Тарас	Кравчук	Павлоович	050-002-2112	113
114	Орися	Кравчук	Євгенівна	067-002-2113	114
115	Марина	Ткач	Юрійівна	097-002-2114	115
116	Віталий	Шевчук	Євгенович	066-002-2115	116
117	Аліна	Шевчук	Олегівна	039-002-2116	117
118	Геннадій	Грищенко	Романович	096-002-2117	118
119	Віра	Грищенко	Петроівна	097-002-2118	119
120	Валентина	Коцюбинська	Євгенівна	063-002-2119	120
121	Максим	Черненко	Петроович	068-002-2120	121
123	Ярослав	Поліщук	Віталійович	050-002-2122	123
124	Софія	Поліщук	Васильівна	067-002-2123	124
125	Катерина	Бондаренко	Петроівна	095-002-2124	125
126	Борис	Соловйова	Васильович	066-002-2125	126
128	Данило	Мацюк	Віталийович	096-002-2127	128
127	Анна	Соловйова	Геннадійівна	039-002-2126	127
129	Еліна	Мацюк	Левівна	097-002-2128	129
130	Єва	Іваненко	Васильівна	096-002-2129	130
131	Ростислав	Левченко	Левович	068-002-2130	131
133	Вадим	Демченко	Максимович	050-002-2132	133
134	Поліна	Демченко	Степанівна	067-002-2133	134
135	Лілія	Коваль	Левівна	068-002-2134	135
136	Костянтин	Романенко	Степанович	066-002-2135	136
137	Яна	Романенко	Данилоівна	039-002-2136	137
139	Марія	Ковальський	Арсенівна	097-002-2138	139
140	Меланія	Бойченко	Степанівна	067-002-2139	140
138	Єгор	Ковальський	Борисович	096-002-2137	138
141	Артем	Павленко	Арсенович	068-002-2140	141
143	Олександр	Пономаренко	Ростиславович	050-002-2142	143
144	Олена	Пономаренко	Богданівна	067-002-2143	144
145	Карина	Клименко	Арсенівна	039-002-2144	145
146	Андрій	Кириченко	Богданович	066-002-2145	146
147	Ганна	Кириченко	Єгорівна	039-002-2146	147
148	Сергій	Мартинюк	Костянтинович	096-002-2147	148
149	Людмила	Мартинюк	Федірівна	097-002-2148	149
150	Наталія	Зайцев	Богданівна	098-002-2149	150
151	Микола	Мартиненко	Федірович	068-002-2150	151
153	Юрій	Остапенко	Артемович	050-002-2152	153
154	Надія	Остапенко	Володимирівна	067-002-2153	154
155	Тетяна	Кузьменко	Федірівна	050-002-2154	155
156	Ігор	Пилипчук	Володимирович	066-002-2155	156
157	Люба	Пилипчук	Сергійівна	039-002-2156	157
158	Євген	Симоненко	Андрійович	096-002-2157	158
159	Марина	Симоненко	Дмитроівна	097-002-2158	159
160	Оксана	Проценко	Володимирівна	066-002-2159	160
161	Олег	Олексієнко	Дмитроович	068-002-2160	161
162	Роксолана	Олексієнко	Юрійівна	063-002-2161	162
164	Валентина	Корсун	Павлоівна	067-002-2163	164
165	Світлана	Нечипоренко	Дмитроівна	097-002-2164	165
174	Єва	Гончар	Віталійівна	067-002-2173	174
176	Ярослав	Ткаченко	Віталійович	066-002-2175	176
175	Зоряна	Мельник	Романівна	095-002-2174	175
177	Софія	Ткаченко	Васильівна	039-002-2176	177
178	Степан	Козак	Тарасович	096-002-2177	178
179	Лілія	Козак	Віталийівна	097-002-2178	179
180	Аліна	Руденко	Віталійівна	096-002-2179	180
184	Меланія	Білик	Максимівна	067-002-2183	184
185	Дарина	Сидоренко	Віталийівна	068-002-2184	185
186	Вадим	Кравченко	Максимович	066-002-2185	186
187	Поліна	Кравченко	Степанівна	039-002-2186	187
188	Богдан	Петренко	Ярославович	096-002-2187	188
189	Карина	Петренко	Борисівна	097-002-2188	189
190	Анна	Дмитренко	Максимівна	067-002-2189	190
191	Єгор	Микитенко	Борисович	068-002-2190	191
193	Федір	Литвин	Данилоович	050-002-2192	193
194	Наталія	Литвин	Ростиславівна	067-002-2193	194
195	Марта	Савченко	Борисівна	039-002-2194	195
196	Олександр	Кравчук	Ростиславович	066-002-2195	196
197	Олена	Кравчук	Богданівна	039-002-2196	197
198	Володимир	Ткач	Вадимович	096-002-2197	198
199	Тетяна	Ткач	Костянтинівна	097-002-2198	199
200	Яна	Шевчук	Ростиславівна	098-002-2199	200
201	Сергій	Грищенко	Костянтинович	068-002-2200	201
202	Людмила	Грищенко	Федірівна	063-002-2201	202
204	Оксана	Коцюбинська	Артемівна	067-002-2203	204
205	Ірина	Черненко	Костянтинівна	050-002-2204	205
207	Надія	Поліщук	Володимирівна	039-002-2206	207
210	Ганна	Соловйова	Артемівна	066-002-2209	210
206	Юрій	Поліщук	Артемович	066-002-2205	206
212	Марина	Мацюк	Дмитроівна	063-002-2211	212
211	Євген	Мацюк	Андрійович	068-002-2210	211
208	Павло	Бондаренко	Олександрович	096-002-2207	208
209	Світлана	Бондаренко	Андрійівна	097-002-2208	209
213	Роман	Іваненко	Сергійович	050-002-2212	213
214	Тамара	Іваненко	Миколаівна	067-002-2213	214
215	Вікторія	Левченко	Андрійівна	097-002-2214	215
216	Петро	Демченко	Миколаович	066-002-2215	216
217	Валентина	Демченко	Павлоівна	039-002-2216	217
218	Віталій	Коваль	Юрійович	096-002-2217	218
219	Зоряна	Коваль	Ігорівна	097-002-2218	219
220	Люба	Романенко	Миколаівна	063-002-2219	220
221	Василь	Ковальський	Ігорович	068-002-2220	221
223	Віталий	Бойченко	Євгенович	050-002-2222	223
224	Аліна	Бойченко	Олегівна	067-002-2223	224
225	Роксолана	Павленко	Ігорівна	095-002-2224	225
226	Лев	Пономаренко	Олегович	066-002-2225	226
227	Єва	Пономаренко	Віталійівна	039-002-2226	227
228	Максим	Клименко	Петроович	096-002-2227	228
229	Дарина	Клименко	Тарасівна	097-002-2228	229
230	Орися	Кириченко	Олегівна	096-002-2229	230
231	Степан	Мартинюк	Тарасович	068-002-2230	231
233	Борис	Зайцев	Васильович	050-002-2232	233
234	Анна	Зайцев	Геннадійівна	067-002-2233	234
235	Віра	Мартиненко	Тарасівна	068-002-2234	235
236	Арсен	Остапенко	Геннадійович	066-002-2235	236
237	Меланія	Остапенко	Максимівна	039-002-2236	237
238	Ростислав	Кузьменко	Левович	096-002-2237	238
239	Марта	Кузьменко	Ярославівна	097-002-2238	239
240	Софія	Пилипчук	Геннадійівна	067-002-2239	240
241	Богдан	Симоненко	Ярославович	068-002-2240	241
243	Костянтин	Проценко	Степанович	050-002-2242	243
244	Яна	Проценко	Данилоівна	067-002-2243	244
245	Еліна	Олексієнко	Ярославівна	039-002-2244	245
246	Федір	Корсун	Данилоович	066-002-2245	246
247	Наталія	Корсун	Ростиславівна	039-002-2246	247
248	Артем	Нечипоренко	Арсенович	096-002-2247	248
254	Ганна	Ковальчук	Єгорівна	067-002-2253	254
255	Марія	Бойко	Вадимівна	050-002-2254	255
256	Дмитро	Гончар	Єгорович	066-002-2255	256
257	Оксана	Гончар	Артемівна	039-002-2256	257
259	Вікторія	Мельник	Олександрівна	097-002-2258	259
260	Олена	Ткаченко	Єгорівна	066-002-2259	260
265	Людмила	Федоренко	Олександрівна	097-002-2264	265
266	Роман	Білик	Сергійович	066-002-2265	266
267	Тамара	Білик	Миколаівна	039-002-2266	267
268	Олег	Сидоренко	Дмитроович	096-002-2267	268
269	Роксолана	Сидоренко	Юрійівна	097-002-2268	269
270	Надія	Кравченко	Сергійівна	063-002-2269	270
271	Віталій	Петренко	Юрійович	068-002-2270	271
272	Зоряна	Петренко	Ігорівна	063-002-2271	272
273	Тарас	Дмитренко	Павлоович	050-002-2272	273
275	Марина	Микитенко	Юрійівна	095-002-2274	275
276	Віталий	Литвин	Євгенович	066-002-2275	276
277	Аліна	Литвин	Олегівна	039-002-2276	277
278	Геннадій	Савченко	Романович	096-002-2277	278
279	Віра	Савченко	Петроівна	097-002-2278	279
280	Валентина	Кравчук	Євгенівна	096-002-2279	280
281	Максим	Ткач	Петроович	068-002-2280	281
282	Дарина	Ткач	Тарасівна	063-002-2281	282
283	Ярослав	Шевчук	Віталійович	050-002-2282	283
284	Софія	Шевчук	Васильівна	067-002-2283	284
285	Катерина	Грищенко	Петроівна	068-002-2284	285
286	Борис	Коцюбинська	Васильович	066-002-2285	286
287	Анна	Коцюбинська	Геннадійівна	039-002-2286	287
288	Данило	Черненко	Віталийович	096-002-2287	288
290	Єва	Поліщук	Васильівна	067-002-2289	290
289	Еліна	Черненко	Левівна	097-002-2288	289
291	Ростислав	Бондаренко	Левович	068-002-2290	291
292	Марта	Бондаренко	Ярославівна	063-002-2291	292
294	Поліна	Соловйова	Степанівна	067-002-2293	294
295	Лілія	Мацюк	Левівна	039-002-2294	295
296	Костянтин	Іваненко	Степанович	066-002-2295	296
297	Яна	Іваненко	Данилоівна	039-002-2296	297
298	Єгор	Левченко	Борисович	096-002-2297	298
299	Марія	Левченко	Арсенівна	097-002-2298	299
300	Меланія	Демченко	Степанівна	098-002-2299	300
301	Артем	Коваль	Арсенович	068-002-2300	301
302	Ірина	Коваль	Вадимівна	063-002-2301	302
304	Олена	Романенко	Богданівна	067-002-2303	304
305	Карина	Ковальський	Арсенівна	050-002-2304	305
306	Андрій	Бойченко	Богданович	066-002-2305	306
307	Ганна	Бойченко	Єгорівна	039-002-2306	307
308	Сергій	Павленко	Костянтинович	096-002-2307	308
309	Людмила	Павленко	Федірівна	097-002-2308	309
310	Наталія	Пономаренко	Богданівна	066-002-2309	310
313	Юрій	Кириченко	Артемович	050-002-2312	313
312	Вікторія	Клименко	Олександрівна	063-002-2311	312
314	Надія	Кириченко	Володимирівна	067-002-2313	314
315	Тетяна	Мартинюк	Федірівна	097-002-2314	315
316	Ігор	Зайцев	Володимирович	066-002-2315	316
317	Люба	Зайцев	Сергійівна	039-002-2316	317
318	Євген	Мартиненко	Андрійович	096-002-2317	318
319	Марина	Мартиненко	Дмитроівна	097-002-2318	319
320	Оксана	Остапенко	Володимирівна	063-002-2319	320
321	Олег	Кузьменко	Дмитроович	068-002-2320	321
322	Роксолана	Кузьменко	Юрійівна	063-002-2321	322
323	Петро	Пилипчук	Миколаович	050-002-2322	323
324	Валентина	Пилипчук	Павлоівна	067-002-2323	324
328	Василь	Олексієнко	Ігорович	096-002-2327	328
325	Світлана	Симоненко	Дмитроівна	095-002-2324	325
326	Тарас	Проценко	Павлоович	066-002-2325	326
329	Катерина	Олексієнко	Романівна	097-002-2328	329
327	Орися	Проценко	Євгенівна	039-002-2326	327
330	Тамара	Корсун	Павлоівна	096-002-2329	330
335	Зоряна	Шевченко	Романівна	068-002-2334	335
336	Ярослав	Ковальчук	Віталійович	066-002-2335	336
343	Арсен	Ткаченко	Геннадійович	050-002-2342	343
344	Меланія	Ткаченко	Максимівна	067-002-2343	344
345	Дарина	Козак	Віталийівна	039-002-2344	345
346	Вадим	Руденко	Максимович	066-002-2345	346
347	Поліна	Руденко	Степанівна	039-002-2346	347
348	Богдан	Федоренко	Ярославович	096-002-2347	348
349	Карина	Федоренко	Борисівна	097-002-2348	349
350	Анна	Білик	Максимівна	098-002-2349	350
351	Єгор	Сидоренко	Борисович	068-002-2350	351
353	Федір	Кравченко	Данилоович	050-002-2352	353
354	Наталія	Кравченко	Ростиславівна	067-002-2353	354
355	Марта	Петренко	Борисівна	050-002-2354	355
356	Олександр	Дмитренко	Ростиславович	066-002-2355	356
357	Олена	Дмитренко	Богданівна	039-002-2356	357
358	Володимир	Микитенко	Вадимович	096-002-2357	358
359	Тетяна	Микитенко	Костянтинівна	097-002-2358	359
361	Сергій	Савченко	Костянтинович	068-002-2360	361
360	Яна	Литвин	Ростиславівна	066-002-2359	360
363	Дмитро	Кравчук	Єгорович	050-002-2362	363
364	Оксана	Кравчук	Артемівна	067-002-2363	364
365	Ірина	Ткач	Костянтинівна	097-002-2364	365
366	Юрій	Шевчук	Артемович	066-002-2365	366
369	Світлана	Грищенко	Андрійівна	097-002-2368	369
370	Ганна	Коцюбинська	Артемівна	063-002-2369	370
368	Павло	Грищенко	Олександрович	096-002-2367	368
372	Марина	Черненко	Дмитроівна	063-002-2371	372
367	Надія	Шевчук	Володимирівна	039-002-2366	367
375	Вікторія	Бондаренко	Андрійівна	095-002-2374	375
376	Петро	Соловйова	Миколаович	066-002-2375	376
377	Валентина	Соловйова	Павлоівна	039-002-2376	377
383	Віталий	Демченко	Євгенович	050-002-2382	383
378	Віталій	Мацюк	Юрійович	096-002-2377	378
381	Василь	Левченко	Ігорович	068-002-2380	381
379	Зоряна	Мацюк	Ігорівна	097-002-2378	379
382	Катерина	Левченко	Романівна	063-002-2381	382
380	Люба	Іваненко	Миколаівна	096-002-2379	380
384	Аліна	Демченко	Олегівна	067-002-2383	384
385	Роксолана	Коваль	Ігорівна	068-002-2384	385
386	Лев	Романенко	Олегович	066-002-2385	386
387	Єва	Романенко	Віталійівна	039-002-2386	387
388	Максим	Ковальський	Петроович	096-002-2387	388
389	Дарина	Ковальський	Тарасівна	097-002-2388	389
390	Орися	Бойченко	Олегівна	067-002-2389	390
391	Степан	Павленко	Тарасович	068-002-2390	391
392	Лілія	Павленко	Віталийівна	063-002-2391	392
393	Борис	Пономаренко	Васильович	050-002-2392	393
394	Анна	Пономаренко	Геннадійівна	067-002-2393	394
395	Віра	Клименко	Тарасівна	039-002-2394	395
396	Арсен	Кириченко	Геннадійович	066-002-2395	396
397	Меланія	Кириченко	Максимівна	039-002-2396	397
398	Ростислав	Мартинюк	Левович	096-002-2397	398
399	Марта	Мартинюк	Ярославівна	097-002-2398	399
400	Софія	Зайцев	Геннадійівна	098-002-2399	400
401	Богдан	Мартиненко	Ярославович	068-002-2400	401
403	Костянтин	Остапенко	Степанович	050-002-2402	403
402	Карина	Мартиненко	Борисівна	063-002-2401	402
404	Яна	Остапенко	Данилоівна	067-002-2403	404
405	Еліна	Кузьменко	Ярославівна	050-002-2404	405
407	Наталія	Пилипчук	Ростиславівна	039-002-2406	407
408	Артем	Симоненко	Арсенович	096-002-2407	408
409	Ірина	Симоненко	Вадимівна	097-002-2408	409
410	Поліна	Проценко	Данилоівна	066-002-2409	410
411	Володимир	Олексієнко	Вадимович	068-002-2410	411
412	Тетяна	Олексієнко	Костянтинівна	063-002-2411	412
1	Олег	Шевченко	Дмитроович	068-002-2000	1
2	Роксолана	Шевченко	Юрійівна	063-002-2001	2
3	Петро	Ковальчук	Миколаович	050-002-2002	3
13	Лев	Руденко	Олегович	050-002-2012	13
4	Валентина	Ковальчук	Павлоівна	067-002-2003	4
14	Єва	Руденко	Віталійівна	067-002-2013	14
15	Зоряна	Федоренко	Романівна	097-002-2014	15
8	Василь	Мельник	Ігорович	096-002-2007	8
6	Тарас	Гончар	Павлоович	066-002-2005	6
9	Катерина	Мельник	Романівна	097-002-2008	9
10	Тамара	Ткаченко	Павлоівна	066-002-2009	10
16	Ярослав	Білик	Віталійович	066-002-2015	16
17	Софія	Білик	Васильівна	039-002-2016	17
7	Орися	Гончар	Євгенівна	039-002-2006	7
48	Павло	Левченко	Олександрович	096-002-2047	48
44	Оксана	Соловйова	Артемівна	067-002-2043	44
81	Богдан	Нечипоренко	Ярославович	068-002-2080	81
84	Яна	Мірошниченко	Данилоівна	067-002-2083	84
85	Еліна	Шевченко	Ярославівна	068-002-2084	85
86	Федір	Ковальчук	Данилоович	066-002-2085	86
87	Наталія	Ковальчук	Ростиславівна	039-002-2086	87
88	Артем	Бойко	Арсенович	096-002-2087	88
89	Ірина	Бойко	Вадимівна	097-002-2088	89
91	Володимир	Мельник	Вадимович	068-002-2090	91
90	Поліна	Гончар	Данилоівна	067-002-2089	90
92	Тетяна	Мельник	Костянтинівна	063-002-2091	92
101	Павло	Сидоренко	Олександрович	068-002-2100	101
418	Микола	Шевченко	Федірович	096-002-2417	418
419	Вікторія	Шевченко	Олександрівна	097-002-2418	419
420	Олена	Ковальчук	Єгорівна	063-002-2419	420
421	Павло	Бойко	Олександрович	068-002-2420	421
427	Тамара	Ткаченко	Миколаівна	039-002-2426	427
428	Олег	Козак	Дмитроович	096-002-2427	428
429	Роксолана	Козак	Юрійівна	097-002-2428	429
437	Аліна	Кравченко	Олегівна	039-002-2436	437
438	Геннадій	Петренко	Романович	096-002-2437	438
439	Віра	Петренко	Петроівна	097-002-2438	439
440	Валентина	Дмитренко	Євгенівна	067-002-2439	440
441	Максим	Микитенко	Петроович	068-002-2440	441
442	Дарина	Микитенко	Тарасівна	063-002-2441	442
443	Ярослав	Литвин	Віталійович	050-002-2442	443
444	Софія	Литвин	Васильівна	067-002-2443	444
445	Катерина	Савченко	Петроівна	039-002-2444	445
446	Борис	Кравчук	Васильович	066-002-2445	446
447	Анна	Кравчук	Геннадійівна	039-002-2446	447
448	Данило	Ткач	Віталийович	096-002-2447	448
449	Еліна	Ткач	Левівна	097-002-2448	449
450	Єва	Шевчук	Васильівна	098-002-2449	450
451	Ростислав	Грищенко	Левович	068-002-2450	451
452	Марта	Грищенко	Ярославівна	063-002-2451	452
453	Вадим	Коцюбинська	Максимович	050-002-2452	453
454	Поліна	Коцюбинська	Степанівна	067-002-2453	454
455	Лілія	Черненко	Левівна	050-002-2454	455
456	Костянтин	Поліщук	Степанович	066-002-2455	456
457	Яна	Поліщук	Данилоівна	039-002-2456	457
458	Єгор	Бондаренко	Борисович	096-002-2457	459
459	Марія	Бондаренко	Арсенівна	097-002-2458	458
460	Меланія	Соловйова	Степанівна	066-002-2459	460
462	Ірина	Мацюк	Вадимівна	063-002-2461	462
461	Артем	Мацюк	Арсенович	068-002-2460	461
463	Олександр	Іваненко	Ростиславович	050-002-2462	463
464	Олена	Іваненко	Богданівна	067-002-2463	464
465	Карина	Левченко	Арсенівна	097-002-2464	465
466	Андрій	Демченко	Богданович	066-002-2465	466
467	Ганна	Демченко	Єгорівна	039-002-2466	467
110	Надія	Литвин	Сергійівна	066-002-2109	110
132	Марта	Левченко	Ярославівна	063-002-2131	132
169	Катерина	Шевченко	Романівна	097-002-2168	169
192	Марія	Микитенко	Арсенівна	063-002-2191	192
251	Володимир	Шевченко	Вадимович	068-002-2250	251
339	Лілія	Бойко	Віталийівна	097-002-2338	339
435	Марина	Сидоренко	Юрійівна	068-002-2434	435
122	Дарина	Черненко	Тарасівна	063-002-2121	122
166	Тарас	Мірошниченко	Павлоович	066-002-2165	166
264	Люба	Руденко	Сергійівна	067-002-2263	264
274	Орися	Дмитренко	Євгенівна	067-002-2273	274
334	Єва	Мірошниченко	Віталійівна	067-002-2333	334
374	Тамара	Поліщук	Миколаівна	067-002-2373	374
142	Ірина	Павленко	Вадимівна	063-002-2141	142
170	Тамара	Ковальчук	Павлоівна	063-002-2169	170
181	Данило	Федоренко	Віталийович	068-002-2180	181
222	Катерина	Ковальський	Романівна	063-002-2221	222
434	Орися	Білик	Євгенівна	067-002-2433	434
152	Вікторія	Мартиненко	Олександрівна	063-002-2151	152
171	Геннадій	Бойко	Романович	068-002-2170	171
258	Микола	Мельник	Федірович	096-002-2257	258
332	Віра	Нечипоренко	Петроівна	063-002-2331	332
340	Аліна	Гончар	Віталійівна	067-002-2339	340
352	Марія	Сидоренко	Арсенівна	063-002-2351	352
425	Людмила	Мельник	Олександрівна	095-002-2424	425
433	Тарас	Білик	Павлоович	050-002-2432	433
163	Петро	Корсун	Миколаович	050-002-2162	163
173	Лев	Гончар	Олегович	050-002-2172	173
183	Арсен	Білик	Геннадійович	050-002-2182	183
203	Дмитро	Коцюбинська	Єгорович	050-002-2202	203
253	Андрій	Ковальчук	Богданович	050-002-2252	253
263	Ігор	Руденко	Володимирович	050-002-2262	263
303	Олександр	Романенко	Ростиславович	050-002-2302	303
331	Геннадій	Нечипоренко	Романович	068-002-2330	331
341	Данило	Мельник	Віталийович	068-002-2340	341
417	Оксана	Мірошниченко	Артемівна	039-002-2416	417
167	Орися	Мірошниченко	Євгенівна	039-002-2166	167
342	Еліна	Мельник	Левівна	063-002-2341	342
362	Людмила	Савченко	Федірівна	063-002-2361	362
371	Євген	Черненко	Андрійович	068-002-2370	371
168	Василь	Шевченко	Ігорович	096-002-2167	168
182	Еліна	Федоренко	Левівна	063-002-2181	182
232	Лілія	Мартинюк	Віталийівна	063-002-2231	232
250	Поліна	Мірошниченко	Данилоівна	098-002-2249	250
261	Павло	Козак	Олександрович	068-002-2260	261
333	Лев	Мірошниченко	Олегович	050-002-2332	333
373	Роман	Поліщук	Сергійович	050-002-2372	373
414	Ганна	Корсун	Єгорівна	067-002-2413	414
426	Роман	Ткаченко	Сергійович	066-002-2425	426
430	Надія	Руденко	Сергійівна	096-002-2429	430
172	Віра	Бойко	Петроівна	063-002-2171	172
242	Карина	Симоненко	Борисівна	063-002-2241	242
293	Вадим	Соловйова	Максимович	050-002-2292	293
311	Микола	Клименко	Федірович	068-002-2310	311
406	Федір	Пилипчук	Данилоович	066-002-2405	406
413	Андрій	Корсун	Богданович	050-002-2412	413
422	Світлана	Бойко	Андрійівна	063-002-2421	422
432	Зоряна	Федоренко	Ігорівна	063-002-2431	432
249	Ірина	Нечипоренко	Вадимівна	097-002-2248	249
262	Світлана	Козак	Андрійівна	063-002-2261	262
338	Степан	Бойко	Тарасович	096-002-2337	338
416	Дмитро	Мірошниченко	Єгорович	066-002-2415	416
423	Ігор	Гончар	Володимирович	050-002-2422	423
431	Віталій	Федоренко	Юрійович	068-002-2430	431
252	Тетяна	Шевченко	Костянтинівна	063-002-2251	252
337	Софія	Ковальчук	Васильівна	039-002-2336	337
415	Марія	Нечипоренко	Вадимівна	097-002-2414	415
424	Люба	Гончар	Сергійівна	067-002-2423	424
436	Віталий	Кравченко	Євгенович	066-002-2435	436
468	Іван	Петренко	Олександрович	067-123-4567	823
469	ТЕСТ21	ТЕСТ2	ТЕСТ2	098-098-0987	835
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (role_id, role_name, role_desc) FROM stdin;
1	SAdmin	Super administrator manages all layers of the application and database contents.
2	Admin	Administrator manages the roles, and basic functions of the database.
4	Student	Students are studying in the school, their prime responsibilities are to keep up with homework.
6	Parent	Mother/Father/Grandmother/Grandfather or step-parent of a student.
7	Teacher	Self explanatory
8	guest	\N
\.


--
-- Data for Name: studentdata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.studentdata (data_id, journal_id, student_id, lesson, mark, status, note, created_at) FROM stdin;
2	1	2	1	5	Присутній	\N	2025-12-14 22:17:43.36063
3	1	3	1	\N	Н	\N	2025-12-14 22:17:43.36063
4	1	4	1	2	Присутній	\N	2025-12-14 22:17:43.36063
5	1	5	1	\N	Присутній	\N	2025-12-14 22:17:43.36063
6	1	6	1	\N	Присутній	\N	2025-12-14 22:17:43.36063
7	1	7	1	7	Присутній	\N	2025-12-14 22:17:43.36063
8	1	8	1	2	Присутній	\N	2025-12-14 22:17:43.36063
9	1	9	1	\N	Н	\N	2025-12-14 22:17:43.36063
10	1	10	1	\N	Присутній	\N	2025-12-14 22:17:43.36063
11	1	1	2	4	Присутній	\N	2025-12-14 22:17:43.36063
12	1	2	2	\N	Присутній	\N	2025-12-14 22:17:43.36063
13	1	3	2	\N	Присутній	\N	2025-12-14 22:17:43.36063
14	1	4	2	\N	Н	\N	2025-12-14 22:17:43.36063
15	1	5	2	\N	Н	\N	2025-12-14 22:17:43.36063
16	1	6	2	\N	Н	\N	2025-12-14 22:17:43.36063
17	1	7	2	\N	Присутній	\N	2025-12-14 22:17:43.36063
18	1	8	2	\N	Присутній	\N	2025-12-14 22:17:43.36063
19	1	9	2	7	Присутній	\N	2025-12-14 22:17:43.36063
20	1	10	2	\N	Н	\N	2025-12-14 22:17:43.36063
21	1	1	3	6	Присутній	\N	2025-12-14 22:17:43.36063
22	1	2	3	7	Присутній	\N	2025-12-14 22:17:43.36063
23	1	3	3	6	Присутній	\N	2025-12-14 22:17:43.36063
24	1	4	3	\N	Присутній	\N	2025-12-14 22:17:43.36063
25	1	5	3	\N	Присутній	\N	2025-12-14 22:17:43.36063
26	1	6	3	\N	Присутній	\N	2025-12-14 22:17:43.36063
27	1	7	3	\N	Присутній	\N	2025-12-14 22:17:43.36063
28	1	8	3	\N	Присутній	\N	2025-12-14 22:17:43.36063
29	1	9	3	\N	Н	\N	2025-12-14 22:17:43.36063
30	1	10	3	\N	Присутній	\N	2025-12-14 22:17:43.36063
31	1	1	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
32	1	2	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
33	1	3	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
34	1	4	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
35	1	5	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
36	1	6	4	4	Присутній	\N	2025-12-14 22:17:43.36063
37	1	7	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
38	1	8	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
39	1	9	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
40	1	10	4	\N	Присутній	\N	2025-12-14 22:17:43.36063
41	1	1	5	\N	Н	\N	2025-12-14 22:17:43.36063
42	1	2	5	\N	Присутній	\N	2025-12-14 22:17:43.36063
43	1	3	5	\N	Присутній	\N	2025-12-14 22:17:43.36063
44	1	4	5	6	Присутній	\N	2025-12-14 22:17:43.36063
45	1	5	5	\N	Н	\N	2025-12-14 22:17:43.36063
46	1	6	5	\N	Н	\N	2025-12-14 22:17:43.36063
47	1	7	5	\N	Присутній	\N	2025-12-14 22:17:43.36063
48	1	8	5	\N	Присутній	\N	2025-12-14 22:17:43.36063
49	1	9	5	\N	Присутній	\N	2025-12-14 22:17:43.36063
50	1	10	5	12	Присутній	\N	2025-12-14 22:17:43.36063
51	2	11	6	\N	Н	\N	2025-12-14 22:17:43.36063
52	2	12	6	\N	Присутній	\N	2025-12-14 22:17:43.36063
53	2	13	6	\N	Н	\N	2025-12-14 22:17:43.36063
54	2	14	6	\N	Присутній	\N	2025-12-14 22:17:43.36063
55	2	15	6	\N	Присутній	\N	2025-12-14 22:17:43.36063
56	2	16	6	\N	Н	\N	2025-12-14 22:17:43.36063
57	2	17	6	\N	Н	\N	2025-12-14 22:17:43.36063
58	2	18	6	\N	Присутній	\N	2025-12-14 22:17:43.36063
59	2	19	6	1	Присутній	\N	2025-12-14 22:17:43.36063
60	2	20	6	\N	Присутній	\N	2025-12-14 22:17:43.36063
61	2	11	7	\N	Н	\N	2025-12-14 22:17:43.36063
62	2	12	7	10	Присутній	\N	2025-12-14 22:17:43.36063
63	2	13	7	\N	Присутній	\N	2025-12-14 22:17:43.36063
64	2	14	7	\N	Н	\N	2025-12-14 22:17:43.36063
65	2	15	7	\N	Присутній	\N	2025-12-14 22:17:43.36063
66	2	16	7	\N	Н	\N	2025-12-14 22:17:43.36063
67	2	17	7	\N	Присутній	\N	2025-12-14 22:17:43.36063
68	2	18	7	\N	Присутній	\N	2025-12-14 22:17:43.36063
69	2	19	7	\N	Н	\N	2025-12-14 22:17:43.36063
70	2	20	7	\N	Н	\N	2025-12-14 22:17:43.36063
71	2	11	8	\N	Присутній	\N	2025-12-14 22:17:43.36063
72	2	12	8	\N	Н	\N	2025-12-14 22:17:43.36063
73	2	13	8	\N	Присутній	\N	2025-12-14 22:17:43.36063
74	2	14	8	\N	Присутній	\N	2025-12-14 22:17:43.36063
75	2	15	8	\N	Н	\N	2025-12-14 22:17:43.36063
76	2	16	8	\N	Н	\N	2025-12-14 22:17:43.36063
77	2	17	8	\N	Присутній	\N	2025-12-14 22:17:43.36063
78	2	18	8	\N	Присутній	\N	2025-12-14 22:17:43.36063
79	2	19	8	1	Присутній	\N	2025-12-14 22:17:43.36063
80	2	20	8	\N	Присутній	\N	2025-12-14 22:17:43.36063
81	2	11	9	3	Присутній	\N	2025-12-14 22:17:43.36063
82	2	12	9	\N	Присутній	\N	2025-12-14 22:17:43.36063
83	2	13	9	\N	Н	\N	2025-12-14 22:17:43.36063
84	2	14	9	7	Присутній	\N	2025-12-14 22:17:43.36063
85	2	15	9	\N	Присутній	\N	2025-12-14 22:17:43.36063
86	2	16	9	\N	Присутній	\N	2025-12-14 22:17:43.36063
87	2	17	9	\N	Н	\N	2025-12-14 22:17:43.36063
88	2	18	9	\N	Присутній	\N	2025-12-14 22:17:43.36063
89	2	19	9	\N	Присутній	\N	2025-12-14 22:17:43.36063
90	2	20	9	\N	Присутній	\N	2025-12-14 22:17:43.36063
91	2	11	10	9	Присутній	\N	2025-12-14 22:17:43.36063
92	2	12	10	\N	Присутній	\N	2025-12-14 22:17:43.36063
93	2	13	10	\N	Присутній	\N	2025-12-14 22:17:43.36063
94	2	14	10	\N	Н	\N	2025-12-14 22:17:43.36063
95	2	15	10	\N	Н	\N	2025-12-14 22:17:43.36063
96	2	16	10	1	Присутній	\N	2025-12-14 22:17:43.36063
97	2	17	10	\N	Присутній	\N	2025-12-14 22:17:43.36063
98	2	18	10	\N	Присутній	\N	2025-12-14 22:17:43.36063
99	2	19	10	\N	Н	\N	2025-12-14 22:17:43.36063
100	2	20	10	\N	Присутній	\N	2025-12-14 22:17:43.36063
101	3	21	11	2	Присутній	\N	2025-12-14 22:17:43.36063
102	3	22	11	\N	Присутній	\N	2025-12-14 22:17:43.36063
103	3	23	11	\N	Н	\N	2025-12-14 22:17:43.36063
104	3	24	11	\N	Присутній	\N	2025-12-14 22:17:43.36063
105	3	25	11	\N	Присутній	\N	2025-12-14 22:17:43.36063
106	3	26	11	3	Присутній	\N	2025-12-14 22:17:43.36063
107	3	27	11	\N	Присутній	\N	2025-12-14 22:17:43.36063
108	3	28	11	\N	Присутній	\N	2025-12-14 22:17:43.36063
109	3	29	11	\N	Присутній	\N	2025-12-14 22:17:43.36063
110	3	30	11	6	Присутній	\N	2025-12-14 22:17:43.36063
111	3	21	12	\N	Присутній	\N	2025-12-14 22:17:43.36063
112	3	22	12	6	Присутній	\N	2025-12-14 22:17:43.36063
113	3	23	12	\N	Присутній	\N	2025-12-14 22:17:43.36063
114	3	24	12	\N	Присутній	\N	2025-12-14 22:17:43.36063
115	3	25	12	\N	Н	\N	2025-12-14 22:17:43.36063
116	3	26	12	10	Присутній	\N	2025-12-14 22:17:43.36063
117	3	27	12	\N	Присутній	\N	2025-12-14 22:17:43.36063
118	3	28	12	8	Присутній	\N	2025-12-14 22:17:43.36063
119	3	29	12	\N	Присутній	\N	2025-12-14 22:17:43.36063
120	3	30	12	\N	Присутній	\N	2025-12-14 22:17:43.36063
121	3	21	13	\N	Присутній	\N	2025-12-14 22:17:43.36063
122	3	22	13	11	Присутній	\N	2025-12-14 22:17:43.36063
123	3	23	13	\N	Присутній	\N	2025-12-14 22:17:43.36063
124	3	24	13	\N	Присутній	\N	2025-12-14 22:17:43.36063
125	3	25	13	\N	Н	\N	2025-12-14 22:17:43.36063
126	3	26	13	\N	Присутній	\N	2025-12-14 22:17:43.36063
127	3	27	13	\N	Н	\N	2025-12-14 22:17:43.36063
128	3	28	13	\N	Н	\N	2025-12-14 22:17:43.36063
129	3	29	13	\N	Присутній	\N	2025-12-14 22:17:43.36063
130	3	30	13	\N	Присутній	\N	2025-12-14 22:17:43.36063
131	3	21	14	\N	Н	\N	2025-12-14 22:17:43.36063
132	3	22	14	\N	Н	\N	2025-12-14 22:17:43.36063
133	3	23	14	\N	Присутній	\N	2025-12-14 22:17:43.36063
134	3	24	14	\N	Присутній	\N	2025-12-14 22:17:43.36063
135	3	25	14	\N	Н	\N	2025-12-14 22:17:43.36063
136	3	26	14	\N	Присутній	\N	2025-12-14 22:17:43.36063
137	3	27	14	4	Присутній	\N	2025-12-14 22:17:43.36063
138	3	28	14	1	Присутній	\N	2025-12-14 22:17:43.36063
139	3	29	14	\N	Присутній	\N	2025-12-14 22:17:43.36063
140	3	30	14	\N	Н	\N	2025-12-14 22:17:43.36063
141	3	21	15	\N	Н	\N	2025-12-14 22:17:43.36063
142	3	22	15	11	Присутній	\N	2025-12-14 22:17:43.36063
143	3	23	15	2	Присутній	\N	2025-12-14 22:17:43.36063
144	3	24	15	\N	Присутній	\N	2025-12-14 22:17:43.36063
145	3	25	15	\N	Присутній	\N	2025-12-14 22:17:43.36063
146	3	26	15	4	Присутній	\N	2025-12-14 22:17:43.36063
147	3	27	15	\N	Н	\N	2025-12-14 22:17:43.36063
148	3	28	15	\N	Присутній	\N	2025-12-14 22:17:43.36063
149	3	29	15	\N	Присутній	\N	2025-12-14 22:17:43.36063
150	3	30	15	\N	Присутній	\N	2025-12-14 22:17:43.36063
151	4	31	16	\N	Присутній	\N	2025-12-14 22:17:43.36063
152	4	32	16	\N	Присутній	\N	2025-12-14 22:17:43.36063
153	4	33	16	\N	Н	\N	2025-12-14 22:17:43.36063
154	4	34	16	\N	Присутній	\N	2025-12-14 22:17:43.36063
155	4	35	16	\N	Н	\N	2025-12-14 22:17:43.36063
156	4	36	16	11	Присутній	\N	2025-12-14 22:17:43.36063
157	4	37	16	\N	Н	\N	2025-12-14 22:17:43.36063
158	4	38	16	\N	Н	\N	2025-12-14 22:17:43.36063
159	4	39	16	\N	Присутній	\N	2025-12-14 22:17:43.36063
160	4	40	16	\N	Присутній	\N	2025-12-14 22:17:43.36063
161	4	31	17	\N	Присутній	\N	2025-12-14 22:17:43.36063
162	4	32	17	\N	Присутній	\N	2025-12-14 22:17:43.36063
163	4	33	17	7	Присутній	\N	2025-12-14 22:17:43.36063
164	4	34	17	\N	Присутній	\N	2025-12-14 22:17:43.36063
165	4	35	17	\N	Присутній	\N	2025-12-14 22:17:43.36063
166	4	36	17	4	Присутній	\N	2025-12-14 22:17:43.36063
167	4	37	17	8	Присутній	\N	2025-12-14 22:17:43.36063
168	4	38	17	3	Присутній	\N	2025-12-14 22:17:43.36063
169	4	39	17	\N	Н	\N	2025-12-14 22:17:43.36063
170	4	40	17	\N	Н	\N	2025-12-14 22:17:43.36063
171	4	31	18	\N	Присутній	\N	2025-12-14 22:17:43.36063
172	4	32	18	\N	Н	\N	2025-12-14 22:17:43.36063
173	4	33	18	\N	Присутній	\N	2025-12-14 22:17:43.36063
174	4	34	18	\N	Присутній	\N	2025-12-14 22:17:43.36063
175	4	35	18	9	Присутній	\N	2025-12-14 22:17:43.36063
176	4	36	18	\N	Присутній	\N	2025-12-14 22:17:43.36063
177	4	37	18	\N	Присутній	\N	2025-12-14 22:17:43.36063
178	4	38	18	\N	Присутній	\N	2025-12-14 22:17:43.36063
179	4	39	18	\N	Присутній	\N	2025-12-14 22:17:43.36063
180	4	40	18	8	Присутній	\N	2025-12-14 22:17:43.36063
181	4	31	19	\N	Присутній	\N	2025-12-14 22:17:43.36063
182	4	32	19	\N	Присутній	\N	2025-12-14 22:17:43.36063
183	4	33	19	\N	Присутній	\N	2025-12-14 22:17:43.36063
184	4	34	19	1	Присутній	\N	2025-12-14 22:17:43.36063
185	4	35	19	\N	Присутній	\N	2025-12-14 22:17:43.36063
186	4	36	19	\N	Н	\N	2025-12-14 22:17:43.36063
187	4	37	19	\N	Присутній	\N	2025-12-14 22:17:43.36063
188	4	38	19	\N	Присутній	\N	2025-12-14 22:17:43.36063
189	4	39	19	\N	Н	\N	2025-12-14 22:17:43.36063
190	4	40	19	\N	Присутній	\N	2025-12-14 22:17:43.36063
191	4	31	20	\N	Присутній	\N	2025-12-14 22:17:43.36063
192	4	32	20	\N	Присутній	\N	2025-12-14 22:17:43.36063
193	4	33	20	\N	Присутній	\N	2025-12-14 22:17:43.36063
194	4	34	20	5	Присутній	\N	2025-12-14 22:17:43.36063
195	4	35	20	\N	Н	\N	2025-12-14 22:17:43.36063
196	4	36	20	12	Присутній	\N	2025-12-14 22:17:43.36063
197	4	37	20	\N	Присутній	\N	2025-12-14 22:17:43.36063
198	4	38	20	\N	Присутній	\N	2025-12-14 22:17:43.36063
199	4	39	20	10	Присутній	\N	2025-12-14 22:17:43.36063
200	4	40	20	\N	Присутній	\N	2025-12-14 22:17:43.36063
201	5	41	21	\N	Присутній	\N	2025-12-14 22:17:43.36063
202	5	42	21	\N	Присутній	\N	2025-12-14 22:17:43.36063
203	5	43	21	9	Присутній	\N	2025-12-14 22:17:43.36063
204	5	44	21	3	Присутній	\N	2025-12-14 22:17:43.36063
205	5	45	21	2	Присутній	\N	2025-12-14 22:17:43.36063
206	5	46	21	\N	Присутній	\N	2025-12-14 22:17:43.36063
207	5	47	21	\N	Н	\N	2025-12-14 22:17:43.36063
208	5	48	21	10	Присутній	\N	2025-12-14 22:17:43.36063
209	5	49	21	\N	Н	\N	2025-12-14 22:17:43.36063
210	5	50	21	\N	Присутній	\N	2025-12-14 22:17:43.36063
211	5	41	22	\N	Присутній	\N	2025-12-14 22:17:43.36063
212	5	42	22	\N	Н	\N	2025-12-14 22:17:43.36063
213	5	43	22	\N	Присутній	\N	2025-12-14 22:17:43.36063
214	5	44	22	\N	Присутній	\N	2025-12-14 22:17:43.36063
215	5	45	22	\N	Присутній	\N	2025-12-14 22:17:43.36063
216	5	46	22	\N	Н	\N	2025-12-14 22:17:43.36063
217	5	47	22	\N	Присутній	\N	2025-12-14 22:17:43.36063
218	5	48	22	\N	Н	\N	2025-12-14 22:17:43.36063
219	5	49	22	\N	Н	\N	2025-12-14 22:17:43.36063
220	5	50	22	\N	Присутній	\N	2025-12-14 22:17:43.36063
221	5	41	23	\N	Н	\N	2025-12-14 22:17:43.36063
222	5	42	23	\N	Н	\N	2025-12-14 22:17:43.36063
223	5	43	23	\N	Присутній	\N	2025-12-14 22:17:43.36063
224	5	44	23	8	Присутній	\N	2025-12-14 22:17:43.36063
225	5	45	23	\N	Присутній	\N	2025-12-14 22:17:43.36063
226	5	46	23	\N	Присутній	\N	2025-12-14 22:17:43.36063
227	5	47	23	9	Присутній	\N	2025-12-14 22:17:43.36063
228	5	48	23	\N	Н	\N	2025-12-14 22:17:43.36063
229	5	49	23	\N	Н	\N	2025-12-14 22:17:43.36063
230	5	50	23	\N	Присутній	\N	2025-12-14 22:17:43.36063
231	5	41	24	\N	Присутній	\N	2025-12-14 22:17:43.36063
232	5	42	24	\N	Присутній	\N	2025-12-14 22:17:43.36063
233	5	43	24	\N	Н	\N	2025-12-14 22:17:43.36063
234	5	44	24	9	Присутній	\N	2025-12-14 22:17:43.36063
235	5	45	24	\N	Присутній	\N	2025-12-14 22:17:43.36063
236	5	46	24	\N	Присутній	\N	2025-12-14 22:17:43.36063
237	5	47	24	\N	Присутній	\N	2025-12-14 22:17:43.36063
238	5	48	24	\N	Присутній	\N	2025-12-14 22:17:43.36063
239	5	49	24	9	Присутній	\N	2025-12-14 22:17:43.36063
240	5	50	24	\N	Н	\N	2025-12-14 22:17:43.36063
241	5	41	25	\N	Присутній	\N	2025-12-14 22:17:43.36063
242	5	42	25	\N	Присутній	\N	2025-12-14 22:17:43.36063
243	5	43	25	2	Присутній	\N	2025-12-14 22:17:43.36063
244	5	44	25	\N	Присутній	\N	2025-12-14 22:17:43.36063
245	5	45	25	\N	Присутній	\N	2025-12-14 22:17:43.36063
246	5	46	25	5	Присутній	\N	2025-12-14 22:17:43.36063
247	5	47	25	\N	Присутній	\N	2025-12-14 22:17:43.36063
248	5	48	25	\N	Присутній	\N	2025-12-14 22:17:43.36063
249	5	49	25	\N	Н	\N	2025-12-14 22:17:43.36063
250	5	50	25	\N	Присутній	\N	2025-12-14 22:17:43.36063
251	6	51	26	\N	Н	\N	2025-12-14 22:17:43.36063
252	6	52	26	\N	Присутній	\N	2025-12-14 22:17:43.36063
253	6	53	26	\N	Присутній	\N	2025-12-14 22:17:43.36063
254	6	54	26	\N	Присутній	\N	2025-12-14 22:17:43.36063
255	6	55	26	7	Присутній	\N	2025-12-14 22:17:43.36063
256	6	56	26	\N	Присутній	\N	2025-12-14 22:17:43.36063
257	6	57	26	6	Присутній	\N	2025-12-14 22:17:43.36063
258	6	58	26	\N	Присутній	\N	2025-12-14 22:17:43.36063
259	6	59	26	\N	Присутній	\N	2025-12-14 22:17:43.36063
260	6	60	26	\N	Н	\N	2025-12-14 22:17:43.36063
261	6	51	27	\N	Присутній	\N	2025-12-14 22:17:43.36063
262	6	52	27	\N	Присутній	\N	2025-12-14 22:17:43.36063
263	6	53	27	\N	Н	\N	2025-12-14 22:17:43.36063
264	6	54	27	2	Присутній	\N	2025-12-14 22:17:43.36063
265	6	55	27	\N	Присутній	\N	2025-12-14 22:17:43.36063
266	6	56	27	\N	Присутній	\N	2025-12-14 22:17:43.36063
267	6	57	27	1	Присутній	\N	2025-12-14 22:17:43.36063
268	6	58	27	\N	Присутній	\N	2025-12-14 22:17:43.36063
269	6	59	27	\N	Присутній	\N	2025-12-14 22:17:43.36063
270	6	60	27	3	Присутній	\N	2025-12-14 22:17:43.36063
271	6	51	28	6	Присутній	\N	2025-12-14 22:17:43.36063
272	6	52	28	\N	Присутній	\N	2025-12-14 22:17:43.36063
273	6	53	28	\N	Присутній	\N	2025-12-14 22:17:43.36063
274	6	54	28	\N	Присутній	\N	2025-12-14 22:17:43.36063
275	6	55	28	\N	Присутній	\N	2025-12-14 22:17:43.36063
276	6	56	28	\N	Н	\N	2025-12-14 22:17:43.36063
277	6	57	28	\N	Н	\N	2025-12-14 22:17:43.36063
278	6	58	28	9	Присутній	\N	2025-12-14 22:17:43.36063
279	6	59	28	\N	Присутній	\N	2025-12-14 22:17:43.36063
280	6	60	28	\N	Н	\N	2025-12-14 22:17:43.36063
281	6	51	29	\N	Присутній	\N	2025-12-14 22:17:43.36063
282	6	52	29	4	Присутній	\N	2025-12-14 22:17:43.36063
283	6	53	29	\N	Присутній	\N	2025-12-14 22:17:43.36063
284	6	54	29	\N	Присутній	\N	2025-12-14 22:17:43.36063
285	6	55	29	\N	Присутній	\N	2025-12-14 22:17:43.36063
286	6	56	29	\N	Присутній	\N	2025-12-14 22:17:43.36063
287	6	57	29	12	Присутній	\N	2025-12-14 22:17:43.36063
288	6	58	29	\N	Присутній	\N	2025-12-14 22:17:43.36063
289	6	59	29	\N	Присутній	\N	2025-12-14 22:17:43.36063
290	6	60	29	\N	Н	\N	2025-12-14 22:17:43.36063
291	6	51	30	\N	Присутній	\N	2025-12-14 22:17:43.36063
292	6	52	30	\N	Присутній	\N	2025-12-14 22:17:43.36063
293	6	53	30	\N	Н	\N	2025-12-14 22:17:43.36063
294	6	54	30	12	Присутній	\N	2025-12-14 22:17:43.36063
295	6	55	30	1	Присутній	\N	2025-12-14 22:17:43.36063
296	6	56	30	\N	Присутній	\N	2025-12-14 22:17:43.36063
297	6	57	30	\N	Н	\N	2025-12-14 22:17:43.36063
298	6	58	30	\N	Присутній	\N	2025-12-14 22:17:43.36063
299	6	59	30	\N	Присутній	\N	2025-12-14 22:17:43.36063
300	6	60	30	\N	Н	\N	2025-12-14 22:17:43.36063
301	7	61	31	\N	Присутній	\N	2025-12-14 22:17:43.36063
302	7	62	31	\N	Н	\N	2025-12-14 22:17:43.36063
303	7	63	31	4	Присутній	\N	2025-12-14 22:17:43.36063
304	7	64	31	\N	Н	\N	2025-12-14 22:17:43.36063
305	7	65	31	\N	Н	\N	2025-12-14 22:17:43.36063
306	7	66	31	5	Присутній	\N	2025-12-14 22:17:43.36063
307	7	67	31	\N	Н	\N	2025-12-14 22:17:43.36063
308	7	68	31	\N	Присутній	\N	2025-12-14 22:17:43.36063
309	7	69	31	\N	Присутній	\N	2025-12-14 22:17:43.36063
310	7	70	31	\N	Присутній	\N	2025-12-14 22:17:43.36063
311	7	61	32	\N	Н	\N	2025-12-14 22:17:43.36063
312	7	62	32	5	Присутній	\N	2025-12-14 22:17:43.36063
313	7	63	32	5	Присутній	\N	2025-12-14 22:17:43.36063
314	7	64	32	10	Присутній	\N	2025-12-14 22:17:43.36063
315	7	65	32	\N	Н	\N	2025-12-14 22:17:43.36063
316	7	66	32	\N	Присутній	\N	2025-12-14 22:17:43.36063
317	7	67	32	\N	Н	\N	2025-12-14 22:17:43.36063
318	7	68	32	\N	Присутній	\N	2025-12-14 22:17:43.36063
319	7	69	32	\N	Присутній	\N	2025-12-14 22:17:43.36063
320	7	70	32	\N	Н	\N	2025-12-14 22:17:43.36063
321	7	61	33	\N	Присутній	\N	2025-12-14 22:17:43.36063
322	7	62	33	\N	Н	\N	2025-12-14 22:17:43.36063
323	7	63	33	\N	Присутній	\N	2025-12-14 22:17:43.36063
324	7	64	33	9	Присутній	\N	2025-12-14 22:17:43.36063
325	7	65	33	\N	Присутній	\N	2025-12-14 22:17:43.36063
326	7	66	33	\N	Присутній	\N	2025-12-14 22:17:43.36063
327	7	67	33	\N	Присутній	\N	2025-12-14 22:17:43.36063
328	7	68	33	7	Присутній	\N	2025-12-14 22:17:43.36063
329	7	69	33	11	Присутній	\N	2025-12-14 22:17:43.36063
330	7	70	33	\N	Присутній	\N	2025-12-14 22:17:43.36063
331	7	61	34	\N	Присутній	\N	2025-12-14 22:17:43.36063
332	7	62	34	\N	Присутній	\N	2025-12-14 22:17:43.36063
333	7	63	34	5	Присутній	\N	2025-12-14 22:17:43.36063
334	7	64	34	\N	Присутній	\N	2025-12-14 22:17:43.36063
335	7	65	34	\N	Присутній	\N	2025-12-14 22:17:43.36063
336	7	66	34	\N	Н	\N	2025-12-14 22:17:43.36063
337	7	67	34	\N	Присутній	\N	2025-12-14 22:17:43.36063
338	7	68	34	\N	Присутній	\N	2025-12-14 22:17:43.36063
339	7	69	34	11	Присутній	\N	2025-12-14 22:17:43.36063
340	7	70	34	\N	Присутній	\N	2025-12-14 22:17:43.36063
341	7	61	35	\N	Присутній	\N	2025-12-14 22:17:43.36063
342	7	62	35	\N	Присутній	\N	2025-12-14 22:17:43.36063
343	7	63	35	\N	Присутній	\N	2025-12-14 22:17:43.36063
344	7	64	35	\N	Н	\N	2025-12-14 22:17:43.36063
345	7	65	35	\N	Присутній	\N	2025-12-14 22:17:43.36063
346	7	66	35	5	Присутній	\N	2025-12-14 22:17:43.36063
347	7	67	35	\N	Н	\N	2025-12-14 22:17:43.36063
348	7	68	35	\N	Присутній	\N	2025-12-14 22:17:43.36063
349	7	69	35	\N	Присутній	\N	2025-12-14 22:17:43.36063
350	7	70	35	\N	Н	\N	2025-12-14 22:17:43.36063
351	8	71	36	\N	Н	\N	2025-12-14 22:17:43.36063
352	8	72	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
353	8	73	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
354	8	74	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
355	8	75	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
356	8	76	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
357	8	77	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
358	8	78	36	\N	Н	\N	2025-12-14 22:17:43.36063
359	8	79	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
360	8	80	36	\N	Присутній	\N	2025-12-14 22:17:43.36063
361	8	71	37	4	Присутній	\N	2025-12-14 22:17:43.36063
362	8	72	37	\N	Присутній	\N	2025-12-14 22:17:43.36063
363	8	73	37	\N	Н	\N	2025-12-14 22:17:43.36063
364	8	74	37	1	Присутній	\N	2025-12-14 22:17:43.36063
365	8	75	37	8	Присутній	\N	2025-12-14 22:17:43.36063
366	8	76	37	\N	Присутній	\N	2025-12-14 22:17:43.36063
367	8	77	37	\N	Присутній	\N	2025-12-14 22:17:43.36063
368	8	78	37	\N	Присутній	\N	2025-12-14 22:17:43.36063
369	8	79	37	\N	Присутній	\N	2025-12-14 22:17:43.36063
370	8	80	37	\N	Присутній	\N	2025-12-14 22:17:43.36063
371	8	71	38	\N	Присутній	\N	2025-12-14 22:17:43.36063
372	8	72	38	\N	Н	\N	2025-12-14 22:17:43.36063
373	8	73	38	\N	Н	\N	2025-12-14 22:17:43.36063
374	8	74	38	12	Присутній	\N	2025-12-14 22:17:43.36063
375	8	75	38	2	Присутній	\N	2025-12-14 22:17:43.36063
376	8	76	38	\N	Присутній	\N	2025-12-14 22:17:43.36063
377	8	77	38	\N	Н	\N	2025-12-14 22:17:43.36063
378	8	78	38	\N	Присутній	\N	2025-12-14 22:17:43.36063
379	8	79	38	\N	Присутній	\N	2025-12-14 22:17:43.36063
380	8	80	38	\N	Присутній	\N	2025-12-14 22:17:43.36063
381	8	71	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
382	8	72	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
383	8	73	39	3	Присутній	\N	2025-12-14 22:17:43.36063
384	8	74	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
385	8	75	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
386	8	76	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
387	8	77	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
388	8	78	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
389	8	79	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
390	8	80	39	\N	Присутній	\N	2025-12-14 22:17:43.36063
391	8	71	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
392	8	72	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
393	8	73	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
394	8	74	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
395	8	75	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
396	8	76	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
397	8	77	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
398	8	78	40	\N	Н	\N	2025-12-14 22:17:43.36063
399	8	79	40	\N	Н	\N	2025-12-14 22:17:43.36063
400	8	80	40	\N	Присутній	\N	2025-12-14 22:17:43.36063
401	9	81	41	\N	Присутній	\N	2025-12-14 22:17:43.36063
402	9	82	41	\N	Присутній	\N	2025-12-14 22:17:43.36063
403	9	83	41	\N	Присутній	\N	2025-12-14 22:17:43.36063
404	9	84	41	\N	Н	\N	2025-12-14 22:17:43.36063
405	9	85	41	5	Присутній	\N	2025-12-14 22:17:43.36063
406	9	86	41	\N	Н	\N	2025-12-14 22:17:43.36063
407	9	87	41	\N	Н	\N	2025-12-14 22:17:43.36063
408	9	88	41	\N	Присутній	\N	2025-12-14 22:17:43.36063
409	9	89	41	3	Присутній	\N	2025-12-14 22:17:43.36063
410	9	90	41	\N	Н	\N	2025-12-14 22:17:43.36063
411	9	81	42	\N	Присутній	\N	2025-12-14 22:17:43.36063
412	9	82	42	\N	Присутній	\N	2025-12-14 22:17:43.36063
413	9	83	42	7	Присутній	\N	2025-12-14 22:17:43.36063
414	9	84	42	\N	Н	\N	2025-12-14 22:17:43.36063
415	9	85	42	\N	Присутній	\N	2025-12-14 22:17:43.36063
416	9	86	42	7	Присутній	\N	2025-12-14 22:17:43.36063
417	9	87	42	\N	Н	\N	2025-12-14 22:17:43.36063
418	9	88	42	\N	Присутній	\N	2025-12-14 22:17:43.36063
419	9	89	42	\N	Присутній	\N	2025-12-14 22:17:43.36063
420	9	90	42	10	Присутній	\N	2025-12-14 22:17:43.36063
421	9	81	43	\N	Н	\N	2025-12-14 22:17:43.36063
422	9	82	43	6	Присутній	\N	2025-12-14 22:17:43.36063
423	9	83	43	\N	Н	\N	2025-12-14 22:17:43.36063
424	9	84	43	\N	Н	\N	2025-12-14 22:17:43.36063
425	9	85	43	\N	Присутній	\N	2025-12-14 22:17:43.36063
426	9	86	43	\N	Присутній	\N	2025-12-14 22:17:43.36063
427	9	87	43	\N	Присутній	\N	2025-12-14 22:17:43.36063
428	9	88	43	\N	Присутній	\N	2025-12-14 22:17:43.36063
429	9	89	43	\N	Присутній	\N	2025-12-14 22:17:43.36063
430	9	90	43	\N	Присутній	\N	2025-12-14 22:17:43.36063
431	9	81	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
432	9	82	44	\N	Н	\N	2025-12-14 22:17:43.36063
433	9	83	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
434	9	84	44	\N	Н	\N	2025-12-14 22:17:43.36063
435	9	85	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
436	9	86	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
437	9	87	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
438	9	88	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
439	9	89	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
440	9	90	44	\N	Присутній	\N	2025-12-14 22:17:43.36063
441	9	81	45	\N	Присутній	\N	2025-12-14 22:17:43.36063
442	9	82	45	\N	Присутній	\N	2025-12-14 22:17:43.36063
443	9	83	45	\N	Присутній	\N	2025-12-14 22:17:43.36063
444	9	84	45	\N	Присутній	\N	2025-12-14 22:17:43.36063
445	9	85	45	7	Присутній	\N	2025-12-14 22:17:43.36063
446	9	86	45	8	Присутній	\N	2025-12-14 22:17:43.36063
447	9	87	45	5	Присутній	\N	2025-12-14 22:17:43.36063
448	9	88	45	\N	Н	\N	2025-12-14 22:17:43.36063
449	9	89	45	\N	Н	\N	2025-12-14 22:17:43.36063
450	9	90	45	\N	Н	\N	2025-12-14 22:17:43.36063
451	10	91	46	\N	Присутній	\N	2025-12-14 22:17:43.36063
452	10	92	46	\N	Н	\N	2025-12-14 22:17:43.36063
453	10	93	46	\N	Присутній	\N	2025-12-14 22:17:43.36063
454	10	94	46	\N	Присутній	\N	2025-12-14 22:17:43.36063
455	10	95	46	\N	Н	\N	2025-12-14 22:17:43.36063
456	10	96	46	1	Присутній	\N	2025-12-14 22:17:43.36063
457	10	97	46	\N	Присутній	\N	2025-12-14 22:17:43.36063
458	10	98	46	6	Присутній	\N	2025-12-14 22:17:43.36063
459	10	99	46	\N	Н	\N	2025-12-14 22:17:43.36063
460	10	100	46	11	Присутній	\N	2025-12-14 22:17:43.36063
461	10	91	47	1	Присутній	\N	2025-12-14 22:17:43.36063
462	10	92	47	\N	Присутній	\N	2025-12-14 22:17:43.36063
463	10	93	47	1	Присутній	\N	2025-12-14 22:17:43.36063
464	10	94	47	\N	Присутній	\N	2025-12-14 22:17:43.36063
465	10	95	47	\N	Н	\N	2025-12-14 22:17:43.36063
466	10	96	47	\N	Присутній	\N	2025-12-14 22:17:43.36063
467	10	97	47	4	Присутній	\N	2025-12-14 22:17:43.36063
468	10	98	47	\N	Присутній	\N	2025-12-14 22:17:43.36063
469	10	99	47	\N	Н	\N	2025-12-14 22:17:43.36063
470	10	100	47	\N	Н	\N	2025-12-14 22:17:43.36063
471	10	91	48	\N	Присутній	\N	2025-12-14 22:17:43.36063
472	10	92	48	\N	Присутній	\N	2025-12-14 22:17:43.36063
473	10	93	48	\N	Присутній	\N	2025-12-14 22:17:43.36063
474	10	94	48	\N	Присутній	\N	2025-12-14 22:17:43.36063
475	10	95	48	5	Присутній	\N	2025-12-14 22:17:43.36063
476	10	96	48	1	Присутній	\N	2025-12-14 22:17:43.36063
477	10	97	48	\N	Присутній	\N	2025-12-14 22:17:43.36063
478	10	98	48	\N	Присутній	\N	2025-12-14 22:17:43.36063
479	10	99	48	\N	Присутній	\N	2025-12-14 22:17:43.36063
480	10	100	48	\N	Н	\N	2025-12-14 22:17:43.36063
481	10	91	49	\N	Присутній	\N	2025-12-14 22:17:43.36063
482	10	92	49	10	Присутній	\N	2025-12-14 22:17:43.36063
483	10	93	49	\N	Присутній	\N	2025-12-14 22:17:43.36063
484	10	94	49	\N	Присутній	\N	2025-12-14 22:17:43.36063
485	10	95	49	5	Присутній	\N	2025-12-14 22:17:43.36063
486	10	96	49	\N	Присутній	\N	2025-12-14 22:17:43.36063
487	10	97	49	\N	Присутній	\N	2025-12-14 22:17:43.36063
488	10	98	49	10	Присутній	\N	2025-12-14 22:17:43.36063
489	10	99	49	\N	Присутній	\N	2025-12-14 22:17:43.36063
490	10	100	49	\N	Н	\N	2025-12-14 22:17:43.36063
491	10	91	50	\N	Н	\N	2025-12-14 22:17:43.36063
492	10	92	50	\N	Н	\N	2025-12-14 22:17:43.36063
493	10	93	50	\N	Присутній	\N	2025-12-14 22:17:43.36063
494	10	94	50	\N	Н	\N	2025-12-14 22:17:43.36063
495	10	95	50	\N	Присутній	\N	2025-12-14 22:17:43.36063
496	10	96	50	\N	Присутній	\N	2025-12-14 22:17:43.36063
497	10	97	50	6	Присутній	\N	2025-12-14 22:17:43.36063
498	10	98	50	\N	Присутній	\N	2025-12-14 22:17:43.36063
499	10	99	50	\N	Присутній	\N	2025-12-14 22:17:43.36063
500	10	100	50	\N	Присутній	\N	2025-12-14 22:17:43.36063
501	11	101	51	\N	Н	\N	2025-12-14 22:17:43.36063
502	11	102	51	\N	Присутній	\N	2025-12-14 22:17:43.36063
503	11	103	51	\N	Присутній	\N	2025-12-14 22:17:43.36063
504	11	104	51	\N	Н	\N	2025-12-14 22:17:43.36063
505	11	105	51	\N	Присутній	\N	2025-12-14 22:17:43.36063
506	11	106	51	\N	Присутній	\N	2025-12-14 22:17:43.36063
507	11	107	51	\N	Присутній	\N	2025-12-14 22:17:43.36063
508	11	108	51	\N	Н	\N	2025-12-14 22:17:43.36063
509	11	109	51	\N	Присутній	\N	2025-12-14 22:17:43.36063
510	11	110	51	\N	Н	\N	2025-12-14 22:17:43.36063
511	11	101	52	\N	Присутній	\N	2025-12-14 22:17:43.36063
512	11	102	52	\N	Присутній	\N	2025-12-14 22:17:43.36063
513	11	103	52	8	Присутній	\N	2025-12-14 22:17:43.36063
514	11	104	52	\N	Н	\N	2025-12-14 22:17:43.36063
515	11	105	52	\N	Присутній	\N	2025-12-14 22:17:43.36063
516	11	106	52	\N	Присутній	\N	2025-12-14 22:17:43.36063
517	11	107	52	\N	Н	\N	2025-12-14 22:17:43.36063
518	11	108	52	6	Присутній	\N	2025-12-14 22:17:43.36063
519	11	109	52	4	Присутній	\N	2025-12-14 22:17:43.36063
520	11	110	52	\N	Н	\N	2025-12-14 22:17:43.36063
521	11	101	53	\N	Н	\N	2025-12-14 22:17:43.36063
522	11	102	53	\N	Н	\N	2025-12-14 22:17:43.36063
523	11	103	53	\N	Присутній	\N	2025-12-14 22:17:43.36063
524	11	104	53	\N	Присутній	\N	2025-12-14 22:17:43.36063
525	11	105	53	\N	Присутній	\N	2025-12-14 22:17:43.36063
526	11	106	53	\N	Присутній	\N	2025-12-14 22:17:43.36063
527	11	107	53	4	Присутній	\N	2025-12-14 22:17:43.36063
528	11	108	53	\N	Присутній	\N	2025-12-14 22:17:43.36063
529	11	109	53	\N	Присутній	\N	2025-12-14 22:17:43.36063
530	11	110	53	\N	Присутній	\N	2025-12-14 22:17:43.36063
531	11	101	54	\N	Присутній	\N	2025-12-14 22:17:43.36063
532	11	102	54	\N	Присутній	\N	2025-12-14 22:17:43.36063
533	11	103	54	\N	Присутній	\N	2025-12-14 22:17:43.36063
534	11	104	54	\N	Присутній	\N	2025-12-14 22:17:43.36063
535	11	105	54	4	Присутній	\N	2025-12-14 22:17:43.36063
536	11	106	54	\N	Н	\N	2025-12-14 22:17:43.36063
537	11	107	54	\N	Н	\N	2025-12-14 22:17:43.36063
538	11	108	54	\N	Присутній	\N	2025-12-14 22:17:43.36063
539	11	109	54	\N	Н	\N	2025-12-14 22:17:43.36063
540	11	110	54	\N	Присутній	\N	2025-12-14 22:17:43.36063
541	11	101	55	\N	Н	\N	2025-12-14 22:17:43.36063
542	11	102	55	\N	Присутній	\N	2025-12-14 22:17:43.36063
543	11	103	55	\N	Присутній	\N	2025-12-14 22:17:43.36063
544	11	104	55	\N	Н	\N	2025-12-14 22:17:43.36063
545	11	105	55	\N	Присутній	\N	2025-12-14 22:17:43.36063
546	11	106	55	\N	Н	\N	2025-12-14 22:17:43.36063
547	11	107	55	\N	Н	\N	2025-12-14 22:17:43.36063
548	11	108	55	\N	Присутній	\N	2025-12-14 22:17:43.36063
549	11	109	55	\N	Н	\N	2025-12-14 22:17:43.36063
550	11	110	55	\N	Присутній	\N	2025-12-14 22:17:43.36063
551	12	111	56	\N	Присутній	\N	2025-12-14 22:17:43.36063
552	12	112	56	\N	Присутній	\N	2025-12-14 22:17:43.36063
553	12	113	56	12	Присутній	\N	2025-12-14 22:17:43.36063
554	12	114	56	\N	Присутній	\N	2025-12-14 22:17:43.36063
555	12	115	56	\N	Присутній	\N	2025-12-14 22:17:43.36063
556	12	116	56	\N	Присутній	\N	2025-12-14 22:17:43.36063
557	12	117	56	\N	Присутній	\N	2025-12-14 22:17:43.36063
558	12	118	56	\N	Н	\N	2025-12-14 22:17:43.36063
559	12	119	56	4	Присутній	\N	2025-12-14 22:17:43.36063
560	12	120	56	\N	Н	\N	2025-12-14 22:17:43.36063
561	12	111	57	\N	Н	\N	2025-12-14 22:17:43.36063
562	12	112	57	\N	Н	\N	2025-12-14 22:17:43.36063
563	12	113	57	\N	Присутній	\N	2025-12-14 22:17:43.36063
564	12	114	57	1	Присутній	\N	2025-12-14 22:17:43.36063
565	12	115	57	\N	Присутній	\N	2025-12-14 22:17:43.36063
566	12	116	57	\N	Присутній	\N	2025-12-14 22:17:43.36063
567	12	117	57	\N	Присутній	\N	2025-12-14 22:17:43.36063
568	12	118	57	8	Присутній	\N	2025-12-14 22:17:43.36063
569	12	119	57	1	Присутній	\N	2025-12-14 22:17:43.36063
570	12	120	57	\N	Присутній	\N	2025-12-14 22:17:43.36063
571	12	111	58	\N	Присутній	\N	2025-12-14 22:17:43.36063
572	12	112	58	\N	Н	\N	2025-12-14 22:17:43.36063
573	12	113	58	1	Присутній	\N	2025-12-14 22:17:43.36063
574	12	114	58	\N	Н	\N	2025-12-14 22:17:43.36063
575	12	115	58	\N	Присутній	\N	2025-12-14 22:17:43.36063
576	12	116	58	2	Присутній	\N	2025-12-14 22:17:43.36063
577	12	117	58	\N	Н	\N	2025-12-14 22:17:43.36063
578	12	118	58	11	Присутній	\N	2025-12-14 22:17:43.36063
579	12	119	58	\N	Присутній	\N	2025-12-14 22:17:43.36063
580	12	120	58	10	Присутній	\N	2025-12-14 22:17:43.36063
581	12	111	59	\N	Присутній	\N	2025-12-14 22:17:43.36063
582	12	112	59	4	Присутній	\N	2025-12-14 22:17:43.36063
583	12	113	59	7	Присутній	\N	2025-12-14 22:17:43.36063
584	12	114	59	\N	Присутній	\N	2025-12-14 22:17:43.36063
585	12	115	59	\N	Присутній	\N	2025-12-14 22:17:43.36063
586	12	116	59	\N	Н	\N	2025-12-14 22:17:43.36063
587	12	117	59	\N	Присутній	\N	2025-12-14 22:17:43.36063
588	12	118	59	\N	Присутній	\N	2025-12-14 22:17:43.36063
589	12	119	59	\N	Н	\N	2025-12-14 22:17:43.36063
590	12	120	59	\N	Присутній	\N	2025-12-14 22:17:43.36063
591	12	111	60	\N	Присутній	\N	2025-12-14 22:17:43.36063
592	12	112	60	\N	Н	\N	2025-12-14 22:17:43.36063
593	12	113	60	\N	Присутній	\N	2025-12-14 22:17:43.36063
594	12	114	60	\N	Присутній	\N	2025-12-14 22:17:43.36063
595	12	115	60	\N	Присутній	\N	2025-12-14 22:17:43.36063
596	12	116	60	\N	Присутній	\N	2025-12-14 22:17:43.36063
597	12	117	60	\N	Н	\N	2025-12-14 22:17:43.36063
598	12	118	60	\N	Н	\N	2025-12-14 22:17:43.36063
599	12	119	60	\N	Присутній	\N	2025-12-14 22:17:43.36063
600	12	120	60	3	Присутній	\N	2025-12-14 22:17:43.36063
601	13	121	61	\N	Присутній	\N	2025-12-14 22:17:43.36063
602	13	122	61	7	Присутній	\N	2025-12-14 22:17:43.36063
603	13	123	61	\N	Присутній	\N	2025-12-14 22:17:43.36063
604	13	124	61	\N	Присутній	\N	2025-12-14 22:17:43.36063
605	13	125	61	\N	Н	\N	2025-12-14 22:17:43.36063
606	13	126	61	\N	Н	\N	2025-12-14 22:17:43.36063
607	13	127	61	\N	Присутній	\N	2025-12-14 22:17:43.36063
608	13	128	61	\N	Присутній	\N	2025-12-14 22:17:43.36063
609	13	129	61	\N	Присутній	\N	2025-12-14 22:17:43.36063
610	13	130	61	\N	Присутній	\N	2025-12-14 22:17:43.36063
611	13	121	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
612	13	122	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
613	13	123	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
614	13	124	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
615	13	125	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
616	13	126	62	\N	Н	\N	2025-12-14 22:17:43.36063
617	13	127	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
618	13	128	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
619	13	129	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
620	13	130	62	\N	Присутній	\N	2025-12-14 22:17:43.36063
621	13	121	63	3	Присутній	\N	2025-12-14 22:17:43.36063
622	13	122	63	\N	Присутній	\N	2025-12-14 22:17:43.36063
623	13	123	63	\N	Присутній	\N	2025-12-14 22:17:43.36063
624	13	124	63	\N	Присутній	\N	2025-12-14 22:17:43.36063
625	13	125	63	\N	Присутній	\N	2025-12-14 22:17:43.36063
626	13	126	63	\N	Н	\N	2025-12-14 22:17:43.36063
627	13	127	63	\N	Присутній	\N	2025-12-14 22:17:43.36063
628	13	128	63	\N	Н	\N	2025-12-14 22:17:43.36063
629	13	129	63	\N	Н	\N	2025-12-14 22:17:43.36063
630	13	130	63	\N	Н	\N	2025-12-14 22:17:43.36063
631	13	121	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
632	13	122	64	\N	Н	\N	2025-12-14 22:17:43.36063
633	13	123	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
634	13	124	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
635	13	125	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
636	13	126	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
637	13	127	64	4	Присутній	\N	2025-12-14 22:17:43.36063
638	13	128	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
639	13	129	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
640	13	130	64	\N	Присутній	\N	2025-12-14 22:17:43.36063
641	13	121	65	\N	Присутній	\N	2025-12-14 22:17:43.36063
642	13	122	65	\N	Присутній	\N	2025-12-14 22:17:43.36063
643	13	123	65	\N	Присутній	\N	2025-12-14 22:17:43.36063
644	13	124	65	\N	Н	\N	2025-12-14 22:17:43.36063
645	13	125	65	3	Присутній	\N	2025-12-14 22:17:43.36063
646	13	126	65	\N	Присутній	\N	2025-12-14 22:17:43.36063
647	13	127	65	\N	Присутній	\N	2025-12-14 22:17:43.36063
648	13	128	65	\N	Присутній	\N	2025-12-14 22:17:43.36063
649	13	129	65	10	Присутній	\N	2025-12-14 22:17:43.36063
650	13	130	65	\N	Н	\N	2025-12-14 22:17:43.36063
651	14	131	66	\N	Присутній	\N	2025-12-14 22:17:43.36063
652	14	132	66	\N	Присутній	\N	2025-12-14 22:17:43.36063
653	14	133	66	\N	Присутній	\N	2025-12-14 22:17:43.36063
654	14	134	66	\N	Н	\N	2025-12-14 22:17:43.36063
655	14	135	66	\N	Н	\N	2025-12-14 22:17:43.36063
656	14	136	66	3	Присутній	\N	2025-12-14 22:17:43.36063
657	14	137	66	\N	Н	\N	2025-12-14 22:17:43.36063
658	14	138	66	\N	Присутній	\N	2025-12-14 22:17:43.36063
659	14	139	66	\N	Н	\N	2025-12-14 22:17:43.36063
660	14	140	66	\N	Присутній	\N	2025-12-14 22:17:43.36063
661	14	131	67	\N	Присутній	\N	2025-12-14 22:17:43.36063
662	14	132	67	\N	Присутній	\N	2025-12-14 22:17:43.36063
663	14	133	67	\N	Присутній	\N	2025-12-14 22:17:43.36063
664	14	134	67	\N	Н	\N	2025-12-14 22:17:43.36063
665	14	135	67	\N	Н	\N	2025-12-14 22:17:43.36063
666	14	136	67	\N	Присутній	\N	2025-12-14 22:17:43.36063
667	14	137	67	\N	Н	\N	2025-12-14 22:17:43.36063
668	14	138	67	\N	Присутній	\N	2025-12-14 22:17:43.36063
669	14	139	67	\N	Присутній	\N	2025-12-14 22:17:43.36063
670	14	140	67	\N	Присутній	\N	2025-12-14 22:17:43.36063
671	14	131	68	\N	Присутній	\N	2025-12-14 22:17:43.36063
672	14	132	68	\N	Н	\N	2025-12-14 22:17:43.36063
673	14	133	68	6	Присутній	\N	2025-12-14 22:17:43.36063
674	14	134	68	\N	Присутній	\N	2025-12-14 22:17:43.36063
675	14	135	68	\N	Присутній	\N	2025-12-14 22:17:43.36063
676	14	136	68	\N	Н	\N	2025-12-14 22:17:43.36063
677	14	137	68	5	Присутній	\N	2025-12-14 22:17:43.36063
678	14	138	68	\N	Присутній	\N	2025-12-14 22:17:43.36063
679	14	139	68	\N	Присутній	\N	2025-12-14 22:17:43.36063
680	14	140	68	\N	Н	\N	2025-12-14 22:17:43.36063
681	14	131	69	\N	Присутній	\N	2025-12-14 22:17:43.36063
682	14	132	69	11	Присутній	\N	2025-12-14 22:17:43.36063
683	14	133	69	\N	Присутній	\N	2025-12-14 22:17:43.36063
684	14	134	69	\N	Н	\N	2025-12-14 22:17:43.36063
685	14	135	69	9	Присутній	\N	2025-12-14 22:17:43.36063
686	14	136	69	7	Присутній	\N	2025-12-14 22:17:43.36063
687	14	137	69	2	Присутній	\N	2025-12-14 22:17:43.36063
688	14	138	69	\N	Присутній	\N	2025-12-14 22:17:43.36063
689	14	139	69	3	Присутній	\N	2025-12-14 22:17:43.36063
690	14	140	69	\N	Присутній	\N	2025-12-14 22:17:43.36063
691	14	131	70	\N	Присутній	\N	2025-12-14 22:17:43.36063
692	14	132	70	\N	Присутній	\N	2025-12-14 22:17:43.36063
693	14	133	70	\N	Н	\N	2025-12-14 22:17:43.36063
694	14	134	70	\N	Присутній	\N	2025-12-14 22:17:43.36063
695	14	135	70	\N	Присутній	\N	2025-12-14 22:17:43.36063
696	14	136	70	\N	Н	\N	2025-12-14 22:17:43.36063
697	14	137	70	\N	Присутній	\N	2025-12-14 22:17:43.36063
698	14	138	70	\N	Н	\N	2025-12-14 22:17:43.36063
699	14	139	70	\N	Присутній	\N	2025-12-14 22:17:43.36063
700	14	140	70	\N	Присутній	\N	2025-12-14 22:17:43.36063
701	15	141	71	\N	Присутній	\N	2025-12-14 22:17:43.36063
702	15	142	71	\N	Присутній	\N	2025-12-14 22:17:43.36063
703	15	143	71	\N	Н	\N	2025-12-14 22:17:43.36063
704	15	144	71	\N	Присутній	\N	2025-12-14 22:17:43.36063
705	15	145	71	\N	Н	\N	2025-12-14 22:17:43.36063
706	15	146	71	\N	Присутній	\N	2025-12-14 22:17:43.36063
707	15	147	71	\N	Присутній	\N	2025-12-14 22:17:43.36063
708	15	148	71	\N	Присутній	\N	2025-12-14 22:17:43.36063
709	15	149	71	\N	Н	\N	2025-12-14 22:17:43.36063
710	15	150	71	\N	Н	\N	2025-12-14 22:17:43.36063
711	15	141	72	\N	Присутній	\N	2025-12-14 22:17:43.36063
712	15	142	72	\N	Присутній	\N	2025-12-14 22:17:43.36063
713	15	143	72	\N	Присутній	\N	2025-12-14 22:17:43.36063
714	15	144	72	9	Присутній	\N	2025-12-14 22:17:43.36063
715	15	145	72	\N	Присутній	\N	2025-12-14 22:17:43.36063
716	15	146	72	\N	Н	\N	2025-12-14 22:17:43.36063
717	15	147	72	\N	Присутній	\N	2025-12-14 22:17:43.36063
718	15	148	72	\N	Н	\N	2025-12-14 22:17:43.36063
719	15	149	72	\N	Присутній	\N	2025-12-14 22:17:43.36063
720	15	150	72	\N	Присутній	\N	2025-12-14 22:17:43.36063
721	15	141	73	\N	Присутній	\N	2025-12-14 22:17:43.36063
722	15	142	73	\N	Н	\N	2025-12-14 22:17:43.36063
723	15	143	73	\N	Н	\N	2025-12-14 22:17:43.36063
724	15	144	73	\N	Присутній	\N	2025-12-14 22:17:43.36063
725	15	145	73	\N	Н	\N	2025-12-14 22:17:43.36063
726	15	146	73	\N	Н	\N	2025-12-14 22:17:43.36063
727	15	147	73	\N	Присутній	\N	2025-12-14 22:17:43.36063
728	15	148	73	\N	Присутній	\N	2025-12-14 22:17:43.36063
729	15	149	73	\N	Н	\N	2025-12-14 22:17:43.36063
730	15	150	73	\N	Присутній	\N	2025-12-14 22:17:43.36063
731	15	141	74	\N	Присутній	\N	2025-12-14 22:17:43.36063
732	15	142	74	\N	Присутній	\N	2025-12-14 22:17:43.36063
733	15	143	74	1	Присутній	\N	2025-12-14 22:17:43.36063
734	15	144	74	10	Присутній	\N	2025-12-14 22:17:43.36063
735	15	145	74	\N	Н	\N	2025-12-14 22:17:43.36063
736	15	146	74	8	Присутній	\N	2025-12-14 22:17:43.36063
737	15	147	74	8	Присутній	\N	2025-12-14 22:17:43.36063
738	15	148	74	3	Присутній	\N	2025-12-14 22:17:43.36063
739	15	149	74	\N	Н	\N	2025-12-14 22:17:43.36063
740	15	150	74	\N	Присутній	\N	2025-12-14 22:17:43.36063
741	15	141	75	8	Присутній	\N	2025-12-14 22:17:43.36063
742	15	142	75	\N	Присутній	\N	2025-12-14 22:17:43.36063
743	15	143	75	\N	Н	\N	2025-12-14 22:17:43.36063
744	15	144	75	\N	Присутній	\N	2025-12-14 22:17:43.36063
745	15	145	75	\N	Н	\N	2025-12-14 22:17:43.36063
746	15	146	75	6	Присутній	\N	2025-12-14 22:17:43.36063
747	15	147	75	\N	Присутній	\N	2025-12-14 22:17:43.36063
748	15	148	75	\N	Присутній	\N	2025-12-14 22:17:43.36063
749	15	149	75	\N	Н	\N	2025-12-14 22:17:43.36063
750	15	150	75	\N	Н	\N	2025-12-14 22:17:43.36063
751	16	151	76	\N	Присутній	\N	2025-12-14 22:17:43.36063
752	16	152	76	\N	Присутній	\N	2025-12-14 22:17:43.36063
753	16	153	76	\N	Присутній	\N	2025-12-14 22:17:43.36063
754	16	154	76	2	Присутній	\N	2025-12-14 22:17:43.36063
755	16	155	76	\N	Н	\N	2025-12-14 22:17:43.36063
756	16	156	76	\N	Присутній	\N	2025-12-14 22:17:43.36063
757	16	157	76	\N	Н	\N	2025-12-14 22:17:43.36063
758	16	158	76	\N	Н	\N	2025-12-14 22:17:43.36063
759	16	159	76	2	Присутній	\N	2025-12-14 22:17:43.36063
760	16	160	76	\N	Присутній	\N	2025-12-14 22:17:43.36063
761	16	151	77	\N	Присутній	\N	2025-12-14 22:17:43.36063
762	16	152	77	3	Присутній	\N	2025-12-14 22:17:43.36063
763	16	153	77	\N	Присутній	\N	2025-12-14 22:17:43.36063
764	16	154	77	\N	Присутній	\N	2025-12-14 22:17:43.36063
765	16	155	77	1	Присутній	\N	2025-12-14 22:17:43.36063
766	16	156	77	\N	Н	\N	2025-12-14 22:17:43.36063
767	16	157	77	\N	Н	\N	2025-12-14 22:17:43.36063
768	16	158	77	9	Присутній	\N	2025-12-14 22:17:43.36063
769	16	159	77	\N	Н	\N	2025-12-14 22:17:43.36063
770	16	160	77	\N	Присутній	\N	2025-12-14 22:17:43.36063
771	16	151	78	3	Присутній	\N	2025-12-14 22:17:43.36063
772	16	152	78	7	Присутній	\N	2025-12-14 22:17:43.36063
773	16	153	78	\N	Присутній	\N	2025-12-14 22:17:43.36063
774	16	154	78	\N	Н	\N	2025-12-14 22:17:43.36063
775	16	155	78	\N	Присутній	\N	2025-12-14 22:17:43.36063
776	16	156	78	8	Присутній	\N	2025-12-14 22:17:43.36063
777	16	157	78	\N	Присутній	\N	2025-12-14 22:17:43.36063
778	16	158	78	\N	Присутній	\N	2025-12-14 22:17:43.36063
779	16	159	78	\N	Присутній	\N	2025-12-14 22:17:43.36063
780	16	160	78	\N	Присутній	\N	2025-12-14 22:17:43.36063
781	16	151	79	\N	Присутній	\N	2025-12-14 22:17:43.36063
782	16	152	79	\N	Н	\N	2025-12-14 22:17:43.36063
783	16	153	79	\N	Присутній	\N	2025-12-14 22:17:43.36063
784	16	154	79	6	Присутній	\N	2025-12-14 22:17:43.36063
785	16	155	79	\N	Присутній	\N	2025-12-14 22:17:43.36063
786	16	156	79	\N	Н	\N	2025-12-14 22:17:43.36063
787	16	157	79	\N	Присутній	\N	2025-12-14 22:17:43.36063
788	16	158	79	\N	Присутній	\N	2025-12-14 22:17:43.36063
789	16	159	79	\N	Присутній	\N	2025-12-14 22:17:43.36063
790	16	160	79	\N	Н	\N	2025-12-14 22:17:43.36063
791	16	151	80	\N	Присутній	\N	2025-12-14 22:17:43.36063
792	16	152	80	\N	Присутній	\N	2025-12-14 22:17:43.36063
793	16	153	80	7	Присутній	\N	2025-12-14 22:17:43.36063
794	16	154	80	\N	Присутній	\N	2025-12-14 22:17:43.36063
795	16	155	80	\N	Присутній	\N	2025-12-14 22:17:43.36063
796	16	156	80	\N	Присутній	\N	2025-12-14 22:17:43.36063
797	16	157	80	\N	Н	\N	2025-12-14 22:17:43.36063
798	16	158	80	\N	Присутній	\N	2025-12-14 22:17:43.36063
799	16	159	80	\N	Присутній	\N	2025-12-14 22:17:43.36063
800	16	160	80	\N	Н	\N	2025-12-14 22:17:43.36063
801	17	161	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
802	17	162	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
803	17	163	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
804	17	164	81	10	Присутній	\N	2025-12-14 22:17:43.36063
805	17	165	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
806	17	166	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
807	17	167	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
808	17	168	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
809	17	169	81	\N	Н	\N	2025-12-14 22:17:43.36063
810	17	170	81	\N	Присутній	\N	2025-12-14 22:17:43.36063
811	17	161	82	\N	Н	\N	2025-12-14 22:17:43.36063
812	17	162	82	5	Присутній	\N	2025-12-14 22:17:43.36063
813	17	163	82	\N	Присутній	\N	2025-12-14 22:17:43.36063
814	17	164	82	\N	Присутній	\N	2025-12-14 22:17:43.36063
815	17	165	82	\N	Присутній	\N	2025-12-14 22:17:43.36063
816	17	166	82	\N	Присутній	\N	2025-12-14 22:17:43.36063
817	17	167	82	\N	Присутній	\N	2025-12-14 22:17:43.36063
818	17	168	82	\N	Присутній	\N	2025-12-14 22:17:43.36063
819	17	169	82	\N	Присутній	\N	2025-12-14 22:17:43.36063
820	17	170	82	\N	Н	\N	2025-12-14 22:17:43.36063
821	17	161	83	\N	Н	\N	2025-12-14 22:17:43.36063
822	17	162	83	\N	Присутній	\N	2025-12-14 22:17:43.36063
823	17	163	83	\N	Присутній	\N	2025-12-14 22:17:43.36063
824	17	164	83	5	Присутній	\N	2025-12-14 22:17:43.36063
825	17	165	83	\N	Н	\N	2025-12-14 22:17:43.36063
826	17	166	83	\N	Н	\N	2025-12-14 22:17:43.36063
827	17	167	83	\N	Н	\N	2025-12-14 22:17:43.36063
828	17	168	83	\N	Присутній	\N	2025-12-14 22:17:43.36063
829	17	169	83	\N	Присутній	\N	2025-12-14 22:17:43.36063
830	17	170	83	\N	Н	\N	2025-12-14 22:17:43.36063
831	17	161	84	\N	Присутній	\N	2025-12-14 22:17:43.36063
832	17	162	84	\N	Н	\N	2025-12-14 22:17:43.36063
833	17	163	84	8	Присутній	\N	2025-12-14 22:17:43.36063
834	17	164	84	\N	Присутній	\N	2025-12-14 22:17:43.36063
835	17	165	84	\N	Н	\N	2025-12-14 22:17:43.36063
836	17	166	84	\N	Присутній	\N	2025-12-14 22:17:43.36063
837	17	167	84	\N	Присутній	\N	2025-12-14 22:17:43.36063
838	17	168	84	\N	Присутній	\N	2025-12-14 22:17:43.36063
839	17	169	84	4	Присутній	\N	2025-12-14 22:17:43.36063
840	17	170	84	\N	Присутній	\N	2025-12-14 22:17:43.36063
841	17	161	85	\N	Присутній	\N	2025-12-14 22:17:43.36063
842	17	162	85	\N	Присутній	\N	2025-12-14 22:17:43.36063
843	17	163	85	\N	Присутній	\N	2025-12-14 22:17:43.36063
844	17	164	85	\N	Присутній	\N	2025-12-14 22:17:43.36063
845	17	165	85	\N	Н	\N	2025-12-14 22:17:43.36063
846	17	166	85	\N	Присутній	\N	2025-12-14 22:17:43.36063
847	17	167	85	9	Присутній	\N	2025-12-14 22:17:43.36063
848	17	168	85	6	Присутній	\N	2025-12-14 22:17:43.36063
849	17	169	85	\N	Присутній	\N	2025-12-14 22:17:43.36063
850	17	170	85	\N	Присутній	\N	2025-12-14 22:17:43.36063
851	18	171	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
852	18	172	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
853	18	173	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
854	18	174	86	4	Присутній	\N	2025-12-14 22:17:43.36063
855	18	175	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
856	18	176	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
857	18	177	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
858	18	178	86	\N	Н	\N	2025-12-14 22:17:43.36063
859	18	179	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
860	18	180	86	\N	Присутній	\N	2025-12-14 22:17:43.36063
861	18	171	87	\N	Присутній	\N	2025-12-14 22:17:43.36063
862	18	172	87	\N	Присутній	\N	2025-12-14 22:17:43.36063
863	18	173	87	\N	Присутній	\N	2025-12-14 22:17:43.36063
864	18	174	87	\N	Присутній	\N	2025-12-14 22:17:43.36063
865	18	175	87	1	Присутній	\N	2025-12-14 22:17:43.36063
866	18	176	87	\N	Присутній	\N	2025-12-14 22:17:43.36063
867	18	177	87	\N	Н	\N	2025-12-14 22:17:43.36063
868	18	178	87	\N	Присутній	\N	2025-12-14 22:17:43.36063
869	18	179	87	9	Присутній	\N	2025-12-14 22:17:43.36063
870	18	180	87	8	Присутній	\N	2025-12-14 22:17:43.36063
871	18	171	88	\N	Н	\N	2025-12-14 22:17:43.36063
872	18	172	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
873	18	173	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
874	18	174	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
875	18	175	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
876	18	176	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
877	18	177	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
878	18	178	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
879	18	179	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
880	18	180	88	\N	Присутній	\N	2025-12-14 22:17:43.36063
881	18	171	89	\N	Присутній	\N	2025-12-14 22:17:43.36063
882	18	172	89	\N	Н	\N	2025-12-14 22:17:43.36063
883	18	173	89	\N	Присутній	\N	2025-12-14 22:17:43.36063
884	18	174	89	\N	Н	\N	2025-12-14 22:17:43.36063
885	18	175	89	\N	Н	\N	2025-12-14 22:17:43.36063
886	18	176	89	\N	Н	\N	2025-12-14 22:17:43.36063
887	18	177	89	\N	Н	\N	2025-12-14 22:17:43.36063
888	18	178	89	\N	Присутній	\N	2025-12-14 22:17:43.36063
889	18	179	89	\N	Н	\N	2025-12-14 22:17:43.36063
890	18	180	89	\N	Присутній	\N	2025-12-14 22:17:43.36063
891	18	171	90	\N	Присутній	\N	2025-12-14 22:17:43.36063
892	18	172	90	5	Присутній	\N	2025-12-14 22:17:43.36063
893	18	173	90	2	Присутній	\N	2025-12-14 22:17:43.36063
894	18	174	90	\N	Присутній	\N	2025-12-14 22:17:43.36063
895	18	175	90	\N	Присутній	\N	2025-12-14 22:17:43.36063
896	18	176	90	4	Присутній	\N	2025-12-14 22:17:43.36063
897	18	177	90	\N	Присутній	\N	2025-12-14 22:17:43.36063
898	18	178	90	\N	Присутній	\N	2025-12-14 22:17:43.36063
899	18	179	90	6	Присутній	\N	2025-12-14 22:17:43.36063
900	18	180	90	\N	Н	\N	2025-12-14 22:17:43.36063
901	19	181	91	10	Присутній	\N	2025-12-14 22:17:43.36063
902	19	182	91	\N	Н	\N	2025-12-14 22:17:43.36063
903	19	183	91	\N	Присутній	\N	2025-12-14 22:17:43.36063
904	19	184	91	\N	Присутній	\N	2025-12-14 22:17:43.36063
905	19	185	91	\N	Присутній	\N	2025-12-14 22:17:43.36063
906	19	186	91	\N	Присутній	\N	2025-12-14 22:17:43.36063
907	19	187	91	\N	Н	\N	2025-12-14 22:17:43.36063
908	19	188	91	\N	Присутній	\N	2025-12-14 22:17:43.36063
909	19	189	91	\N	Присутній	\N	2025-12-14 22:17:43.36063
910	19	190	91	\N	Присутній	\N	2025-12-14 22:17:43.36063
911	19	181	92	\N	Н	\N	2025-12-14 22:17:43.36063
912	19	182	92	\N	Присутній	\N	2025-12-14 22:17:43.36063
913	19	183	92	\N	Присутній	\N	2025-12-14 22:17:43.36063
914	19	184	92	\N	Присутній	\N	2025-12-14 22:17:43.36063
915	19	185	92	\N	Присутній	\N	2025-12-14 22:17:43.36063
916	19	186	92	1	Присутній	\N	2025-12-14 22:17:43.36063
917	19	187	92	6	Присутній	\N	2025-12-14 22:17:43.36063
918	19	188	92	\N	Присутній	\N	2025-12-14 22:17:43.36063
919	19	189	92	\N	Н	\N	2025-12-14 22:17:43.36063
920	19	190	92	\N	Н	\N	2025-12-14 22:17:43.36063
921	19	181	93	1	Присутній	\N	2025-12-14 22:17:43.36063
922	19	182	93	7	Присутній	\N	2025-12-14 22:17:43.36063
923	19	183	93	\N	Присутній	\N	2025-12-14 22:17:43.36063
924	19	184	93	\N	Присутній	\N	2025-12-14 22:17:43.36063
925	19	185	93	\N	Присутній	\N	2025-12-14 22:17:43.36063
926	19	186	93	\N	Присутній	\N	2025-12-14 22:17:43.36063
927	19	187	93	\N	Присутній	\N	2025-12-14 22:17:43.36063
928	19	188	93	9	Присутній	\N	2025-12-14 22:17:43.36063
929	19	189	93	\N	Н	\N	2025-12-14 22:17:43.36063
930	19	190	93	\N	Присутній	\N	2025-12-14 22:17:43.36063
931	19	181	94	\N	Присутній	\N	2025-12-14 22:17:43.36063
932	19	182	94	\N	Присутній	\N	2025-12-14 22:17:43.36063
933	19	183	94	\N	Присутній	\N	2025-12-14 22:17:43.36063
934	19	184	94	\N	Н	\N	2025-12-14 22:17:43.36063
935	19	185	94	\N	Присутній	\N	2025-12-14 22:17:43.36063
936	19	186	94	8	Присутній	\N	2025-12-14 22:17:43.36063
937	19	187	94	\N	Присутній	\N	2025-12-14 22:17:43.36063
938	19	188	94	\N	Н	\N	2025-12-14 22:17:43.36063
939	19	189	94	12	Присутній	\N	2025-12-14 22:17:43.36063
940	19	190	94	\N	Присутній	\N	2025-12-14 22:17:43.36063
941	19	181	95	2	Присутній	\N	2025-12-14 22:17:43.36063
942	19	182	95	\N	Н	\N	2025-12-14 22:17:43.36063
943	19	183	95	3	Присутній	\N	2025-12-14 22:17:43.36063
944	19	184	95	\N	Н	\N	2025-12-14 22:17:43.36063
945	19	185	95	\N	Присутній	\N	2025-12-14 22:17:43.36063
946	19	186	95	\N	Присутній	\N	2025-12-14 22:17:43.36063
947	19	187	95	\N	Н	\N	2025-12-14 22:17:43.36063
948	19	188	95	\N	Присутній	\N	2025-12-14 22:17:43.36063
949	19	189	95	\N	Присутній	\N	2025-12-14 22:17:43.36063
950	19	190	95	\N	Присутній	\N	2025-12-14 22:17:43.36063
951	20	191	96	\N	Присутній	\N	2025-12-14 22:17:43.36063
952	20	192	96	12	Присутній	\N	2025-12-14 22:17:43.36063
953	20	193	96	11	Присутній	\N	2025-12-14 22:17:43.36063
954	20	194	96	\N	Присутній	\N	2025-12-14 22:17:43.36063
955	20	195	96	\N	Присутній	\N	2025-12-14 22:17:43.36063
956	20	196	96	\N	Присутній	\N	2025-12-14 22:17:43.36063
957	20	197	96	\N	Н	\N	2025-12-14 22:17:43.36063
958	20	198	96	\N	Присутній	\N	2025-12-14 22:17:43.36063
959	20	199	96	\N	Н	\N	2025-12-14 22:17:43.36063
960	20	200	96	\N	Н	\N	2025-12-14 22:17:43.36063
961	20	191	97	\N	Присутній	\N	2025-12-14 22:17:43.36063
962	20	192	97	\N	Н	\N	2025-12-14 22:17:43.36063
963	20	193	97	7	Присутній	\N	2025-12-14 22:17:43.36063
964	20	194	97	\N	Н	\N	2025-12-14 22:17:43.36063
965	20	195	97	\N	Н	\N	2025-12-14 22:17:43.36063
966	20	196	97	\N	Присутній	\N	2025-12-14 22:17:43.36063
967	20	197	97	\N	Присутній	\N	2025-12-14 22:17:43.36063
968	20	198	97	\N	Присутній	\N	2025-12-14 22:17:43.36063
969	20	199	97	2	Присутній	\N	2025-12-14 22:17:43.36063
970	20	200	97	2	Присутній	\N	2025-12-14 22:17:43.36063
971	20	191	98	\N	Присутній	\N	2025-12-14 22:17:43.36063
972	20	192	98	\N	Н	\N	2025-12-14 22:17:43.36063
973	20	193	98	1	Присутній	\N	2025-12-14 22:17:43.36063
974	20	194	98	\N	Присутній	\N	2025-12-14 22:17:43.36063
975	20	195	98	\N	Присутній	\N	2025-12-14 22:17:43.36063
976	20	196	98	\N	Н	\N	2025-12-14 22:17:43.36063
977	20	197	98	6	Присутній	\N	2025-12-14 22:17:43.36063
978	20	198	98	\N	Присутній	\N	2025-12-14 22:17:43.36063
979	20	199	98	\N	Присутній	\N	2025-12-14 22:17:43.36063
980	20	200	98	\N	Н	\N	2025-12-14 22:17:43.36063
981	20	191	99	\N	Присутній	\N	2025-12-14 22:17:43.36063
982	20	192	99	5	Присутній	\N	2025-12-14 22:17:43.36063
983	20	193	99	\N	Присутній	\N	2025-12-14 22:17:43.36063
984	20	194	99	\N	Н	\N	2025-12-14 22:17:43.36063
985	20	195	99	\N	Присутній	\N	2025-12-14 22:17:43.36063
986	20	196	99	\N	Н	\N	2025-12-14 22:17:43.36063
987	20	197	99	\N	Присутній	\N	2025-12-14 22:17:43.36063
988	20	198	99	\N	Н	\N	2025-12-14 22:17:43.36063
989	20	199	99	9	Присутній	\N	2025-12-14 22:17:43.36063
990	20	200	99	\N	Н	\N	2025-12-14 22:17:43.36063
991	20	191	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
992	20	192	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
993	20	193	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
994	20	194	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
995	20	195	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
996	20	196	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
997	20	197	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
998	20	198	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
999	20	199	100	11	Присутній	\N	2025-12-14 22:17:43.36063
1000	20	200	100	\N	Присутній	\N	2025-12-14 22:17:43.36063
1001	21	201	101	\N	Н	\N	2025-12-14 22:17:43.36063
1002	21	202	101	12	Присутній	\N	2025-12-14 22:17:43.36063
1003	21	203	101	\N	Присутній	\N	2025-12-14 22:17:43.36063
1004	21	204	101	\N	Присутній	\N	2025-12-14 22:17:43.36063
1005	21	205	101	\N	Н	\N	2025-12-14 22:17:43.36063
1006	21	206	101	3	Присутній	\N	2025-12-14 22:17:43.36063
1007	21	207	101	\N	Присутній	\N	2025-12-14 22:17:43.36063
1008	21	208	101	\N	Н	\N	2025-12-14 22:17:43.36063
1009	21	209	101	11	Присутній	\N	2025-12-14 22:17:43.36063
1010	21	210	101	\N	Присутній	\N	2025-12-14 22:17:43.36063
1011	21	201	102	9	Присутній	\N	2025-12-14 22:17:43.36063
1012	21	202	102	\N	Н	\N	2025-12-14 22:17:43.36063
1013	21	203	102	\N	Н	\N	2025-12-14 22:17:43.36063
1014	21	204	102	\N	Н	\N	2025-12-14 22:17:43.36063
1015	21	205	102	\N	Н	\N	2025-12-14 22:17:43.36063
1016	21	206	102	\N	Присутній	\N	2025-12-14 22:17:43.36063
1017	21	207	102	\N	Присутній	\N	2025-12-14 22:17:43.36063
1018	21	208	102	\N	Присутній	\N	2025-12-14 22:17:43.36063
1019	21	209	102	1	Присутній	\N	2025-12-14 22:17:43.36063
1020	21	210	102	10	Присутній	\N	2025-12-14 22:17:43.36063
1021	21	201	103	2	Присутній	\N	2025-12-14 22:17:43.36063
1022	21	202	103	\N	Н	\N	2025-12-14 22:17:43.36063
1023	21	203	103	\N	Присутній	\N	2025-12-14 22:17:43.36063
1024	21	204	103	\N	Присутній	\N	2025-12-14 22:17:43.36063
1025	21	205	103	\N	Н	\N	2025-12-14 22:17:43.36063
1026	21	206	103	\N	Н	\N	2025-12-14 22:17:43.36063
1027	21	207	103	\N	Присутній	\N	2025-12-14 22:17:43.36063
1028	21	208	103	7	Присутній	\N	2025-12-14 22:17:43.36063
1029	21	209	103	11	Присутній	\N	2025-12-14 22:17:43.36063
1030	21	210	103	\N	Присутній	\N	2025-12-14 22:17:43.36063
1031	21	201	104	\N	Присутній	\N	2025-12-14 22:17:43.36063
1032	21	202	104	\N	Присутній	\N	2025-12-14 22:17:43.36063
1033	21	203	104	7	Присутній	\N	2025-12-14 22:17:43.36063
1034	21	204	104	\N	Присутній	\N	2025-12-14 22:17:43.36063
1035	21	205	104	4	Присутній	\N	2025-12-14 22:17:43.36063
1036	21	206	104	\N	Н	\N	2025-12-14 22:17:43.36063
1037	21	207	104	\N	Н	\N	2025-12-14 22:17:43.36063
1038	21	208	104	5	Присутній	\N	2025-12-14 22:17:43.36063
1039	21	209	104	\N	Н	\N	2025-12-14 22:17:43.36063
1040	21	210	104	8	Присутній	\N	2025-12-14 22:17:43.36063
1041	21	201	105	\N	Присутній	\N	2025-12-14 22:17:43.36063
1042	21	202	105	7	Присутній	\N	2025-12-14 22:17:43.36063
1043	21	203	105	\N	Присутній	\N	2025-12-14 22:17:43.36063
1044	21	204	105	\N	Н	\N	2025-12-14 22:17:43.36063
1045	21	205	105	\N	Присутній	\N	2025-12-14 22:17:43.36063
1046	21	206	105	\N	Присутній	\N	2025-12-14 22:17:43.36063
1047	21	207	105	\N	Н	\N	2025-12-14 22:17:43.36063
1048	21	208	105	\N	Н	\N	2025-12-14 22:17:43.36063
1049	21	209	105	\N	Присутній	\N	2025-12-14 22:17:43.36063
1050	21	210	105	\N	Н	\N	2025-12-14 22:17:43.36063
1051	22	211	106	\N	Присутній	\N	2025-12-14 22:17:43.36063
1052	22	212	106	6	Присутній	\N	2025-12-14 22:17:43.36063
1053	22	213	106	\N	Присутній	\N	2025-12-14 22:17:43.36063
1054	22	214	106	\N	Присутній	\N	2025-12-14 22:17:43.36063
1055	22	215	106	\N	Присутній	\N	2025-12-14 22:17:43.36063
1056	22	216	106	\N	Н	\N	2025-12-14 22:17:43.36063
1057	22	217	106	1	Присутній	\N	2025-12-14 22:17:43.36063
1058	22	218	106	\N	Присутній	\N	2025-12-14 22:17:43.36063
1059	22	219	106	10	Присутній	\N	2025-12-14 22:17:43.36063
1060	22	220	106	\N	Присутній	\N	2025-12-14 22:17:43.36063
1061	22	211	107	\N	Присутній	\N	2025-12-14 22:17:43.36063
1062	22	212	107	\N	Н	\N	2025-12-14 22:17:43.36063
1063	22	213	107	\N	Н	\N	2025-12-14 22:17:43.36063
1064	22	214	107	7	Присутній	\N	2025-12-14 22:17:43.36063
1065	22	215	107	\N	Присутній	\N	2025-12-14 22:17:43.36063
1066	22	216	107	\N	Присутній	\N	2025-12-14 22:17:43.36063
1067	22	217	107	\N	Н	\N	2025-12-14 22:17:43.36063
1068	22	218	107	\N	Н	\N	2025-12-14 22:17:43.36063
1069	22	219	107	\N	Н	\N	2025-12-14 22:17:43.36063
1070	22	220	107	\N	Н	\N	2025-12-14 22:17:43.36063
1071	22	211	108	9	Присутній	\N	2025-12-14 22:17:43.36063
1072	22	212	108	\N	Присутній	\N	2025-12-14 22:17:43.36063
1073	22	213	108	\N	Присутній	\N	2025-12-14 22:17:43.36063
1074	22	214	108	6	Присутній	\N	2025-12-14 22:17:43.36063
1075	22	215	108	\N	Н	\N	2025-12-14 22:17:43.36063
1076	22	216	108	\N	Присутній	\N	2025-12-14 22:17:43.36063
1077	22	217	108	\N	Присутній	\N	2025-12-14 22:17:43.36063
1078	22	218	108	2	Присутній	\N	2025-12-14 22:17:43.36063
1079	22	219	108	4	Присутній	\N	2025-12-14 22:17:43.36063
1080	22	220	108	3	Присутній	\N	2025-12-14 22:17:43.36063
1081	22	211	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1082	22	212	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1083	22	213	109	11	Присутній	\N	2025-12-14 22:17:43.36063
1084	22	214	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1085	22	215	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1086	22	216	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1087	22	217	109	\N	Н	\N	2025-12-14 22:17:43.36063
1088	22	218	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1089	22	219	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1090	22	220	109	\N	Присутній	\N	2025-12-14 22:17:43.36063
1091	22	211	110	\N	Присутній	\N	2025-12-14 22:17:43.36063
1092	22	212	110	\N	Присутній	\N	2025-12-14 22:17:43.36063
1093	22	213	110	\N	Присутній	\N	2025-12-14 22:17:43.36063
1094	22	214	110	2	Присутній	\N	2025-12-14 22:17:43.36063
1095	22	215	110	\N	Присутній	\N	2025-12-14 22:17:43.36063
1096	22	216	110	\N	Присутній	\N	2025-12-14 22:17:43.36063
1097	22	217	110	\N	Присутній	\N	2025-12-14 22:17:43.36063
1098	22	218	110	\N	Присутній	\N	2025-12-14 22:17:43.36063
1099	22	219	110	\N	Н	\N	2025-12-14 22:17:43.36063
1100	22	220	110	8	Присутній	\N	2025-12-14 22:17:43.36063
1101	23	221	111	\N	Присутній	\N	2025-12-14 22:17:43.36063
1102	23	222	111	5	Присутній	\N	2025-12-14 22:17:43.36063
1103	23	223	111	2	Присутній	\N	2025-12-14 22:17:43.36063
1104	23	224	111	\N	Присутній	\N	2025-12-14 22:17:43.36063
1105	23	225	111	\N	Присутній	\N	2025-12-14 22:17:43.36063
1106	23	226	111	\N	Присутній	\N	2025-12-14 22:17:43.36063
1107	23	227	111	\N	Присутній	\N	2025-12-14 22:17:43.36063
1108	23	228	111	\N	Присутній	\N	2025-12-14 22:17:43.36063
1109	23	229	111	\N	Присутній	\N	2025-12-14 22:17:43.36063
1110	23	230	111	\N	Н	\N	2025-12-14 22:17:43.36063
1111	23	221	112	\N	Присутній	\N	2025-12-14 22:17:43.36063
1112	23	222	112	\N	Присутній	\N	2025-12-14 22:17:43.36063
1113	23	223	112	\N	Н	\N	2025-12-14 22:17:43.36063
1114	23	224	112	\N	Присутній	\N	2025-12-14 22:17:43.36063
1115	23	225	112	1	Присутній	\N	2025-12-14 22:17:43.36063
1116	23	226	112	\N	Присутній	\N	2025-12-14 22:17:43.36063
1117	23	227	112	\N	Присутній	\N	2025-12-14 22:17:43.36063
1118	23	228	112	\N	Присутній	\N	2025-12-14 22:17:43.36063
1119	23	229	112	\N	Присутній	\N	2025-12-14 22:17:43.36063
1120	23	230	112	11	Присутній	\N	2025-12-14 22:17:43.36063
1121	23	221	113	4	Присутній	\N	2025-12-14 22:17:43.36063
1122	23	222	113	\N	Присутній	\N	2025-12-14 22:17:43.36063
1123	23	223	113	\N	Присутній	\N	2025-12-14 22:17:43.36063
1124	23	224	113	\N	Присутній	\N	2025-12-14 22:17:43.36063
1125	23	225	113	\N	Присутній	\N	2025-12-14 22:17:43.36063
1126	23	226	113	\N	Н	\N	2025-12-14 22:17:43.36063
1127	23	227	113	\N	Присутній	\N	2025-12-14 22:17:43.36063
1128	23	228	113	\N	Н	\N	2025-12-14 22:17:43.36063
1129	23	229	113	\N	Присутній	\N	2025-12-14 22:17:43.36063
1130	23	230	113	\N	Присутній	\N	2025-12-14 22:17:43.36063
1131	23	221	114	11	Присутній	\N	2025-12-14 22:17:43.36063
1132	23	222	114	\N	Присутній	\N	2025-12-14 22:17:43.36063
1133	23	223	114	2	Присутній	\N	2025-12-14 22:17:43.36063
1134	23	224	114	\N	Присутній	\N	2025-12-14 22:17:43.36063
1135	23	225	114	\N	Н	\N	2025-12-14 22:17:43.36063
1136	23	226	114	\N	Н	\N	2025-12-14 22:17:43.36063
1137	23	227	114	\N	Присутній	\N	2025-12-14 22:17:43.36063
1138	23	228	114	\N	Присутній	\N	2025-12-14 22:17:43.36063
1139	23	229	114	\N	Присутній	\N	2025-12-14 22:17:43.36063
1140	23	230	114	2	Присутній	\N	2025-12-14 22:17:43.36063
1141	23	221	115	\N	Присутній	\N	2025-12-14 22:17:43.36063
1142	23	222	115	6	Присутній	\N	2025-12-14 22:17:43.36063
1143	23	223	115	\N	Н	\N	2025-12-14 22:17:43.36063
1144	23	224	115	\N	Присутній	\N	2025-12-14 22:17:43.36063
1145	23	225	115	\N	Присутній	\N	2025-12-14 22:17:43.36063
1146	23	226	115	12	Присутній	\N	2025-12-14 22:17:43.36063
1147	23	227	115	\N	Присутній	\N	2025-12-14 22:17:43.36063
1148	23	228	115	\N	Н	\N	2025-12-14 22:17:43.36063
1149	23	229	115	\N	Н	\N	2025-12-14 22:17:43.36063
1150	23	230	115	\N	Присутній	\N	2025-12-14 22:17:43.36063
1151	24	231	116	\N	Присутній	\N	2025-12-14 22:17:43.36063
1152	24	232	116	\N	Присутній	\N	2025-12-14 22:17:43.36063
1153	24	233	116	\N	Присутній	\N	2025-12-14 22:17:43.36063
1154	24	234	116	\N	Присутній	\N	2025-12-14 22:17:43.36063
1155	24	235	116	\N	Присутній	\N	2025-12-14 22:17:43.36063
1156	24	236	116	\N	Присутній	\N	2025-12-14 22:17:43.36063
1157	24	237	116	\N	Присутній	\N	2025-12-14 22:17:43.36063
1158	24	238	116	\N	Н	\N	2025-12-14 22:17:43.36063
1159	24	239	116	\N	Н	\N	2025-12-14 22:17:43.36063
1160	24	240	116	\N	Н	\N	2025-12-14 22:17:43.36063
1161	24	231	117	4	Присутній	\N	2025-12-14 22:17:43.36063
1162	24	232	117	\N	Н	\N	2025-12-14 22:17:43.36063
1163	24	233	117	\N	Присутній	\N	2025-12-14 22:17:43.36063
1164	24	234	117	3	Присутній	\N	2025-12-14 22:17:43.36063
1165	24	235	117	5	Присутній	\N	2025-12-14 22:17:43.36063
1166	24	236	117	\N	Присутній	\N	2025-12-14 22:17:43.36063
1167	24	237	117	9	Присутній	\N	2025-12-14 22:17:43.36063
1168	24	238	117	\N	Присутній	\N	2025-12-14 22:17:43.36063
1169	24	239	117	\N	Присутній	\N	2025-12-14 22:17:43.36063
1170	24	240	117	6	Присутній	\N	2025-12-14 22:17:43.36063
1171	24	231	118	\N	Присутній	\N	2025-12-14 22:17:43.36063
1172	24	232	118	\N	Присутній	\N	2025-12-14 22:17:43.36063
1173	24	233	118	\N	Присутній	\N	2025-12-14 22:17:43.36063
1174	24	234	118	3	Присутній	\N	2025-12-14 22:17:43.36063
1175	24	235	118	\N	Присутній	\N	2025-12-14 22:17:43.36063
1176	24	236	118	\N	Присутній	\N	2025-12-14 22:17:43.36063
1177	24	237	118	\N	Присутній	\N	2025-12-14 22:17:43.36063
1178	24	238	118	8	Присутній	\N	2025-12-14 22:17:43.36063
1179	24	239	118	6	Присутній	\N	2025-12-14 22:17:43.36063
1180	24	240	118	\N	Присутній	\N	2025-12-14 22:17:43.36063
1181	24	231	119	\N	Н	\N	2025-12-14 22:17:43.36063
1182	24	232	119	\N	Н	\N	2025-12-14 22:17:43.36063
1183	24	233	119	\N	Н	\N	2025-12-14 22:17:43.36063
1184	24	234	119	\N	Присутній	\N	2025-12-14 22:17:43.36063
1185	24	235	119	\N	Н	\N	2025-12-14 22:17:43.36063
1186	24	236	119	\N	Присутній	\N	2025-12-14 22:17:43.36063
1187	24	237	119	\N	Н	\N	2025-12-14 22:17:43.36063
1188	24	238	119	\N	Присутній	\N	2025-12-14 22:17:43.36063
1189	24	239	119	\N	Присутній	\N	2025-12-14 22:17:43.36063
1190	24	240	119	\N	Присутній	\N	2025-12-14 22:17:43.36063
1191	24	231	120	\N	Н	\N	2025-12-14 22:17:43.36063
1192	24	232	120	\N	Присутній	\N	2025-12-14 22:17:43.36063
1193	24	233	120	\N	Присутній	\N	2025-12-14 22:17:43.36063
1194	24	234	120	\N	Присутній	\N	2025-12-14 22:17:43.36063
1195	24	235	120	\N	Н	\N	2025-12-14 22:17:43.36063
1196	24	236	120	\N	Н	\N	2025-12-14 22:17:43.36063
1197	24	237	120	\N	Присутній	\N	2025-12-14 22:17:43.36063
1198	24	238	120	\N	Присутній	\N	2025-12-14 22:17:43.36063
1199	24	239	120	\N	Присутній	\N	2025-12-14 22:17:43.36063
1200	24	240	120	\N	Присутній	\N	2025-12-14 22:17:43.36063
1201	25	241	121	5	Присутній	\N	2025-12-14 22:17:43.36063
1202	25	242	121	8	Присутній	\N	2025-12-14 22:17:43.36063
1203	25	243	121	\N	Присутній	\N	2025-12-14 22:17:43.36063
1204	25	244	121	\N	Присутній	\N	2025-12-14 22:17:43.36063
1205	25	245	121	9	Присутній	\N	2025-12-14 22:17:43.36063
1206	25	246	121	\N	Присутній	\N	2025-12-14 22:17:43.36063
1207	25	247	121	\N	Н	\N	2025-12-14 22:17:43.36063
1208	25	248	121	\N	Присутній	\N	2025-12-14 22:17:43.36063
1209	25	249	121	\N	Н	\N	2025-12-14 22:17:43.36063
1210	25	250	121	\N	Присутній	\N	2025-12-14 22:17:43.36063
1211	25	241	122	7	Присутній	\N	2025-12-14 22:17:43.36063
1212	25	242	122	4	Присутній	\N	2025-12-14 22:17:43.36063
1213	25	243	122	\N	Присутній	\N	2025-12-14 22:17:43.36063
1214	25	244	122	\N	Присутній	\N	2025-12-14 22:17:43.36063
1215	25	245	122	\N	Присутній	\N	2025-12-14 22:17:43.36063
1216	25	246	122	\N	Н	\N	2025-12-14 22:17:43.36063
1217	25	247	122	\N	Н	\N	2025-12-14 22:17:43.36063
1218	25	248	122	\N	Н	\N	2025-12-14 22:17:43.36063
1219	25	249	122	\N	Н	\N	2025-12-14 22:17:43.36063
1220	25	250	122	4	Присутній	\N	2025-12-14 22:17:43.36063
1221	25	241	123	2	Присутній	\N	2025-12-14 22:17:43.36063
1222	25	242	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1223	25	243	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1224	25	244	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1225	25	245	123	5	Присутній	\N	2025-12-14 22:17:43.36063
1226	25	246	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1227	25	247	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1228	25	248	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1229	25	249	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1230	25	250	123	\N	Присутній	\N	2025-12-14 22:17:43.36063
1231	25	241	124	\N	Присутній	\N	2025-12-14 22:17:43.36063
1232	25	242	124	\N	Присутній	\N	2025-12-14 22:17:43.36063
1233	25	243	124	4	Присутній	\N	2025-12-14 22:17:43.36063
1234	25	244	124	\N	Присутній	\N	2025-12-14 22:17:43.36063
1235	25	245	124	\N	Присутній	\N	2025-12-14 22:17:43.36063
1236	25	246	124	\N	Присутній	\N	2025-12-14 22:17:43.36063
1237	25	247	124	\N	Присутній	\N	2025-12-14 22:17:43.36063
1238	25	248	124	5	Присутній	\N	2025-12-14 22:17:43.36063
1239	25	249	124	\N	Н	\N	2025-12-14 22:17:43.36063
1240	25	250	124	4	Присутній	\N	2025-12-14 22:17:43.36063
1241	25	241	125	\N	Н	\N	2025-12-14 22:17:43.36063
1242	25	242	125	\N	Присутній	\N	2025-12-14 22:17:43.36063
1243	25	243	125	\N	Присутній	\N	2025-12-14 22:17:43.36063
1244	25	244	125	8	Присутній	\N	2025-12-14 22:17:43.36063
1245	25	245	125	\N	Присутній	\N	2025-12-14 22:17:43.36063
1246	25	246	125	9	Присутній	\N	2025-12-14 22:17:43.36063
1247	25	247	125	\N	Присутній	\N	2025-12-14 22:17:43.36063
1248	25	248	125	\N	Присутній	\N	2025-12-14 22:17:43.36063
1249	25	249	125	\N	Н	\N	2025-12-14 22:17:43.36063
1250	25	250	125	6	Присутній	\N	2025-12-14 22:17:43.36063
1251	26	251	126	\N	Н	\N	2025-12-14 22:17:43.36063
1252	26	252	126	\N	Н	\N	2025-12-14 22:17:43.36063
1253	26	253	126	\N	Присутній	\N	2025-12-14 22:17:43.36063
1254	26	254	126	6	Присутній	\N	2025-12-14 22:17:43.36063
1255	26	255	126	9	Присутній	\N	2025-12-14 22:17:43.36063
1256	26	256	126	\N	Присутній	\N	2025-12-14 22:17:43.36063
1257	26	257	126	\N	Присутній	\N	2025-12-14 22:17:43.36063
1258	26	258	126	\N	Присутній	\N	2025-12-14 22:17:43.36063
1259	26	259	126	8	Присутній	\N	2025-12-14 22:17:43.36063
1260	26	260	126	7	Присутній	\N	2025-12-14 22:17:43.36063
1261	26	251	127	\N	Присутній	\N	2025-12-14 22:17:43.36063
1262	26	252	127	\N	Н	\N	2025-12-14 22:17:43.36063
1263	26	253	127	2	Присутній	\N	2025-12-14 22:17:43.36063
1264	26	254	127	\N	Н	\N	2025-12-14 22:17:43.36063
1265	26	255	127	\N	Присутній	\N	2025-12-14 22:17:43.36063
1266	26	256	127	\N	Присутній	\N	2025-12-14 22:17:43.36063
1267	26	257	127	\N	Присутній	\N	2025-12-14 22:17:43.36063
1268	26	258	127	\N	Присутній	\N	2025-12-14 22:17:43.36063
1269	26	259	127	\N	Н	\N	2025-12-14 22:17:43.36063
1270	26	260	127	9	Присутній	\N	2025-12-14 22:17:43.36063
1271	26	251	128	\N	Н	\N	2025-12-14 22:17:43.36063
1272	26	252	128	\N	Присутній	\N	2025-12-14 22:17:43.36063
1273	26	253	128	\N	Присутній	\N	2025-12-14 22:17:43.36063
1274	26	254	128	\N	Присутній	\N	2025-12-14 22:17:43.36063
1275	26	255	128	\N	Присутній	\N	2025-12-14 22:17:43.36063
1276	26	256	128	\N	Присутній	\N	2025-12-14 22:17:43.36063
1277	26	257	128	3	Присутній	\N	2025-12-14 22:17:43.36063
1278	26	258	128	8	Присутній	\N	2025-12-14 22:17:43.36063
1279	26	259	128	4	Присутній	\N	2025-12-14 22:17:43.36063
1280	26	260	128	4	Присутній	\N	2025-12-14 22:17:43.36063
1281	26	251	129	\N	Присутній	\N	2025-12-14 22:17:43.36063
1282	26	252	129	\N	Н	\N	2025-12-14 22:17:43.36063
1283	26	253	129	\N	Н	\N	2025-12-14 22:17:43.36063
1284	26	254	129	\N	Н	\N	2025-12-14 22:17:43.36063
1285	26	255	129	\N	Присутній	\N	2025-12-14 22:17:43.36063
1286	26	256	129	\N	Присутній	\N	2025-12-14 22:17:43.36063
1287	26	257	129	11	Присутній	\N	2025-12-14 22:17:43.36063
1288	26	258	129	6	Присутній	\N	2025-12-14 22:17:43.36063
1289	26	259	129	\N	Присутній	\N	2025-12-14 22:17:43.36063
1290	26	260	129	11	Присутній	\N	2025-12-14 22:17:43.36063
1291	26	251	130	\N	Н	\N	2025-12-14 22:17:43.36063
1292	26	252	130	6	Присутній	\N	2025-12-14 22:17:43.36063
1293	26	253	130	\N	Н	\N	2025-12-14 22:17:43.36063
1294	26	254	130	\N	Н	\N	2025-12-14 22:17:43.36063
1295	26	255	130	\N	Н	\N	2025-12-14 22:17:43.36063
1296	26	256	130	\N	Присутній	\N	2025-12-14 22:17:43.36063
1297	26	257	130	\N	Н	\N	2025-12-14 22:17:43.36063
1298	26	258	130	12	Присутній	\N	2025-12-14 22:17:43.36063
1299	26	259	130	\N	Присутній	\N	2025-12-14 22:17:43.36063
1300	26	260	130	\N	Присутній	\N	2025-12-14 22:17:43.36063
1301	27	261	131	\N	Присутній	\N	2025-12-14 22:17:43.36063
1302	27	262	131	\N	Присутній	\N	2025-12-14 22:17:43.36063
1303	27	263	131	\N	Присутній	\N	2025-12-14 22:17:43.36063
1304	27	264	131	10	Присутній	\N	2025-12-14 22:17:43.36063
1305	27	265	131	\N	Присутній	\N	2025-12-14 22:17:43.36063
1306	27	266	131	5	Присутній	\N	2025-12-14 22:17:43.36063
1307	27	267	131	\N	Н	\N	2025-12-14 22:17:43.36063
1308	27	268	131	11	Присутній	\N	2025-12-14 22:17:43.36063
1309	27	269	131	\N	Н	\N	2025-12-14 22:17:43.36063
1310	27	270	131	\N	Н	\N	2025-12-14 22:17:43.36063
1311	27	261	132	\N	Присутній	\N	2025-12-14 22:17:43.36063
1312	27	262	132	8	Присутній	\N	2025-12-14 22:17:43.36063
1313	27	263	132	\N	Н	\N	2025-12-14 22:17:43.36063
1314	27	264	132	6	Присутній	\N	2025-12-14 22:17:43.36063
1315	27	265	132	\N	Присутній	\N	2025-12-14 22:17:43.36063
1316	27	266	132	\N	Н	\N	2025-12-14 22:17:43.36063
1317	27	267	132	\N	Присутній	\N	2025-12-14 22:17:43.36063
1318	27	268	132	\N	Присутній	\N	2025-12-14 22:17:43.36063
1319	27	269	132	11	Присутній	\N	2025-12-14 22:17:43.36063
1320	27	270	132	\N	Присутній	\N	2025-12-14 22:17:43.36063
1321	27	261	133	\N	Н	\N	2025-12-14 22:17:43.36063
1322	27	262	133	\N	Присутній	\N	2025-12-14 22:17:43.36063
1323	27	263	133	\N	Присутній	\N	2025-12-14 22:17:43.36063
1324	27	264	133	\N	Присутній	\N	2025-12-14 22:17:43.36063
1325	27	265	133	10	Присутній	\N	2025-12-14 22:17:43.36063
1326	27	266	133	\N	Присутній	\N	2025-12-14 22:17:43.36063
1327	27	267	133	\N	Н	\N	2025-12-14 22:17:43.36063
1328	27	268	133	4	Присутній	\N	2025-12-14 22:17:43.36063
1329	27	269	133	\N	Присутній	\N	2025-12-14 22:17:43.36063
1330	27	270	133	\N	Н	\N	2025-12-14 22:17:43.36063
1331	27	261	134	\N	Н	\N	2025-12-14 22:17:43.36063
1332	27	262	134	\N	Присутній	\N	2025-12-14 22:17:43.36063
1333	27	263	134	\N	Присутній	\N	2025-12-14 22:17:43.36063
1334	27	264	134	\N	Присутній	\N	2025-12-14 22:17:43.36063
1335	27	265	134	\N	Присутній	\N	2025-12-14 22:17:43.36063
1336	27	266	134	\N	Н	\N	2025-12-14 22:17:43.36063
1337	27	267	134	\N	Присутній	\N	2025-12-14 22:17:43.36063
1338	27	268	134	\N	Присутній	\N	2025-12-14 22:17:43.36063
1339	27	269	134	\N	Присутній	\N	2025-12-14 22:17:43.36063
1340	27	270	134	\N	Н	\N	2025-12-14 22:17:43.36063
1341	27	261	135	\N	Присутній	\N	2025-12-14 22:17:43.36063
1342	27	262	135	\N	Н	\N	2025-12-14 22:17:43.36063
1343	27	263	135	12	Присутній	\N	2025-12-14 22:17:43.36063
1344	27	264	135	9	Присутній	\N	2025-12-14 22:17:43.36063
1345	27	265	135	\N	Н	\N	2025-12-14 22:17:43.36063
1346	27	266	135	\N	Присутній	\N	2025-12-14 22:17:43.36063
1347	27	267	135	\N	Н	\N	2025-12-14 22:17:43.36063
1348	27	268	135	\N	Н	\N	2025-12-14 22:17:43.36063
1349	27	269	135	\N	Н	\N	2025-12-14 22:17:43.36063
1350	27	270	135	\N	Присутній	\N	2025-12-14 22:17:43.36063
1351	28	271	136	\N	Н	\N	2025-12-14 22:17:43.36063
1352	28	272	136	\N	Присутній	\N	2025-12-14 22:17:43.36063
1353	28	273	136	\N	Присутній	\N	2025-12-14 22:17:43.36063
1354	28	274	136	2	Присутній	\N	2025-12-14 22:17:43.36063
1355	28	275	136	\N	Присутній	\N	2025-12-14 22:17:43.36063
1356	28	276	136	\N	Присутній	\N	2025-12-14 22:17:43.36063
1357	28	277	136	\N	Н	\N	2025-12-14 22:17:43.36063
1358	28	278	136	11	Присутній	\N	2025-12-14 22:17:43.36063
1359	28	279	136	\N	Присутній	\N	2025-12-14 22:17:43.36063
1360	28	280	136	\N	Присутній	\N	2025-12-14 22:17:43.36063
1361	28	271	137	\N	Присутній	\N	2025-12-14 22:17:43.36063
1362	28	272	137	\N	Присутній	\N	2025-12-14 22:17:43.36063
1363	28	273	137	\N	Присутній	\N	2025-12-14 22:17:43.36063
1364	28	274	137	\N	Н	\N	2025-12-14 22:17:43.36063
1365	28	275	137	\N	Н	\N	2025-12-14 22:17:43.36063
1366	28	276	137	12	Присутній	\N	2025-12-14 22:17:43.36063
1367	28	277	137	\N	Присутній	\N	2025-12-14 22:17:43.36063
1368	28	278	137	\N	Присутній	\N	2025-12-14 22:17:43.36063
1369	28	279	137	\N	Присутній	\N	2025-12-14 22:17:43.36063
1370	28	280	137	\N	Присутній	\N	2025-12-14 22:17:43.36063
1371	28	271	138	4	Присутній	\N	2025-12-14 22:17:43.36063
1372	28	272	138	\N	Присутній	\N	2025-12-14 22:17:43.36063
1373	28	273	138	\N	Н	\N	2025-12-14 22:17:43.36063
1374	28	274	138	\N	Присутній	\N	2025-12-14 22:17:43.36063
1375	28	275	138	\N	Н	\N	2025-12-14 22:17:43.36063
1376	28	276	138	\N	Присутній	\N	2025-12-14 22:17:43.36063
1377	28	277	138	\N	Присутній	\N	2025-12-14 22:17:43.36063
1378	28	278	138	\N	Присутній	\N	2025-12-14 22:17:43.36063
1379	28	279	138	2	Присутній	\N	2025-12-14 22:17:43.36063
1380	28	280	138	7	Присутній	\N	2025-12-14 22:17:43.36063
1381	28	271	139	\N	Присутній	\N	2025-12-14 22:17:43.36063
1382	28	272	139	\N	Присутній	\N	2025-12-14 22:17:43.36063
1383	28	273	139	\N	Присутній	\N	2025-12-14 22:17:43.36063
1384	28	274	139	\N	Присутній	\N	2025-12-14 22:17:43.36063
1385	28	275	139	\N	Присутній	\N	2025-12-14 22:17:43.36063
1386	28	276	139	6	Присутній	\N	2025-12-14 22:17:43.36063
1387	28	277	139	\N	Присутній	\N	2025-12-14 22:17:43.36063
1388	28	278	139	\N	Н	\N	2025-12-14 22:17:43.36063
1389	28	279	139	\N	Присутній	\N	2025-12-14 22:17:43.36063
1390	28	280	139	\N	Н	\N	2025-12-14 22:17:43.36063
1391	28	271	140	\N	Присутній	\N	2025-12-14 22:17:43.36063
1392	28	272	140	\N	Присутній	\N	2025-12-14 22:17:43.36063
1393	28	273	140	\N	Присутній	\N	2025-12-14 22:17:43.36063
1394	28	274	140	3	Присутній	\N	2025-12-14 22:17:43.36063
1395	28	275	140	\N	Н	\N	2025-12-14 22:17:43.36063
1396	28	276	140	\N	Присутній	\N	2025-12-14 22:17:43.36063
1397	28	277	140	2	Присутній	\N	2025-12-14 22:17:43.36063
1398	28	278	140	\N	Присутній	\N	2025-12-14 22:17:43.36063
1399	28	279	140	\N	Н	\N	2025-12-14 22:17:43.36063
1400	28	280	140	12	Присутній	\N	2025-12-14 22:17:43.36063
1401	13	41	51	\N	Н		2025-12-14 22:17:43.36063
1402	13	42	52	\N	Н		2025-12-14 22:17:43.36063
1403	13	43	53	3	Присутній	poor performance	2025-12-14 22:17:43.36063
1404	13	44	54	\N	Н		2025-12-14 22:17:43.36063
1405	14	45	55	\N	Н		2025-12-14 22:17:43.36063
1406	14	46	56	2	Присутній	low grade	2025-12-14 22:17:43.36063
1407	14	47	57	\N	Н		2025-12-14 22:17:43.36063
1408	14	48	58	\N	Н		2025-12-14 22:17:43.36063
1409	15	49	59	\N	Н		2025-12-14 22:17:43.36063
1410	15	50	60	\N	Н		2025-12-14 22:17:43.36063
1411	15	51	61	3	Присутній	failed	2025-12-14 22:17:43.36063
1412	15	52	62	\N	Н		2025-12-14 22:17:43.36063
1413	16	53	63	\N	Н		2025-12-14 22:17:43.36063
1414	16	54	64	\N	Н		2025-12-14 22:17:43.36063
1415	16	55	65	\N	Н		2025-12-14 22:17:43.36063
1416	16	56	66	1	Присутній	very low mark	2025-12-14 22:17:43.36063
1417	17	57	67	\N	Н		2025-12-14 22:17:43.36063
1418	17	58	68	\N	Н		2025-12-14 22:17:43.36063
1419	17	59	69	\N	Н		2025-12-14 22:17:43.36063
1420	17	60	70	\N	Н		2025-12-14 22:17:43.36063
1421	18	61	71	\N	Н		2025-12-14 22:17:43.36063
1422	18	62	72	\N	Н		2025-12-14 22:17:43.36063
1423	18	63	73	2	Присутній	poor	2025-12-14 22:17:43.36063
1424	18	64	74	\N	Н		2025-12-14 22:17:43.36063
1425	19	65	75	\N	Н		2025-12-14 22:17:43.36063
1426	19	66	76	\N	Н		2025-12-14 22:17:43.36063
1427	19	67	77	\N	Н		2025-12-14 22:17:43.36063
1428	19	68	78	3	Присутній	failed test	2025-12-14 22:17:43.36063
1429	20	69	79	\N	Н		2025-12-14 22:17:43.36063
1430	20	70	80	\N	Н		2025-12-14 22:17:43.36063
1431	20	71	81	\N	Н		2025-12-14 22:17:43.36063
1432	20	72	82	\N	Н		2025-12-14 22:17:43.36063
1433	21	73	83	\N	Н		2025-12-14 22:17:43.36063
1434	21	74	84	2	Присутній	low mark	2025-12-14 22:17:43.36063
1435	21	75	85	\N	Н		2025-12-14 22:17:43.36063
1436	21	76	86	\N	Н		2025-12-14 22:17:43.36063
1437	22	77	87	\N	Н		2025-12-14 22:17:43.36063
1438	22	78	88	\N	Н		2025-12-14 22:17:43.36063
1439	22	79	89	1	Присутній	very low	2025-12-14 22:17:43.36063
1440	22	80	90	\N	Н		2025-12-14 22:17:43.36063
1441	23	81	91	\N	Н		2025-12-14 22:17:43.36063
1442	23	82	92	\N	Н		2025-12-14 22:17:43.36063
1443	23	83	93	\N	Н		2025-12-14 22:17:43.36063
1444	23	84	94	2	Присутній	poor	2025-12-14 22:17:43.36063
1445	24	85	95	\N	Н		2025-12-14 22:17:43.36063
1446	24	86	96	\N	Н		2025-12-14 22:17:43.36063
1447	24	87	97	\N	Н		2025-12-14 22:17:43.36063
1448	24	88	98	\N	Н		2025-12-14 22:17:43.36063
1449	25	89	99	\N	Н		2025-12-14 22:17:43.36063
1450	25	90	100	3	Присутній	failed	2025-12-14 22:17:43.36063
1451	25	91	101	\N	Н		2025-12-14 22:17:43.36063
1452	25	92	102	\N	Н		2025-12-14 22:17:43.36063
1453	26	93	103	\N	Н		2025-12-14 22:17:43.36063
1454	26	94	104	\N	Н		2025-12-14 22:17:43.36063
1455	26	95	105	2	Присутній	low	2025-12-14 22:17:43.36063
1456	26	96	106	\N	Н		2025-12-14 22:17:43.36063
1457	27	97	107	\N	Н		2025-12-14 22:17:43.36063
1458	27	98	108	\N	Н		2025-12-14 22:17:43.36063
1459	27	99	109	\N	Н		2025-12-14 22:17:43.36063
1460	27	100	110	\N	Н		2025-12-14 22:17:43.36063
1461	28	101	111	\N	Н		2025-12-14 22:17:43.36063
1462	28	102	112	\N	Н		2025-12-14 22:17:43.36063
1463	28	103	113	3	Присутній	failed	2025-12-14 22:17:43.36063
1464	28	104	114	\N	Н		2025-12-14 22:17:43.36063
1465	28	105	115	\N	Н		2025-12-14 22:17:43.36063
1466	28	106	116	\N	Н		2025-12-14 22:17:43.36063
1467	28	107	117	\N	Н		2025-12-14 22:17:43.36063
1468	28	108	118	2	Присутній	low grade	2025-12-14 22:17:43.36063
1469	28	109	119	\N	Н		2025-12-14 22:17:43.36063
1470	28	110	120	\N	Н		2025-12-14 22:17:43.36063
1471	1	1	1	8	Присутній	good	2025-12-14 22:17:43.36063
1472	1	1	2	3	Присутній	poor performance	2025-12-14 22:17:43.36063
1473	1	1	3	\N	Н		2025-12-14 22:17:43.36063
1474	1	1	4	12	Присутній	excellent	2025-12-14 22:17:43.36063
1475	1	1	5	5	Присутній	average	2025-12-14 22:17:43.36063
1476	1	1	6	\N	Н		2025-12-14 22:17:43.36063
1477	1	1	7	2	Присутній	very low	2025-12-14 22:17:43.36063
1478	1	1	8	9	Присутній	good	2025-12-14 22:17:43.36063
1479	1	1	9	\N	Н		2025-12-14 22:17:43.36063
1480	1	1	10	7	Присутній	decent	2025-12-14 22:17:43.36063
1481	1	5	10	12	П	Добре працював	2025-12-14 22:17:43.36063
1482	1	1	163	10	П	Активна робота	2025-12-18 17:18:43.268208
1483	1	1	164	9	П	\N	2025-12-18 17:18:43.268208
1484	1	1	165	11	П	Чітка відповідь	2025-12-18 17:18:43.268208
1485	1	1	166	8	П	\N	2025-12-18 17:18:43.268208
1486	1	1	167	\N	Н	Відсутній	2025-12-18 17:18:43.268208
1487	1	1	168	7	П	Слабка підготовка	2025-12-18 17:18:43.268208
1488	1	1	169	12	П	Відмінно	2025-12-18 17:18:43.268208
1489	1	1	170	9	П	\N	2025-12-18 17:18:43.268208
1490	1	1	171	\N	Н	Не зʼявився	2025-12-18 17:18:43.268208
1494	1	1	5	12	П	12	2025-12-21 23:40:11.190487
1496	30	77	190	12	П	фів	2025-12-23 02:57:44.351142
1497	1	1	192	12	П	Гарна робота!	2025-12-23 11:45:42.259094
1501	2	14	196	12	П	HEHEHEHE	2026-01-11 01:53:26.014971
1502	1	1	196	12	П	АФОТШ	2026-01-11 01:56:47.789403
1503	1	1	198	2	П	NO SHITTY	2026-01-11 01:57:26.174678
1504	1	1	203	1	Н	NE NI SI	2026-01-11 01:59:57.531988
1506	1	10	185	\N	Н	BAD SHIT!	2026-01-11 18:59:58.648905
1507	1	3	185	1	Н	SHIT!!!!!	2026-01-11 19:05:23.556873
1508	14	134	185	1	Н	1	2026-01-11 19:14:55.780181
1513	15	148	185	1	Н	\N	2026-01-11 21:23:44.18991
1	1	1	1	\N	Присутній	TEST	2025-12-14 22:17:43.36063
1514	15	148	210	1	Н	I SAID SHIT2	2026-01-11 21:25:24.356719
1500	1	10	196	12	П	YEAHHH	2026-01-11 01:53:04.490861
\.


--
-- Data for Name: studentparent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.studentparent (student_id_ref, parent_id_ref) FROM stdin;
1	1
1	2
2	3
2	4
3	5
4	6
4	7
5	8
5	9
6	10
7	11
7	12
8	13
8	14
9	15
10	16
10	17
11	18
11	19
12	20
13	21
13	22
14	23
14	24
15	25
16	26
16	27
17	28
17	29
18	30
19	31
19	32
20	33
20	34
21	35
22	36
22	37
23	38
23	39
24	40
25	41
25	42
26	43
26	44
27	45
28	46
28	47
29	48
29	49
30	50
31	51
31	52
32	53
32	54
33	55
34	56
34	57
35	58
35	59
36	60
37	61
37	62
38	63
38	64
39	65
40	66
40	67
41	68
41	69
42	70
43	71
43	72
44	73
44	74
45	75
46	76
46	77
47	78
47	79
48	80
49	81
49	82
50	83
50	84
51	85
52	86
52	87
53	88
53	89
54	90
55	91
55	92
56	93
56	94
57	95
58	96
58	97
59	98
59	99
60	100
61	101
61	102
62	103
62	104
63	105
64	106
64	107
65	108
65	109
66	110
67	111
67	112
68	113
68	114
69	115
70	116
70	117
71	118
71	119
72	120
73	121
73	122
74	123
74	124
75	125
76	126
76	127
77	128
77	129
78	130
79	131
79	132
80	133
80	134
81	135
82	136
82	137
83	138
83	139
84	140
85	141
85	142
86	143
86	144
87	145
88	146
88	147
89	148
89	149
90	150
91	151
91	152
92	153
92	154
93	155
94	156
94	157
95	158
95	159
96	160
97	161
97	162
98	163
98	164
99	165
100	166
100	167
101	168
101	169
102	170
103	171
103	172
104	173
104	174
105	175
106	176
106	177
107	178
107	179
108	180
109	181
109	182
110	183
110	184
111	185
112	186
112	187
113	188
113	189
114	190
115	191
115	192
116	193
116	194
117	195
118	196
118	197
119	198
119	199
120	200
121	201
121	202
122	203
122	204
123	205
124	206
124	207
125	208
125	209
126	210
127	211
127	212
128	213
128	214
129	215
130	216
130	217
131	218
131	219
132	220
133	221
133	222
134	223
134	224
135	225
136	226
136	227
137	228
137	229
138	230
139	231
139	232
140	233
140	234
141	235
142	236
142	237
143	238
143	239
144	240
145	241
145	242
146	243
146	244
147	245
148	246
148	247
149	248
149	249
150	250
151	251
151	252
152	253
152	254
153	255
154	256
154	257
155	258
155	259
156	260
157	261
157	262
158	263
158	264
159	265
160	266
160	267
161	268
161	269
162	270
163	271
163	272
164	273
164	274
165	275
166	276
166	277
167	278
167	279
168	280
169	281
169	282
170	283
170	284
171	285
172	286
172	287
173	288
173	289
174	290
175	291
175	292
176	293
176	294
177	295
178	296
178	297
179	298
179	299
180	300
181	301
181	302
182	303
182	304
183	305
184	306
184	307
185	308
185	309
186	310
187	311
187	312
188	313
188	314
189	315
190	316
190	317
191	318
191	319
192	320
193	321
193	322
194	323
194	324
195	325
196	326
196	327
197	328
197	329
198	330
199	331
199	332
200	333
200	334
201	335
202	336
202	337
203	338
203	339
204	340
205	341
205	342
206	343
206	344
207	345
208	346
208	347
209	348
209	349
210	350
211	351
211	352
212	353
212	354
213	355
214	356
214	357
215	358
215	359
216	360
217	361
217	362
218	363
218	364
219	365
220	366
220	367
221	368
221	369
222	370
223	371
223	372
224	373
224	374
225	375
226	376
226	377
227	378
227	379
228	380
229	381
229	382
230	383
230	384
231	385
232	386
232	387
233	388
233	389
234	390
235	391
235	392
236	393
236	394
237	395
238	396
238	397
239	398
239	399
240	400
241	401
241	402
242	403
242	404
243	405
244	406
244	407
245	408
245	409
246	410
247	411
247	412
248	413
248	414
249	415
250	416
250	417
251	418
251	419
252	420
253	421
253	422
254	423
254	424
255	425
256	426
256	427
257	428
257	429
258	430
259	431
259	432
260	433
260	434
261	435
262	436
262	437
263	438
263	439
264	440
265	441
265	442
266	443
266	444
267	445
268	446
268	447
269	448
269	449
270	450
271	451
271	452
272	453
272	454
273	455
274	456
274	457
275	458
275	459
276	460
277	461
277	462
278	463
278	464
279	465
280	466
280	467
1	11
282	469
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.students (student_id, student_name, student_surname, student_patronym, student_phone, student_user_id, student_class) FROM stdin;
12	Люба	Кравченко	Віталийівна	068-001-1011	483	1-Б
13	Олег	Петренко	Васильович	050-001-1012	484	1-Б
14	Тамара	Дмитренко	Левівна	063-001-1013	485	1-Б
10	Надія	Білик	Тарасівна	098-001-1009	481	1-А
19	Геннадій	Ткач	Степанович	097-001-1018	490	1-Б
22	Єва	Коцюбинська	Вадимівна	068-001-1021	493	1-В
20	Аліна	Шевчук	Арсенівна	098-001-1019	491	1-Б
21	Максим	Грищенко	Данилоович	067-001-1020	492	1-В
23	Степан	Черненко	Ростиславович	050-001-1022	494	1-В
25	Данило	Бондаренко	Богданович	095-001-1024	496	1-В
24	Софія	Поліщук	Костянтинівна	063-001-1023	495	1-В
26	Анна	Соловйова	Федірівна	066-001-1025	497	1-В
27	Ростислав	Мацюк	Єгорович	039-001-1026	498	1-В
28	Меланія	Іваненко	Олександрівна	096-001-1027	499	1-В
29	Богдан	Левченко	Артемович	097-001-1028	500	1-В
30	Поліна	Демченко	Андрійівна	098-001-1029	501	1-В
31	Єгор	Коваль	Володимирович	067-001-1030	502	2-А
32	Яна	Романенко	Дмитроівна	068-001-1031	503	2-А
33	Артем	Ковальський	Сергійович	050-001-1032	504	2-А
35	Володимир	Павленко	Миколаович	095-001-1034	506	2-А
37	Сергій	Клименко	Павлоович	039-001-1036	508	2-А
36	Олена	Пономаренко	Ігорівна	066-001-1035	507	2-А
34	Наталія	Бойченко	Юрійівна	063-001-1033	505	2-А
38	Ганна	Кириченко	Романівна	096-001-1037	509	2-А
40	Оксана	Зайцев	Петроівна	098-001-1039	511	2-А
39	Микола	Мартинюк	Євгенович	097-001-1038	510	2-А
41	Павло	Мартиненко	Олегович	067-001-1040	512	2-Б
42	Надія	Остапенко	Тарасівна	068-001-1041	513	2-Б
43	Євген	Кузьменко	Віталійович	050-001-1042	514	2-Б
44	Люба	Пилипчук	Віталийівна	063-001-1043	515	2-Б
45	Олег	Симоненко	Васильович	095-001-1044	516	2-Б
46	Тамара	Проценко	Левівна	066-001-1045	517	2-Б
47	Віталій	Олексієнко	Геннадійович	039-001-1046	518	2-Б
49	Василь	Нечипоренко	Максимович	097-001-1048	520	2-Б
48	Валентина	Корсун	Ярославівна	096-001-1047	519	2-Б
50	Орися	Мірошниченко	Борисівна	098-001-1049	521	2-Б
51	Геннадій	Шевченко	Степанович	067-001-1050	522	2-В
52	Аліна	Ковальчук	Арсенівна	068-001-1051	523	2-В
54	Єва	Гончар	Вадимівна	063-001-1053	525	2-В
55	Степан	Мельник	Ростиславович	095-001-1054	526	2-В
57	Данило	Козак	Богданович	039-001-1056	528	2-В
56	Софія	Ткаченко	Костянтинівна	066-001-1055	527	2-В
59	Ростислав	Федоренко	Єгорович	097-001-1058	530	2-В
60	Меланія	Білик	Олександрівна	098-001-1059	531	2-В
61	Богдан	Сидоренко	Артемович	067-001-1060	532	3-А
62	Поліна	Кравченко	Андрійівна	068-001-1061	533	3-А
63	Єгор	Петренко	Володимирович	050-001-1062	534	3-А
64	Яна	Дмитренко	Дмитроівна	063-001-1063	535	3-А
67	Володимир	Савченко	Миколаович	039-001-1066	538	3-А
66	Наталія	Литвин	Юрійівна	066-001-1065	537	3-А
65	Артем	Микитенко	Сергійович	095-001-1064	536	3-А
68	Олена	Кравчук	Ігорівна	096-001-1067	539	3-А
69	Сергій	Ткач	Павлоович	097-001-1068	540	3-А
70	Ганна	Шевчук	Романівна	098-001-1069	541	3-А
71	Микола	Грищенко	Євгенович	067-001-1070	542	3-Б
72	Оксана	Коцюбинська	Петроівна	068-001-1071	543	3-Б
73	Павло	Черненко	Олегович	050-001-1072	544	3-Б
75	Євген	Бондаренко	Віталійович	095-001-1074	546	3-Б
76	Люба	Соловйова	Віталийівна	066-001-1075	547	3-Б
77	Олег	Мацюк	Васильович	039-001-1076	548	3-Б
78	Тамара	Іваненко	Левівна	096-001-1077	549	3-Б
79	Віталій	Левченко	Геннадійович	097-001-1078	550	3-Б
85	Максим	Павленко	Данилоович	095-001-1084	556	3-В
86	Єва	Пономаренко	Вадимівна	066-001-1085	557	3-В
87	Степан	Клименко	Ростиславович	039-001-1086	558	3-В
88	Софія	Кириченко	Костянтинівна	096-001-1087	559	3-В
94	Поліна	Пилипчук	Андрійівна	063-001-1093	565	4-А
95	Єгор	Симоненко	Володимирович	095-001-1094	566	4-А
96	Яна	Проценко	Дмитроівна	066-001-1095	567	4-А
97	Артем	Олексієнко	Сергійович	039-001-1096	568	4-А
98	Наталія	Корсун	Юрійівна	096-001-1097	569	4-А
99	Володимир	Нечипоренко	Миколаович	097-001-1098	570	4-А
100	Олена	Мірошниченко	Ігорівна	098-001-1099	571	4-А
101	Сергій	Шевченко	Павлоович	067-001-1100	572	4-Б
102	Ганна	Ковальчук	Романівна	068-001-1101	573	4-Б
104	Оксана	Гончар	Петроівна	063-001-1103	575	4-Б
105	Павло	Мельник	Олегович	095-001-1104	576	4-Б
106	Надія	Ткаченко	Тарасівна	066-001-1105	577	4-Б
107	Євген	Козак	Віталійович	039-001-1106	578	4-Б
108	Люба	Руденко	Віталийівна	096-001-1107	579	4-Б
109	Олег	Федоренко	Васильович	097-001-1108	580	4-Б
113	Василь	Петренко	Максимович	050-001-1112	584	4-В
114	Орися	Дмитренко	Борисівна	063-001-1113	585	4-В
115	Геннадій	Микитенко	Степанович	095-001-1114	586	4-В
116	Аліна	Литвин	Арсенівна	066-001-1115	587	4-В
117	Максим	Савченко	Данилоович	039-001-1116	588	4-В
118	Єва	Кравчук	Вадимівна	096-001-1117	589	4-В
119	Степан	Ткач	Ростиславович	097-001-1118	590	4-В
120	Софія	Шевчук	Костянтинівна	098-001-1119	591	4-В
121	Данило	Грищенко	Богданович	067-001-1120	592	5-А
122	Анна	Коцюбинська	Федірівна	068-001-1121	593	5-А
123	Ростислав	Черненко	Єгорович	050-001-1122	594	5-А
124	Меланія	Поліщук	Олександрівна	063-001-1123	595	5-А
125	Богдан	Бондаренко	Артемович	095-001-1124	596	5-А
126	Поліна	Соловйова	Андрійівна	066-001-1125	597	5-А
127	Єгор	Мацюк	Володимирович	039-001-1126	598	5-А
128	Яна	Іваненко	Дмитроівна	096-001-1127	599	5-А
129	Артем	Левченко	Сергійович	097-001-1128	600	5-А
130	Наталія	Демченко	Юрійівна	098-001-1129	601	5-А
131	Володимир	Коваль	Миколаович	067-001-1130	602	5-Б
132	Олена	Романенко	Ігорівна	068-001-1131	603	5-Б
133	Сергій	Ковальський	Павлоович	050-001-1132	604	5-Б
134	Ганна	Бойченко	Романівна	063-001-1133	605	5-Б
135	Микола	Павленко	Євгенович	095-001-1134	606	5-Б
136	Оксана	Пономаренко	Петроівна	066-001-1135	607	5-Б
138	Надія	Кириченко	Тарасівна	096-001-1137	609	5-Б
139	Євген	Мартинюк	Віталійович	097-001-1138	610	5-Б
137	Павло	Клименко	Олегович	039-001-1136	608	5-Б
140	Люба	Зайцев	Віталийівна	098-001-1139	611	5-Б
141	Олег	Мартиненко	Васильович	067-001-1140	612	6-А
142	Тамара	Остапенко	Левівна	068-001-1141	613	6-А
143	Віталій	Кузьменко	Геннадійович	050-001-1142	614	6-А
144	Валентина	Пилипчук	Ярославівна	063-001-1143	615	6-А
145	Василь	Симоненко	Максимович	095-001-1144	616	6-А
146	Орися	Проценко	Борисівна	066-001-1145	617	6-А
147	Геннадій	Олексієнко	Степанович	039-001-1146	618	6-А
148	Аліна	Корсун	Арсенівна	096-001-1147	619	6-А
149	Максим	Нечипоренко	Данилоович	097-001-1148	620	6-А
150	Єва	Мірошниченко	Вадимівна	098-001-1149	621	6-А
151	Степан	Шевченко	Ростиславович	067-001-1150	622	6-Б
152	Софія	Ковальчук	Костянтинівна	068-001-1151	623	6-Б
154	Анна	Гончар	Федірівна	063-001-1153	625	6-Б
155	Ростислав	Мельник	Єгорович	095-001-1154	626	6-Б
156	Меланія	Ткаченко	Олександрівна	066-001-1155	627	6-Б
165	Сергій	Микитенко	Павлоович	095-001-1164	636	7-А
166	Ганна	Литвин	Романівна	066-001-1165	637	7-А
167	Микола	Савченко	Євгенович	039-001-1166	638	7-А
168	Оксана	Кравчук	Петроівна	096-001-1167	639	7-А
169	Павло	Ткач	Олегович	097-001-1168	640	7-А
170	Надія	Шевчук	Тарасівна	098-001-1169	641	7-А
171	Євген	Грищенко	Віталійович	067-001-1170	642	7-Б
174	Тамара	Поліщук	Левівна	063-001-1173	645	7-Б
175	Віталій	Бондаренко	Геннадійович	095-001-1174	646	7-Б
176	Валентина	Соловйова	Ярославівна	066-001-1175	647	7-Б
177	Василь	Мацюк	Максимович	039-001-1176	648	7-Б
178	Орися	Іваненко	Борисівна	096-001-1177	649	7-Б
179	Геннадій	Левченко	Степанович	097-001-1178	650	7-Б
180	Аліна	Демченко	Арсенівна	098-001-1179	651	7-Б
181	Максим	Коваль	Данилоович	067-001-1180	652	8-А
183	Степан	Ковальський	Ростиславович	050-001-1182	654	8-А
185	Данило	Павленко	Богданович	095-001-1184	656	8-А
186	Анна	Пономаренко	Федірівна	066-001-1185	657	8-А
187	Ростислав	Клименко	Єгорович	039-001-1186	658	8-А
188	Меланія	Кириченко	Олександрівна	096-001-1187	659	8-А
189	Богдан	Мартинюк	Артемович	097-001-1188	660	8-А
190	Поліна	Зайцев	Андрійівна	098-001-1189	661	8-А
192	Яна	Остапенко	Дмитроівна	068-001-1191	663	8-Б
193	Артем	Кузьменко	Сергійович	050-001-1192	664	8-Б
194	Наталія	Пилипчук	Юрійівна	063-001-1193	665	8-Б
196	Олена	Проценко	Ігорівна	066-001-1195	667	8-Б
195	Володимир	Симоненко	Миколаович	095-001-1194	666	8-Б
197	Сергій	Олексієнко	Павлоович	039-001-1196	668	8-Б
198	Ганна	Корсун	Романівна	096-001-1197	669	8-Б
199	Микола	Нечипоренко	Євгенович	097-001-1198	670	8-Б
200	Оксана	Мірошниченко	Петроівна	098-001-1199	671	8-Б
201	Павло	Шевченко	Олегович	067-001-1200	672	9-А
202	Надія	Ковальчук	Тарасівна	068-001-1201	673	9-А
203	Євген	Бойко	Віталійович	050-001-1202	674	9-А
205	Олег	Мельник	Васильович	095-001-1204	676	9-А
206	Тамара	Ткаченко	Левівна	066-001-1205	677	9-А
207	Віталій	Козак	Геннадійович	039-001-1206	678	9-А
208	Валентина	Руденко	Ярославівна	096-001-1207	679	9-А
209	Василь	Федоренко	Максимович	097-001-1208	680	9-А
210	Орися	Білик	Борисівна	098-001-1209	681	9-А
211	Геннадій	Сидоренко	Степанович	067-001-1210	682	9-Б
212	Аліна	Кравченко	Арсенівна	068-001-1211	683	9-Б
214	Єва	Дмитренко	Вадимівна	063-001-1213	685	9-Б
215	Степан	Микитенко	Ростиславович	095-001-1214	686	9-Б
216	Софія	Литвин	Костянтинівна	066-001-1215	687	9-Б
217	Данило	Савченко	Богданович	039-001-1216	688	9-Б
218	Анна	Кравчук	Федірівна	096-001-1217	689	9-Б
220	Меланія	Шевчук	Олександрівна	098-001-1219	691	9-Б
221	Богдан	Грищенко	Артемович	067-001-1220	692	10-А
222	Поліна	Коцюбинська	Андрійівна	068-001-1221	693	10-А
223	Єгор	Черненко	Володимирович	050-001-1222	694	10-А
224	Яна	Поліщук	Дмитроівна	063-001-1223	695	10-А
225	Артем	Бондаренко	Сергійович	095-001-1224	696	10-А
226	Наталія	Соловйова	Юрійівна	066-001-1225	697	10-А
227	Володимир	Мацюк	Миколаович	039-001-1226	698	10-А
228	Олена	Іваненко	Ігорівна	096-001-1227	699	10-А
229	Сергій	Левченко	Павлоович	097-001-1228	700	10-А
230	Ганна	Демченко	Романівна	098-001-1229	701	10-А
231	Микола	Коваль	Євгенович	067-001-1230	702	10-Б
232	Оксана	Романенко	Петроівна	068-001-1231	703	10-Б
233	Павло	Ковальський	Олегович	050-001-1232	704	10-Б
280	Софія	Демченко	Костянтинівна	098-001-1279	\N	12-Б
11	Євген	Сидоренко	Віталійович	067-001-1010	482	1-Б
3	Володимир	Бойко	Миколаович	050-001-1002	474	1-А
2	Наталія	Ковальчук	Юрійівна	068-001-1001	473	1-А
15	Віталій	Микитенко	Геннадійович	095-001-1014	486	1-Б
6	Ганна	Ткаченко	Романівна	066-001-1005	477	1-А
16	Валентина	Литвин	Ярославівна	066-001-1015	487	1-Б
5	Сергій	Мельник	Павлоович	095-001-1004	476	1-А
7	Микола	Козак	Євгенович	039-001-1006	478	1-А
9	Павло	Федоренко	Олегович	097-001-1008	480	1-А
17	Василь	Савченко	Максимович	039-001-1016	488	1-Б
8	Оксана	Руденко	Петроівна	096-001-1007	479	1-А
18	Орися	Кравчук	Борисівна	096-001-1017	489	1-Б
53	Максим	Бойко	Данилоович	050-001-1052	524	2-В
58	Анна	Руденко	Федірівна	096-001-1057	529	2-В
74	Надія	Поліщук	Тарасівна	063-001-1073	545	3-Б
82	Орися	Романенко	Борисівна	068-001-1081	553	3-В
80	Валентина	Демченко	Ярославівна	098-001-1079	551	3-Б
81	Василь	Коваль	Максимович	067-001-1080	552	3-В
83	Геннадій	Ковальський	Степанович	050-001-1082	554	3-В
84	Аліна	Бойченко	Арсенівна	063-001-1083	555	3-В
89	Данило	Мартинюк	Богданович	097-001-1088	560	3-В
90	Анна	Зайцев	Федірівна	098-001-1089	561	3-В
91	Ростислав	Мартиненко	Єгорович	067-001-1090	562	4-А
92	Меланія	Остапенко	Олександрівна	068-001-1091	563	4-А
93	Богдан	Кузьменко	Артемович	050-001-1092	564	4-А
103	Микола	Бойко	Євгенович	050-001-1102	574	4-Б
110	Тамара	Білик	Левівна	098-001-1109	581	4-Б
111	Віталій	Сидоренко	Геннадійович	067-001-1110	582	4-В
246	Єва	Проценко	Вадимівна	066-001-1245	717	11-А
245	Максим	Симоненко	Данилоович	095-001-1244	716	11-А
247	Степан	Олексієнко	Ростиславович	039-001-1246	718	11-А
248	Софія	Корсун	Костянтинівна	096-001-1247	719	11-А
1	Артем	Шевченко	Сергійович	067-001-1000	826	1-А
249	Данило	Нечипоренко	Богданович	097-001-1248	720	11-А
250	Анна	Мірошниченко	Федірівна	098-001-1249	721	11-А
251	Ростислав	Шевченко	Єгорович	067-001-1250	722	11-Б
252	Меланія	Ковальчук	Олександрівна	068-001-1251	723	11-Б
253	Богдан	Бойко	Артемович	050-001-1252	724	11-Б
255	Єгор	Мельник	Володимирович	095-001-1254	726	11-Б
256	Яна	Ткаченко	Дмитроівна	066-001-1255	727	11-Б
257	Артем	Козак	Сергійович	039-001-1256	728	11-Б
258	Наталія	Руденко	Юрійівна	096-001-1257	729	11-Б
259	Володимир	Федоренко	Миколаович	097-001-1258	730	11-Б
260	Олена	Білик	Ігорівна	098-001-1259	731	11-Б
261	Сергій	Сидоренко	Павлоович	067-001-1260	732	12-А
262	Ганна	Кравченко	Романівна	068-001-1261	733	12-А
263	Микола	Петренко	Євгенович	050-001-1262	734	12-А
264	Оксана	Дмитренко	Петроівна	063-001-1263	735	12-А
265	Павло	Микитенко	Олегович	095-001-1264	736	12-А
266	Надія	Литвин	Тарасівна	066-001-1265	737	12-А
267	Євген	Савченко	Віталійович	039-001-1266	738	12-А
268	Люба	Кравчук	Віталийівна	096-001-1267	739	12-А
269	Олег	Ткач	Васильович	097-001-1268	742	12-А
270	Тамара	Шевчук	Левівна	098-001-1269	743	12-А
271	Віталій	Грищенко	Геннадійович	067-001-1270	744	12-Б
272	Валентина	Коцюбинська	Ярославівна	068-001-1271	740	12-Б
273	Василь	Черненко	Максимович	050-001-1272	741	12-Б
275	Геннадій	Бондаренко	Степанович	095-001-1274	746	12-Б
276	Аліна	Соловйова	Арсенівна	066-001-1275	747	12-Б
277	Максим	Мацюк	Данилоович	039-001-1276	748	12-Б
278	Єва	Іваненко	Вадимівна	096-001-1277	749	12-Б
279	Степан	Левченко	Ростиславович	097-001-1278	750	12-Б
112	Валентина	Кравченко	Ярославівна	068-001-1111	583	4-В
153	Данило	Бойко	Богданович	050-001-1152	624	6-Б
161	Артем	Сидоренко	Сергійович	067-001-1160	632	7-А
236	Люба	Пономаренко	Віталийівна	066-001-1235	707	10-Б
157	Богдан	Козак	Артемович	039-001-1156	628	6-Б
244	Аліна	Пилипчук	Арсенівна	063-001-1243	715	11-А
274	Орися	Поліщук	Борисівна	063-001-1273	745	12-Б
158	Поліна	Руденко	Андрійівна	096-001-1157	629	6-Б
173	Олег	Черненко	Васильович	050-001-1172	644	7-Б
191	Єгор	Мартиненко	Володимирович	067-001-1190	662	8-Б
239	Віталій	Мартинюк	Геннадійович	097-001-1238	710	10-Б
160	Яна	Білик	Дмитроівна	098-001-1159	631	6-Б
237	Олег	Клименко	Васильович	039-001-1236	708	10-Б
159	Єгор	Федоренко	Володимирович	097-001-1158	630	6-Б
182	Єва	Романенко	Вадимівна	068-001-1181	653	8-А
234	Надія	Бойченко	Тарасівна	063-001-1233	705	10-Б
241	Василь	Мартиненко	Максимович	067-001-1240	712	11-А
163	Володимир	Петренко	Миколаович	050-001-1162	634	7-А
162	Наталія	Кравченко	Юрійівна	068-001-1161	633	7-А
164	Олена	Дмитренко	Ігорівна	063-001-1163	635	7-А
172	Люба	Коцюбинська	Віталийівна	068-001-1171	643	7-Б
184	Софія	Бойченко	Костянтинівна	063-001-1183	655	8-А
204	Люба	Гончар	Віталийівна	063-001-1203	675	9-А
213	Максим	Петренко	Данилоович	050-001-1212	684	9-Б
235	Євген	Павленко	Віталійович	095-001-1234	706	10-Б
238	Тамара	Кириченко	Левівна	096-001-1237	709	10-Б
240	Валентина	Зайцев	Ярославівна	098-001-1239	711	10-Б
242	Орися	Остапенко	Борисівна	068-001-1241	713	11-А
243	Геннадій	Кузьменко	Степанович	050-001-1242	714	11-А
254	Поліна	Гончар	Андрійівна	063-001-1253	725	11-Б
219	Ростислав	Ткач	Єгорович	097-001-1218	472	9-Б
281	Івана	Петренко	Олександрівна	067-123-4567	824	1-А
282	ТЕСТS	ТЕСТ	ТЕСТ	098-000-0000	831	12-Г
287	ТЕСТ2	ТЕСТ2	ТЕСТ2	098-098-0987	834	12-Г
289	Сергій	Курсенко	Олександрович	097-123-4525	839	12-Г
4	Олена	Гончар	Ігорівна	063-001-1003	475	1-А
290	TESTS	TESTS	\N	098-789-1234	840	12-Г
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subjects (subject_id, subject_name, subject_program, cabinet) FROM stdin;
1	Математика	\N	328
2	Українська мова	\N	217
3	Українська література	\N	148
4	Фізика	\N	195
5	Хімія	\N	105
6	Біологія	\N	144
7	Географія	\N	314
8	Історія	\N	118
9	Англійська мова	\N	230
10	Фізкультура	\N	378
11	Мистецтво	\N	317
12	Музика	\N	343
13	Інформатика	\N	118
14	Технології	\N	301
15	Історія України	\N	312
16	Алгебра	\N	128
17	Геометрія	\N	266
18	Екологія	\N	217
19	Економіка	\N	271
20	Всесвітня Історія	\N	132
22	TEST	TEST	100
\.


--
-- Data for Name: teacher; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher (teacher_id, teacher_name, teacher_surname, teacher_patronym, teacher_phone, teacher_user_id) FROM stdin;
5	Андрій	Мельник	Олексійович	063-123-4505	754
4	Наталія	Гончар	Андріївна	050-123-4504	755
8	Олена	Руденко	Анатоліївна	067-123-4508	756
10	Тетяна	Білик	Ігорівна	068-123-4510	757
11	Микола	Сидоренко	Олександрович	039-123-4511	758
12	Людмила	Кравченко	Михайлівна	050-123-4512	759
13	Юрій	Петренко	Вікторович	067-123-4513	760
14	Оксана	Дмитренко	Сергіївна	095-123-4514	761
15	Віктор	Микитенко	Анатолійович	063-123-4515	762
17	Євген	Савченко	Олександрович	067-123-4517	763
18	Світлана	Кравчук	Вікторівна	039-123-4518	764
20	Люба	Шевчук	Іванівна	068-123-4520	765
21	Олег	Грищенко	Сергійович	067-123-4521	766
24	Валентина	Поліщук	Миколаївна	050-123-4524	767
23	Ігор	Черненко	Анатолійович	095-123-4523	768
25	Анатолій	Бондаренко	Вікторович	068-123-4525	769
26	Ольга	Соловйова	Сергіївна	063-123-4526	770
27	Роман	Мацюк	Олександрович	067-123-4527	771
28	Тамара	Іваненко	Петрівна	039-123-4528	772
29	Вікторія	Левченко	Анатоліївна	050-123-4529	773
30	Єгор	Демченко	Сергійович	063-123-4530	776
2	Марія	Ковальчук	Петрівна	038-123-4502	775
6	Ірина	Ткаченко	Вікторівна	068-123-4506	777
7	Сергій	Козак	Петрович	095-123-4507	778
3	Володимир	Бойко	Сергійович	067-123-4503	779
9	Дмитро	Федоренко	Володимирович	063-123-4509	781
16	Ганна	Литвин	Петрівна	068-123-4516	780
31	Марина	Коваль	Михайлівна	068-123-4531	782
22	Надія	Коцюбинська	Петрівна	063-123-4522	783
19	Павло	Ткач	Михайлович	050-123-4519	784
32	Денис	Романенко	Олексійович	067-123-4532	785
34	ass	fist	all	096-000-0000	123
36	ass	fist	all	097-000-0000	\N
37	Івани	Петренко	Олександрович	067-123-4567	825
1	Олександр	Шевченко	Іванович	039-123-4501	827
\.


--
-- Data for Name: timetable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.timetable (timetable_id, timetable_name, timetable_class) FROM stdin;
1	Розклад для 1-А	1-А
2	Розклад для 1-Б	1-Б
3	Розклад для 1-В	1-В
4	Розклад для 2-А	2-А
5	Розклад для 2-Б	2-Б
6	Розклад для 2-В	2-В
7	Розклад для 3-А	3-А
8	Розклад для 3-Б	3-Б
9	Розклад для 3-В	3-В
10	Розклад для 4-А	4-А
11	Розклад для 4-Б	4-Б
12	Розклад для 4-В	4-В
13	Розклад для 5-А	5-А
14	Розклад для 5-Б	5-Б
15	Розклад для 6-А	6-А
16	Розклад для 6-Б	6-Б
17	Розклад для 7-А	7-А
18	Розклад для 7-Б	7-Б
19	Розклад для 8-А	8-А
20	Розклад для 8-Б	8-Б
21	Розклад для 9-А	9-А
22	Розклад для 9-Б	9-Б
23	Розклад для 10-А	10-А
24	Розклад для 10-Б	10-Б
25	Розклад для 11-А	11-А
26	Розклад для 11-Б	11-Б
27	Розклад для 12-А	12-А
28	Розклад для 12-Б	12-Б
32	TESTS	12-Г
\.


--
-- Data for Name: userrole; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.userrole (user_id, role_id) FROM stdin;
1	6
11	6
12	6
13	6
2	6
5	6
4	6
3	6
14	6
6	6
9	6
8	6
7	6
15	6
16	6
17	6
18	6
19	6
20	6
21	6
22	6
23	6
24	6
10	6
25	6
26	6
27	6
28	6
29	6
30	6
31	6
32	6
33	6
35	6
34	6
36	6
37	6
38	6
39	6
40	6
41	6
42	6
43	6
44	6
45	6
46	6
47	6
48	6
49	6
50	6
51	6
52	6
53	6
54	6
56	6
55	6
58	6
57	6
60	6
59	6
61	6
62	6
63	6
64	6
65	6
66	6
67	6
68	6
69	6
70	6
71	6
72	6
73	6
74	6
75	6
77	6
78	6
79	6
76	6
80	6
81	6
82	6
83	6
84	6
85	6
86	6
87	6
88	6
89	6
91	6
90	6
92	6
93	6
94	6
95	6
96	6
97	6
98	6
99	6
100	6
101	6
102	6
103	6
104	6
105	6
106	6
107	6
108	6
109	6
110	6
111	6
112	6
113	6
114	6
115	6
116	6
117	6
118	6
119	6
120	6
122	6
121	6
123	6
124	6
125	6
126	6
127	6
128	6
129	6
130	6
131	6
132	6
133	6
134	6
135	6
136	6
137	6
138	6
139	6
140	6
141	6
142	6
143	6
144	6
145	6
146	6
147	6
148	6
149	6
150	6
151	6
152	6
153	6
154	6
155	6
156	6
157	6
158	6
159	6
160	6
161	6
162	6
163	6
164	6
165	6
166	6
167	6
168	6
169	6
170	6
171	6
172	6
173	6
174	6
175	6
176	6
177	6
178	6
179	6
180	6
181	6
182	6
183	6
184	6
185	6
186	6
187	6
188	6
189	6
190	6
191	6
192	6
193	6
194	6
195	6
196	6
197	6
198	6
199	6
200	6
201	6
202	6
203	6
204	6
205	6
206	6
207	6
208	6
209	6
210	6
211	6
212	6
213	6
214	6
215	6
216	6
217	6
218	6
219	6
220	6
221	6
222	6
223	6
224	6
225	6
226	6
227	6
238	6
246	6
257	6
268	6
280	6
285	6
295	6
304	6
316	6
326	6
337	6
350	6
356	6
367	6
380	6
383	6
393	6
403	6
412	6
423	6
431	6
440	6
452	6
463	6
229	6
239	6
245	6
256	6
269	6
279	6
287	6
296	6
308	6
319	6
328	6
338	6
349	6
358	6
369	6
379	6
387	6
397	6
410	6
420	6
430	6
443	6
450	6
462	6
228	6
237	6
249	6
255	6
263	6
274	6
286	6
300	6
305	6
318	6
329	6
339	6
348	6
359	6
368	6
377	6
389	6
401	6
408	6
418	6
426	6
437	6
448	6
458	6
230	6
240	6
250	6
260	6
270	6
278	6
288	6
299	6
309	6
317	6
330	6
336	6
347	6
360	6
366	6
378	6
388	6
398	6
409	6
419	6
429	6
439	6
449	6
461	6
231	6
242	6
252	6
262	6
272	6
281	6
292	6
302	6
312	6
324	6
335	6
345	6
352	6
363	6
374	6
390	6
399	6
411	6
421	6
433	6
442	6
453	6
460	6
232	6
241	6
251	6
261	6
271	6
282	6
291	6
301	6
311	6
321	6
331	6
341	6
351	6
361	6
371	6
381	6
391	6
400	6
407	6
417	6
428	6
435	6
444	6
455	6
464	6
233	6
243	6
253	6
264	6
277	6
289	6
298	6
306	6
314	6
323	6
333	6
342	6
353	6
362	6
372	6
382	6
392	6
402	6
413	6
422	6
432	6
441	6
451	6
459	6
467	6
234	6
247	6
259	6
265	6
276	6
283	6
293	6
303	6
313	6
322	6
332	6
343	6
354	6
365	6
375	6
386	6
396	6
405	6
415	6
425	6
436	6
446	6
454	6
465	6
235	6
244	6
254	6
266	6
273	6
284	6
294	6
307	6
320	6
327	6
340	6
346	6
357	6
370	6
376	6
385	6
395	6
406	6
416	6
427	6
438	6
445	6
456	6
466	6
236	6
248	6
258	6
267	6
275	6
290	6
297	6
310	6
315	6
325	6
334	6
344	6
355	6
364	6
373	6
384	6
394	6
404	6
414	6
424	6
434	6
447	6
457	6
472	4
482	4
483	4
484	4
485	4
473	4
474	4
475	4
486	4
476	4
477	4
479	4
480	4
487	4
478	4
488	4
489	4
490	4
481	4
491	4
492	4
493	4
494	4
496	4
495	4
497	4
498	4
499	4
500	4
501	4
502	4
503	4
504	4
505	4
506	4
507	4
508	4
509	4
510	4
511	4
512	4
513	4
514	4
515	4
516	4
517	4
518	4
519	4
520	4
521	4
522	4
523	4
524	4
525	4
526	4
527	4
528	4
529	4
530	4
531	4
533	4
532	4
534	4
535	4
536	4
537	4
538	4
539	4
540	4
541	4
542	4
543	4
544	4
545	4
546	4
547	4
548	4
549	4
550	4
551	4
552	4
553	4
554	4
555	4
556	4
557	4
558	4
559	4
560	4
561	4
562	4
563	4
564	4
565	4
566	4
567	4
568	4
570	4
569	4
571	4
572	4
573	4
574	4
575	4
576	4
577	4
578	4
579	4
580	4
581	4
582	4
583	4
584	4
585	4
586	4
587	4
588	4
589	4
590	4
591	4
592	4
593	4
594	4
595	4
596	4
597	4
598	4
599	4
600	4
601	4
602	4
603	4
604	4
605	4
606	4
607	4
608	4
609	4
610	4
611	4
612	4
613	4
614	4
615	4
616	4
617	4
618	4
619	4
620	4
621	4
622	4
624	4
625	4
623	4
626	4
627	4
628	4
629	4
630	4
631	4
632	4
633	4
634	4
635	4
636	4
637	4
638	4
639	4
640	4
641	4
642	4
643	4
644	4
645	4
646	4
648	4
649	4
647	4
650	4
651	4
652	4
653	4
654	4
655	4
656	4
657	4
658	4
659	4
660	4
661	4
662	4
663	4
664	4
665	4
666	4
667	4
668	4
669	4
670	4
671	4
672	4
673	4
674	4
675	4
685	4
695	4
705	4
715	4
725	4
735	4
745	4
676	4
687	4
696	4
706	4
716	4
732	4
741	4
748	4
677	4
686	4
697	4
707	4
717	4
727	4
737	4
749	4
678	4
688	4
699	4
709	4
721	4
729	4
739	4
750	4
679	4
689	4
698	4
712	4
724	4
731	4
740	4
680	4
694	4
701	4
713	4
723	4
733	4
744	4
681	4
690	4
702	4
714	4
719	4
728	4
738	4
747	4
682	4
692	4
703	4
711	4
722	4
734	4
743	4
683	4
693	4
700	4
708	4
718	4
726	4
736	4
746	4
684	4
691	4
704	4
710	4
720	4
730	4
742	4
761	7
771	7
772	7
773	7
763	7
765	7
766	7
764	7
762	7
774	7
776	7
775	7
777	7
767	7
780	7
779	7
781	7
778	7
769	7
770	7
768	7
782	7
783	7
785	7
784	7
786	4
786	7
787	4
788	8
823	6
824	4
825	7
826	4
827	7
828	6
830	2
831	1
834	4
835	6
836	7
839	4
840	4
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, username, email, password) FROM stdin;
1	KovalchukValentynaPavloivna	KovalchukValentynaPavloivna@school.ua	$2b$12$OxIcbw4Ik.o6xvVvhFDxFudW8WPTTUnJOK9Hc29g3EDjBQYIqbvR6
2	BoikoSvitlanaDmytroivna	BoikoSvitlanaDmytroivna@school.ua	$2b$12$zzMeV1zAQTefpJobFiKPa.RYBbBogNwY3L8Z.XctCKAB9C67BpuzG
3	HoncharTarasPavloovych	HoncharTarasPavloovych@school.ua	$2b$12$xKIwbvm6TXsJcVVmR4W/kuAOpj4QiZvy8SwyktqVnA8Xxyx4DRT4O
4	MelnykVasylIhorovych	MelnykVasylIhorovych@school.ua	$2b$12$NEdSCsmHD.zXKBuw4IXxeuwyKD/LBY.7y1Ufmv2Q76eA8F6fiyQOm
5	MelnykKaterynaRomanivna	MelnykKaterynaRomanivna@school.ua	$2b$12$l92xiy5tvZkpR.WvnMECuesofWB.TBnEDvF2J713BJPdWawbQ9QzS
6	KozakViraPetroivna	KozakViraPetroivna@school.ua	$2b$12$pBflAZdvQz.HAA8m6WZVduxh3hi0cxDx/BAvMs1HRnhpR17Giery2
7	KozakHennadiiRomanovych	KozakHennadiiRomanovych@school.ua	$2b$12$Z73d2mQ4xDFzACz6.qYac.8ym0omSP8vXSNbME7Z4PrY3QIVxGW6e
8	RudenkoLevOlehovych	RudenkoLevOlehovych@school.ua	$2b$12$Dc4iNNSaR7dY3o8gw2UeSO94t/X8png55SlJTKLam9GN4Ol7knqrK
9	RudenkoIevaVitaliiivna	RudenkoIevaVitaliiivna@school.ua	$2b$12$PFeOfIJpwNa/au.CGa9aU.hqiOUP8iJj6yYJdXyuuAerV9xDDNW/C
10	FedorenkoZorianaRomanivna	FedorenkoZorianaRomanivna@school.ua	$2b$12$kZlc1R4Ca21ANqs0YYZRref4Mv6qoWuBSwNcgV4lvnWX4pdSG209K
11	BilykIaroslavVitaliiovych	BilykIaroslavVitaliiovych@school.ua	$2b$12$7wVwguDsw2ZDViKkTjY0Zu8UMvua/fYplxpxBfedgkFibS7HbP8QC
12	SydorenkoStepanTarasovych	SydorenkoStepanTarasovych@school.ua	$2b$12$8Pm.NqGDIsz/JBbHDNzRbe9PHVmqbxG8CF.QdzlhTbJqpKBE5XxAO
13	BilykSofiiaVasylivna	BilykSofiiaVasylivna@school.ua	$2b$12$UVKFD/k55dCFkKCdbedlvuG8/GRVKUYSQ6IYV3tmxEPnhtFUAufdi
14	SydorenkoLiliiaVitalyiivna	SydorenkoLiliiaVitalyiivna@school.ua	$2b$12$WwBD4txfNjkyNruGCsLQ8.Jli3rSb8mjo3wK6LPb5l5dDRIsjsxUq
15	KravchenkoAlinaVitaliiivna	KravchenkoAlinaVitaliiivna@school.ua	$2b$12$/s7e3miwHdUKY7QokjhnK.fPLz7ypHtTt3CFWnT.3yLLvr6hZ4Ju.
16	PetrenkoElinaLevivna	PetrenkoElinaLevivna@school.ua	$2b$12$05GTK86M2isBAexB1/mRDOBoVMsWHhXdd61kAgyu9T/hmQY7DIwiW
17	DmytrenkoArsenHennadiiovych	DmytrenkoArsenHennadiiovych@school.ua	$2b$12$ENcqwqy7dOaygBm4qCnmkOAyDd5eG5T1TbI4.3ls1Rq.kIxRuYGPG
18	DmytrenkoMelaniiaMaksymivna	DmytrenkoMelaniiaMaksymivna@school.ua	$2b$12$ApqinDB4dY3BuijKOcmJeOVdsVVGErC8AJn8.eLXB6Mt8CcGgf4Ja
19	LytvynVadymMaksymovych	LytvynVadymMaksymovych@school.ua	$2b$12$2SFZMAXuMrSm5tKp/4VNoOLGh7HKrNK.KYNc2R/qVQBHeO/xsGfSm
20	MykytenkoDarynaVitalyiivna	MykytenkoDarynaVitalyiivna@school.ua	$2b$12$icpvpQH44bLvYPy1mjzNK.M0/r2Biw5whDegE5xXit9nNisIJGoe6
21	LytvynPolinaStepanivna	LytvynPolinaStepanivna@school.ua	$2b$12$Go.29MW7PhZJSIpC3IiDtO37ZykyUIbXnXPqgoNwCUIl1M8DE0bS.
22	SavchenkoBohdanIaroslavovych	SavchenkoBohdanIaroslavovych@school.ua	$2b$12$/vcvmA5iq9oDGGgFWgV4k.Schd37wa4LmL3/PDYe3eWvqDHv.7HhC
23	KravchukAnnaMaksymivna	KravchukAnnaMaksymivna@school.ua	$2b$12$NbPs4uL8LDuYhQ1YDCcqIujv/uvfeupdYDo5.loCzpCLZGH1kIqAG
24	SavchenkoKarynaBorysivna	SavchenkoKarynaBorysivna@school.ua	$2b$12$s/g7.WiXB.5qzZYJu88I/.W9cBChw7fF6UQ4Du.5PdOgOPkiBlqoi
25	TkachIehorBorysovych	TkachIehorBorysovych@school.ua	$2b$12$i20n1d7N6fORMZmP06eeQ.po0aEKutX7JQIva4CtSF.YnTgeoy/1.
26	TkachMariiaArsenivna	TkachMariiaArsenivna@school.ua	$2b$12$UaY7QX6Qd723BRtKbiKeMeRSpeSeqgsJG/ufnZRoVCk8zkTxoDEKO
27	ShevchukNataliiaRostyslavivna	ShevchukNataliiaRostyslavivna@school.ua	$2b$12$qHsc76K0OoW3k7ml8/dfL.wYXFvsgOh3G1Tf0oXQr1pmo626TPysS
28	HryshchenkoMartaBorysivna	HryshchenkoMartaBorysivna@school.ua	$2b$12$tR.sopJKvo/XfnZfYF/eq.ABKuVFF04eGyX6KuYC8UK7aZaKCy5b2
29	KotsiubynskaOlenaBohdanivna	KotsiubynskaOlenaBohdanivna@school.ua	$2b$12$Yc.PSklX734efUG9At0rPO0iGAfr67bxYEbQz9ppV/.vDTtrjfTbu
30	PolishchukIanaRostyslavivna	PolishchukIanaRostyslavivna@school.ua	$2b$12$KVcuh/um5/UrBKp1CSV3BODZupwm6aFsn6ZM/OPrJvIiwpcsujlLe
31	BondarenkoSerhiiKostiantynovych	BondarenkoSerhiiKostiantynovych@school.ua	$2b$12$EnT5hcr2kWe3V9M7LTu4Gu4DKA3tluNF8vwSUIALRe9DYiMZq8TN2
32	SoloviovaDmytroIehorovych	SoloviovaDmytroIehorovych@school.ua	$2b$12$3A6e1/GCPAkxFdwO2tTz3OQ7.Fr3TUnr9YSIprDWFHSItlTZTSSpK
33	BondarenkoLiudmylaFedirivna	BondarenkoLiudmylaFedirivna@school.ua	$2b$12$7LuA5QfGLTuVWjDGKPl2T.AXidcR5DayshxcreW93Nvk0/k1m5.Mq
34	SoloviovaOksanaArtemivna	SoloviovaOksanaArtemivna@school.ua	$2b$12$VExQx0zHHvY.fqrLLoN0BuUST4ZlBRDGvH1SIJKtanmY2YUrVx532
35	MatsiukIrynaKostiantynivna	MatsiukIrynaKostiantynivna@school.ua	$2b$12$K6NjD.4ghYxx0qYtIm/8sO77qgKaMBaAA21D4Ww7YoXoLPwyrUuiO
36	IvanenkoIuriiArtemovych	IvanenkoIuriiArtemovych@school.ua	$2b$12$Gy6dnZ4JQq30HQf9ddIbpOq2bdffKlLWbhsDPdjHeStpBdSZj2l4K
37	IvanenkoNadiiaVolodymyrivna	IvanenkoNadiiaVolodymyrivna@school.ua	$2b$12$nY45ygoj1GFFdFXgDvjTQuaNK6Ji/Za0RXAQ3M1U7tfGjxqBXB2Ce
38	LevchenkoPavloOleksandrovych	LevchenkoPavloOleksandrovych@school.ua	$2b$12$aF4/ZQTZyJW06vFJqVaFpeH3JngU4ywidA55bEvg086sutuCZCVIK
39	LevchenkoSvitlanaAndriiivna	LevchenkoSvitlanaAndriiivna@school.ua	$2b$12$pulWgTJcDAXLuyC3Co.YLefp79ihN2DqfNxe8Vj49DHb/lJNbZR9e
40	DemchenkoHannaArtemivna	DemchenkoHannaArtemivna@school.ua	$2b$12$fZHL6neDEsLen8pgfl4X1O6mn6rQigDSQKS40uODrtujq8hPGg9U.
41	KovalIevhenAndriiovych	KovalIevhenAndriiovych@school.ua	$2b$12$WDirRVDh0eTEugm8yMRjAOWDaZ6sC1ox3CwMg90xWa4eOKzJp/92e
42	KovalMarynaDmytroivna	KovalMarynaDmytroivna@school.ua	$2b$12$GrhS1BvaubLsFxMtrZ4QOu.3LKUw9fx1UPh56nAaJ3nyUpGLZzOXC
43	ChernenkoVolodymyrVadymovych	ChernenkoVolodymyrVadymovych@school.ua	$2b$12$XTE9Vl.4uzkaSQM.OSvOzuFfzAjsW14LtR177FV5bAaQVXdPP6GmS
44	RomanenkoRomanSerhiiovych	RomanenkoRomanSerhiiovych@school.ua	$2b$12$AZdy3bGznE0ksqqDsD3OCOU9hHIdi4iBJ2K43Kk5O.o5xpHDHmvoa
45	RomanenkoTamaraMykolaivna	RomanenkoTamaraMykolaivna@school.ua	$2b$12$qQdhv5ne6VJ1QY5UwziDzugcr/09aBEVwWIz/45W2wAZmPUqtWLLS
46	KovalskyiViktoriiaAndriiivna	KovalskyiViktoriiaAndriiivna@school.ua	$2b$12$Z7.QSwdRgdg8hxh5qBhwO.Y7NfEW30EYjGCgWdP2WsD9dMApxf2by
47	BoichenkoPetroMykolaovych	BoichenkoPetroMykolaovych@school.ua	$2b$12$TuS5F3I/yFIfx2CykgHJLuyWZWPFeN7jMGihrVmAwg9dJu55QkhgO
48	BoichenkoValentynaPavloivna	BoichenkoValentynaPavloivna@school.ua	$2b$12$Vo2AMtbdweIxy6axAJtzq.t8AhJQ8dxpuq/4M7TSLOjx9yMk/Ss6O
49	PavlenkoVitaliiIuriiovych	PavlenkoVitaliiIuriiovych@school.ua	$2b$12$ZVhhg2bTn5WY5Kn1t/Zn..yci9lFTvPj4HvTVQ48oRoZr.foMglCi
50	PavlenkoZorianaIhorivna	PavlenkoZorianaIhorivna@school.ua	$2b$12$o0V5ICLMk1vUeUnOgPqpgucSmwcxs6Zujht9xwrZmEsJnjiYxqgRG
51	PonomarenkoLiubaMykolaivna	PonomarenkoLiubaMykolaivna@school.ua	$2b$12$7hTk4.9ZA6fW96ktUV8h4O0peJHLmBfxZiXTXbnSEZS6YC/ezBwqy
52	KlymenkoVasylIhorovych	KlymenkoVasylIhorovych@school.ua	$2b$12$yIhgFwuFRiDl/asqe5n1aOUqtCBKcLD.cx9PSvQ.JHNmE08X.Mqru
53	KlymenkoKaterynaRomanivna	KlymenkoKaterynaRomanivna@school.ua	$2b$12$fBVhwmsS4A/.fvUdGDBLe.EFIkUgS7sTpvvsEWymJMjZ6n5HtKV1K
54	KyrychenkoVitalyiIevhenovych	KyrychenkoVitalyiIevhenovych@school.ua	$2b$12$3Z/6XVs17Xyr34E3JrVtxus1dFUFv1vlHwRPspSguYmj6MNa1PjRe
55	KyrychenkoAlinaOlehivna	KyrychenkoAlinaOlehivna@school.ua	$2b$12$pmKIlUfLaF43HSEDBWkRDuW9OsPQRgAz6M1aNLmHmDrAxWmsXBFMi
56	MartyniukRoksolanaIhorivna	MartyniukRoksolanaIhorivna@school.ua	$2b$12$2s9mx46HYJDPNFkIfMzsDuHfA8LA8xkAmXCqi3891K2REiIVFYXPW
57	ZaitsevLevOlehovych	ZaitsevLevOlehovych@school.ua	$2b$12$QbRlOYQlYUz7VAgST6eHDO7CJd5fDqyIMVV.0pUMWqmQM2ATFIIZm
58	ZaitsevIevaVitaliiivna	ZaitsevIevaVitaliiivna@school.ua	$2b$12$Uqx7rJOZwg1mtdPcLvQRYOpdjWhu.XELAhBunJqb1xSxCpZQn3Jvm
59	MartynenkoMaksymPetroovych	MartynenkoMaksymPetroovych@school.ua	$2b$12$yVFiV0tep4IVzCY/hhfKLOxsu.vpYyHZtiKPvzPqWzJ61H9GIXzC.
60	MartynenkoDarynaTarasivna	MartynenkoDarynaTarasivna@school.ua	$2b$12$iChmcyTP/MwKbgUDyfDTk.yLrKGgoX9S7F164at023DfS714s3Nza
61	OstapenkoOrysiaOlehivna	OstapenkoOrysiaOlehivna@school.ua	$2b$12$kCLpDJmHI/6L0VGZahTnGOu9D7tPrOvHqYZAnxUhZ1T6NsZlEfYcq
62	KuzmenkoStepanTarasovych	KuzmenkoStepanTarasovych@school.ua	$2b$12$WySJQl4m38iYpPRFGo0GVuQ2P9QjIfq/Q3Bd0JAgVT9ob1djpzV.G
63	KuzmenkoLiliiaVitalyiivna	KuzmenkoLiliiaVitalyiivna@school.ua	$2b$12$ie/0acuLj9PXUxffrnROguJ6PcOGaFER/FAQ4p9ICWGfk/XRJCzze
64	PylypchukBorysVasylovych	PylypchukBorysVasylovych@school.ua	$2b$12$LsCxULc8DI1TOSyPN2Qf5ebmj3eO0radgMaCmOE9iFEScHLKz5bOi
65	PylypchukAnnaHennadiiivna	PylypchukAnnaHennadiiivna@school.ua	$2b$12$bUfrE6SHCjnB8o1PvcsrVuV9/3fQ5066ImFehR4Ex13oUAebjRtWK
66	SymonenkoViraTarasivna	SymonenkoViraTarasivna@school.ua	$2b$12$U3FpHsCccbOhbwSavJi0DeMYxmLmxPbTsbGzGYF.Nu.HDs6.GMDnG
67	ProtsenkoArsenHennadiiovych	ProtsenkoArsenHennadiiovych@school.ua	$2b$12$TSTRhhj/UZTJgxat13/nc.9itX1UcjrD6qAjUV0/LvRLbVxKLh8zi
68	ProtsenkoMelaniiaMaksymivna	ProtsenkoMelaniiaMaksymivna@school.ua	$2b$12$YIkt5bvr9Xt4DuRmVvXZGu4adCzndjSt3Tw3pNUT8d1/liVQ4FSzi
69	OleksiienkoRostyslavLevovych	OleksiienkoRostyslavLevovych@school.ua	$2b$12$FJ27YLxggJEoeyD5iPejsOKI0c/ad5LKVIeCGB47UF1wTPvUBy2QS
70	OleksiienkoMartaIaroslavivna	OleksiienkoMartaIaroslavivna@school.ua	$2b$12$GXCHDLM3XPSNRPU6z7pKL.bkR1UMVeXDsve1H5InVwKvUlSfCnXpm
71	KorsunSofiiaHennadiiivna	KorsunSofiiaHennadiiivna@school.ua	$2b$12$m0ftvLhF80COJ2WAPvBFvO2gRd77kd9onLZ2GrgPVDcifvUoMeg5C
72	NechyporenkoBohdanIaroslavovych	NechyporenkoBohdanIaroslavovych@school.ua	$2b$12$UhGp882p0rNVVwM.ivACU.rE59RsgZiegKNrMFUVS841JJpOPTKoi
73	NechyporenkoKarynaBorysivna	NechyporenkoKarynaBorysivna@school.ua	$2b$12$0kxs23eFanvDi7I1cFin6ecCGaCsbrrC6J9NlrEk80rQXd/C1cNxu
74	MiroshnychenkoKostiantynStepanovych	MiroshnychenkoKostiantynStepanovych@school.ua	$2b$12$P4XfBKUlJyat6HMRQ6oxnepNtQmxByXWIkA.h5CIOraaS.l/PgjwO
75	MiroshnychenkoIanaDanyloivna	MiroshnychenkoIanaDanyloivna@school.ua	$2b$12$owjCPRSACZvmlmE6l7jkWunj0wTw6X/GuV4lda.UT5UOgczTu9B96
76	ShevchenkoElinaIaroslavivna	ShevchenkoElinaIaroslavivna@school.ua	$2b$12$7VjtJ4avEhyFOoriV9zlIeRHlB.G0hb2suGy1f5jfZOH/P52JCAF.
77	KovalchukFedirDanyloovych	KovalchukFedirDanyloovych@school.ua	$2b$12$DEOsQmIgyG8RZgkdK4fRzul0z0STefUErntQK8H0y8xD/E73.nIla
78	KovalchukNataliiaRostyslavivna	KovalchukNataliiaRostyslavivna@school.ua	$2b$12$W4GJkcDJjTKn7wyn6JSOiOdppC36904DxDjaOzfdmua1XQfXPIt42
79	BoikoArtemArsenovych	BoikoArtemArsenovych@school.ua	$2b$12$wVSeeiXMnzl.J/IRwmuWaeYMpWK4nbsL8wf.sok3dPNbNmqXrTEGS
80	BoikoIrynaVadymivna	BoikoIrynaVadymivna@school.ua	$2b$12$RDW4d6s/ozxE.O.1Qbtv5OV69qGXe74g3GBBoTWnDKXU0cfoetULC
81	MelnykVolodymyrVadymovych	MelnykVolodymyrVadymovych@school.ua	$2b$12$Pq8K/UqUQMYT7iS3WCrTPOMFcO5cdrn/ze1JzvrTL9TnCtYdZjNPa
82	HoncharPolinaDanyloivna	HoncharPolinaDanyloivna@school.ua	$2b$12$uZ4J9wOZ3TtnoCL7HZcuTOsGTDeX6rb.Jr6Zz7RTL5x0w8h.JToYm
83	MelnykTetianaKostiantynivna	MelnykTetianaKostiantynivna@school.ua	$2b$12$aECqVvvdTcvSpeBgYHYWgOXvfKDZ89nNCvIjwADxbUYGsigcX3lPC
84	TkachenkoAndriiBohdanovych	TkachenkoAndriiBohdanovych@school.ua	$2b$12$wa.RxOV/x9WvXKRc6OVMju3QSIMf0dF5PoLHGFyprG3QuCqZdZfQO
85	TkachenkoHannaIehorivna	TkachenkoHannaIehorivna@school.ua	$2b$12$DUxM9JWAs1MqOM3AL2Ui0uJi7cMoOjpnx55OpZxUSVjf/cQyc5kcS
86	KozakMariiaVadymivna	KozakMariiaVadymivna@school.ua	$2b$12$uIXEoekj6Xi7gB34zqIZ1uoSWYwv87grjWESbtvFrcCDqkzcxxkfO
87	RudenkoDmytroIehorovych	RudenkoDmytroIehorovych@school.ua	$2b$12$ukVFABP90WFH9gEfMrcoZuI/uDSp1DEa6mv6zjSFJUznegPwIluRu
88	RudenkoOksanaArtemivna	RudenkoOksanaArtemivna@school.ua	$2b$12$YfQW3y/J.eQWA6ELYHisq.qWp.yHuJ1ER5Jvr2X96A6rfK/lJY/vm
89	FedorenkoViktoriiaOleksandrivna	FedorenkoViktoriiaOleksandrivna@school.ua	$2b$12$SC8Z2lp5fohsK63mVloqf.L0298t6Ggx6Biho/N08Ydk6fcOkM4x.
90	FedorenkoMykolaFedirovych	FedorenkoMykolaFedirovych@school.ua	$2b$12$wlO7A3uypLQcnUIRZuKJeu5LG5jIZda7dsb86RjTONJmr8pqPz6fq
91	BilykOlenaIehorivna	BilykOlenaIehorivna@school.ua	$2b$12$i5Lt5aTMCSKJ48qOiRxoIexe6T6SevKSsNWwh2khi4jOyYlpj42zS
92	SydorenkoPavloOleksandrovych	SydorenkoPavloOleksandrovych@school.ua	$2b$12$tmztvAibOE2DrE7RZ.k50esfZTObaXYbmUfQe.l3SFCpH29s6QzSS
93	SydorenkoSvitlanaAndriiivna	SydorenkoSvitlanaAndriiivna@school.ua	$2b$12$XngXEFCuPv5PrkfKxQ0y8OH.Cmff8cY09nkFpy/iiLFKGTh31Fey2
94	KravchenkoIhorVolodymyrovych	KravchenkoIhorVolodymyrovych@school.ua	$2b$12$f04ZddBaVUOprCupD04U.ueY8yVejBDQ6K2LZK0HflFUE/93ywsUy
95	KravchenkoLiubaSerhiiivna	KravchenkoLiubaSerhiiivna@school.ua	$2b$12$9y4XEV1fZUaiOKWcT0IQmOUboY/NO5helEtD9yOJ4lSXXa9fVGVyK
96	PetrenkoLiudmylaOleksandrivna	PetrenkoLiudmylaOleksandrivna@school.ua	$2b$12$/LhB/EBcQ.yhmccpjOWAf.x81HJjtghWIMfWr99Q5G4UaFCx4DjTK
97	DmytrenkoRomanSerhiiovych	DmytrenkoRomanSerhiiovych@school.ua	$2b$12$azcwN1.OlTFdxpEDnWRkIelAM4r3/BBL6d1CWaaa2ms/rPhirdXFO
98	DmytrenkoTamaraMykolaivna	DmytrenkoTamaraMykolaivna@school.ua	$2b$12$CB12TkiNmz51Ay9ZkVaanOyhyeAoenzjFXyeesFoO2mVwn2Jp6pBy
99	MykytenkoOlehDmytroovych	MykytenkoOlehDmytroovych@school.ua	$2b$12$seWTNjofPcfEhiDu/4u6/.8QqGZ8uxTos37A1KuaF.qHcF1HHUP7K
100	MykytenkoRoksolanaIuriiivna	MykytenkoRoksolanaIuriiivna@school.ua	$2b$12$8PfLGIpwMSsFPHudXzndheP1pvf1ErIHPsCuqWuZT4XY51lCVS682
101	LytvynNadiiaSerhiiivna	LytvynNadiiaSerhiiivna@school.ua	$2b$12$Lce2z93OJqTh4HPxPDLVjOxSJMur97NCFnJjql8GZ6v67Je0f9NDe
102	SavchenkoVitaliiIuriiovych	SavchenkoVitaliiIuriiovych@school.ua	$2b$12$ErV5flYyQbhmhoBS7mrup.EOOOJimYumi1xaPm.bs/xa0487Levx6
103	SavchenkoZorianaIhorivna	SavchenkoZorianaIhorivna@school.ua	$2b$12$ZuFKFcYKJbrDNHh5CFV2hukh7khcR7eqf/Qpsd6j824/Ls4r1v8w6
104	KravchukTarasPavloovych	KravchukTarasPavloovych@school.ua	$2b$12$XwwI5PlwAV9nHhSlHSSqgu1AYBLDTEQXn3AbMmPKVr6DjkS0MEsku
105	KravchukOrysiaIevhenivna	KravchukOrysiaIevhenivna@school.ua	$2b$12$8lPwMcNrqC/H27Ln4D195e3NlHnUP5TDnNpclgQTRqwguSvCc4u1m
106	TkachMarynaIuriiivna	TkachMarynaIuriiivna@school.ua	$2b$12$M2AU1.VLMuDhZovoGhSptuaIPBnoBkykEimJ76BDVHyXS/JFqRGUm
107	ShevchukVitalyiIevhenovych	ShevchukVitalyiIevhenovych@school.ua	$2b$12$zbUkAjKgbi7VM5Rcw3rwZO6NvacHZvdYhQ0F4dI4Te7bsSum9G9vW
108	ShevchukAlinaOlehivna	ShevchukAlinaOlehivna@school.ua	$2b$12$pL/RrAZUrnnY9nvSbEVTxutidOUK4hnK2QbYqHTPg8yVFFvjVCUv2
109	HryshchenkoHennadiiRomanovych	HryshchenkoHennadiiRomanovych@school.ua	$2b$12$u9VbTKA59rc1qfhIo1vdKuSWC0O0ueAs0FOhrvV3usDBV86NyXwLC
110	HryshchenkoViraPetroivna	HryshchenkoViraPetroivna@school.ua	$2b$12$gHOupCJYHsdRoCfz5ei.he1YacjPVSzonmX1.lLF9M67sa3jaiWv6
111	KotsiubynskaValentynaIevhenivna	KotsiubynskaValentynaIevhenivna@school.ua	$2b$12$mDYd30w.7UYlU2RMYwNVgOZQiNVI/e9XOVYDflBjDDjMABScsoMW2
112	ChernenkoMaksymPetroovych	ChernenkoMaksymPetroovych@school.ua	$2b$12$IzYDWAhVaR8FNAEYxdpS4uLNjjw6urjNRSLmfDG.j.Fu5P0inqPzC
113	PolishchukIaroslavVitaliiovych	PolishchukIaroslavVitaliiovych@school.ua	$2b$12$SJKWQv.ntFweKqO6yP.GkuV8eyIprvaY4PWEbQrwfBTtJygDYBlW.
114	ChernenkoDarynaTarasivna	ChernenkoDarynaTarasivna@school.ua	$2b$12$1ZtX4OqI0AAJSuisBuypR.6DwgoklHCs6vK7Ss5vK9UEyiK9j11RS
115	PolishchukSofiiaVasylivna	PolishchukSofiiaVasylivna@school.ua	$2b$12$LEaBfzDL5c1ZbzoC0r1O9.NYgfoocIXefVW42tMEPlCL.9RnaWUTy
116	BondarenkoKaterynaPetroivna	BondarenkoKaterynaPetroivna@school.ua	$2b$12$NYZS/VhBGd4.XWFNNjb5p.ETcdbQkEU0whFkckN1ObWBgLMdBwgXe
117	SoloviovaBorysVasylovych	SoloviovaBorysVasylovych@school.ua	$2b$12$W12W.weMO1ng.bge32MQwOf1n9bVYEsZzKmSr/IfJ9wTL3YWxLt7m
118	SoloviovaAnnaHennadiiivna	SoloviovaAnnaHennadiiivna@school.ua	$2b$12$f.WF6.p/37P5brPDwnf.5.b8JTkMPVZfZvnKddX2L/xgrqe7UxONW
119	MatsiukDanyloVitalyiovych	MatsiukDanyloVitalyiovych@school.ua	$2b$12$CcTmCuMhLmjwao8rtektkunkBW3k4N5TXJa9T.ukyggVH0Mb5Fqim
120	MatsiukElinaLevivna	MatsiukElinaLevivna@school.ua	$2b$12$veNIFqr30t/47dIw1Bbz0Obj3B.W729chbOCoZWrjkqmI98PGsZS.
121	IvanenkoIevaVasylivna	IvanenkoIevaVasylivna@school.ua	$2b$12$2oxrBjdSH57QjiOgwhfspeUVNEsaRPZ61ae0nzirYHSc./kVaYvRm
122	LevchenkoRostyslavLevovych	LevchenkoRostyslavLevovych@school.ua	$2b$12$0xBj.sFVUP0yy6c4J1dHAe3AvBhJ0quJ1uLtupZ6M..sGZGZaKXmm
123	LevchenkoMartaIaroslavivna	LevchenkoMartaIaroslavivna@school.ua	$2b$12$gZTtuU0k6L9dImZRMwRogOOgsxL8BkCOLzE1NF/8fvjNXBXEYhlSS
124	DemchenkoVadymMaksymovych	DemchenkoVadymMaksymovych@school.ua	$2b$12$VO5id9Ndn9oepvccr4oFfOCm05fxoqrM4sVCkUpMRqFaOubxZ9wVO
125	DemchenkoPolinaStepanivna	DemchenkoPolinaStepanivna@school.ua	$2b$12$amwOEDkSUUiNBy5Z.EU7cOR51AbCt5OrGMGgA29rWa5h4ow4rvvkG
126	KovalLiliiaLevivna	KovalLiliiaLevivna@school.ua	$2b$12$GHoTm/Q7o1dL3soZvfacWeJF.h7f1D0KalO13rs5R861cusQUmkyi
127	RomanenkoKostiantynStepanovych	RomanenkoKostiantynStepanovych@school.ua	$2b$12$o4kATFU319fHttVHLpfRs.ODM.9g2bfxJQ98.nc5SqvVambzwonQ2
128	RomanenkoIanaDanyloivna	RomanenkoIanaDanyloivna@school.ua	$2b$12$afy9bhdKQugnHuTUlZGhYe.cT.hHtXBQgyqDeuv2wFcneOxxcTz.q
129	KovalskyiIehorBorysovych	KovalskyiIehorBorysovych@school.ua	$2b$12$0qohSDMoeI21la6glPA/LuBxM06g8jxUHdzfd6XeJ7/Z.FdU9znR.
130	BoichenkoMelaniiaStepanivna	BoichenkoMelaniiaStepanivna@school.ua	$2b$12$lIpJ.hPG3./lLOt5RgSACOIoVsiKEgCx3A1uSv4yJanm0gnPMTn32
131	KovalskyiMariiaArsenivna	KovalskyiMariiaArsenivna@school.ua	$2b$12$mMNZQeOZ8LWlD7nGNUWVr.KwFmRllktiYkPrDDUko5F1E95G9UIc6
132	PavlenkoArtemArsenovych	PavlenkoArtemArsenovych@school.ua	$2b$12$crPQkxG.wLFyJHOYYQazJ.NBZofhzte6E1WOG1s4QxNDkVxm0VrAy
133	PavlenkoIrynaVadymivna	PavlenkoIrynaVadymivna@school.ua	$2b$12$SELn26FHsT5wetIctUCR3uS7RTlXXCbG0EqaEwV3lFWGRsscArKbW
134	PonomarenkoOleksandrRostyslavovych	PonomarenkoOleksandrRostyslavovych@school.ua	$2b$12$uArhrqU.bcA8FZl4BhD3p.7GpnAhhUmv2ygKfbk8rXLcMeBWqRxcK
135	PonomarenkoOlenaBohdanivna	PonomarenkoOlenaBohdanivna@school.ua	$2b$12$ghtOTBgJvXdQMVJIJz8txuGwftI4csoyOSFrdIRATyy4e5aALgblG
136	KlymenkoKarynaArsenivna	KlymenkoKarynaArsenivna@school.ua	$2b$12$EF./BYDT26OYU50YGHCpNeeFASpFkXoECvWOFw.yRUpa3D9PGWZKW
137	KyrychenkoAndriiBohdanovych	KyrychenkoAndriiBohdanovych@school.ua	$2b$12$hgnL3cxVGQ74ZvI5Nl3qSu784oaQGeaQEVAUxEAMNSIS1uS8DRLsu
138	KyrychenkoHannaIehorivna	KyrychenkoHannaIehorivna@school.ua	$2b$12$8aERK/gElgr/HIrusgGDUOkqF4BmYzHuloMgNKrIdHdKsJQhyrKKS
139	MartyniukSerhiiKostiantynovych	MartyniukSerhiiKostiantynovych@school.ua	$2b$12$cI7CS4SOi/V7ZWbP9sWxq.ATUJbNB1mOi75xowPFi64KkjPNWaUd.
140	MartyniukLiudmylaFedirivna	MartyniukLiudmylaFedirivna@school.ua	$2b$12$bnAov.3vokES.1fumJlLgukPhJzYTt5rDv5ZtDKo825WSjzScoiMi
141	ZaitsevNataliiaBohdanivna	ZaitsevNataliiaBohdanivna@school.ua	$2b$12$k.x84W8Lb1MIhNx7jBQ7rutJg3b9KLCs8xfXJRgc5Bt2TN9Z5URmy
142	MartynenkoMykolaFedirovych	MartynenkoMykolaFedirovych@school.ua	$2b$12$bmzOO1yvARuJlMPYWBHsS.Z7p2t/kSm0AZbnk0zkd4x.ekurxOoZi
143	MartynenkoViktoriiaOleksandrivna	MartynenkoViktoriiaOleksandrivna@school.ua	$2b$12$5pHApK3OmDCc1ewaHqCwl.Ok7Ft8Lps/4e0p9phVRQqAniiOSYdFe
144	OstapenkoIuriiArtemovych	OstapenkoIuriiArtemovych@school.ua	$2b$12$y4wWrlFhBEgGSmiVv8PHuuUifN.hD/I7DEOS5eCI69EG2.RFpDQdO
145	OstapenkoNadiiaVolodymyrivna	OstapenkoNadiiaVolodymyrivna@school.ua	$2b$12$T0eFaHbJ2aSVw2qLCa57vulDG0e6OA37obdtEK6akZNMLsfiTdLUC
146	KuzmenkoTetianaFedirivna	KuzmenkoTetianaFedirivna@school.ua	$2b$12$/ZbmTqOcOnCxoBasZHqsEeKJkh0EQzJGxIeTT8CYryxwaYbSS7aH6
147	PylypchukIhorVolodymyrovych	PylypchukIhorVolodymyrovych@school.ua	$2b$12$mvObRGEyFb1iQdicrbBx8OJap.7nG5SbbS3lNMBIBfmtvetrTWbMG
148	PylypchukLiubaSerhiiivna	PylypchukLiubaSerhiiivna@school.ua	$2b$12$zfdu4cL2UgpDyMlZomOi1uao02ihDcEJQ25rHbQTGTLPCU/FdcmDO
149	SymonenkoIevhenAndriiovych	SymonenkoIevhenAndriiovych@school.ua	$2b$12$zRpbhXeoGgOLZ0vMBEG3HuGvXe.jrixuDdqSqU3MfjUIXgcW8DdpO
150	SymonenkoMarynaDmytroivna	SymonenkoMarynaDmytroivna@school.ua	$2b$12$QV71n1v8qDvVAQYXwHP2bO2sb.JfjRtRIDun/TUPiYAsDWAuOwioW
151	ProtsenkoOksanaVolodymyrivna	ProtsenkoOksanaVolodymyrivna@school.ua	$2b$12$zdKXAjEdSDkk7yUqk.OMner031.vmrGmt9c..UqFO1neRHMYJPRM6
152	OleksiienkoOlehDmytroovych	OleksiienkoOlehDmytroovych@school.ua	$2b$12$bpsQDf9RsWWZ/hgDtb.TQOB25KLlUUd.ekxh1Ase7KgZtnr.BF25C
153	OleksiienkoRoksolanaIuriiivna	OleksiienkoRoksolanaIuriiivna@school.ua	$2b$12$Vy3h/g0jXKYxNSeFYCazoe3lycE0l1nqU3ESxWWPclSwIn6GnXkwS
154	KorsunPetroMykolaovych	KorsunPetroMykolaovych@school.ua	$2b$12$EorT2xfUEZJrHEb5xVPbF.kfSxuOcItk/X3ev6BYqgGbEXIzwhbYu
155	KorsunValentynaPavloivna	KorsunValentynaPavloivna@school.ua	$2b$12$zrFvZEuCtbl6jSHQZJBQMOSZVL.Hx982n.bA4AGjshPwv9PYTnjDm
156	NechyporenkoSvitlanaDmytroivna	NechyporenkoSvitlanaDmytroivna@school.ua	$2b$12$Vcl2xgHi6VmG/08A1dE03uvuy6UuKVVn5c3kt.VJzm28A79Utv5Mm
157	MiroshnychenkoTarasPavloovych	MiroshnychenkoTarasPavloovych@school.ua	$2b$12$vpuQYkgF2mTBAd6UJwq1C.LUBejqky3P1lW4Iea3inLIY.FS3S5RO
158	MiroshnychenkoOrysiaIevhenivna	MiroshnychenkoOrysiaIevhenivna@school.ua	$2b$12$d.TxpPODNJgacQfiN1pxUuv/atKybk3wovuxGGt8KbqNgQzfT43IO
159	ShevchenkoVasylIhorovych	ShevchenkoVasylIhorovych@school.ua	$2b$12$klUaF3RPMyd9iX9aByqN9eR5W1c8ydJ9xN24RtEkBuWXTzOHH5XGW
160	ShevchenkoKaterynaRomanivna	ShevchenkoKaterynaRomanivna@school.ua	$2b$12$2bTF5dyweoAh2D9owPqUk.ye.XBDW4L5.Bn/uAx1.h3rsZkwFhHOm
161	KovalchukTamaraPavloivna	KovalchukTamaraPavloivna@school.ua	$2b$12$SVbjFvfvUCA/uMQvGAIVc.7DaBQGpL98odvxwmZzBMrFX4WzPaL3O
162	BoikoHennadiiRomanovych	BoikoHennadiiRomanovych@school.ua	$2b$12$1bdYzD4C.UoqV0wIeiIz7e/t8TvJ.klNQJm53j4NlPIhEai0Xp0hm
163	BoikoViraPetroivna	BoikoViraPetroivna@school.ua	$2b$12$DG/Bavgw3wKO5tIJhvgEkOAAtlD2.8CmZSvCI/YGwOOkvhXng.01O
164	HoncharLevOlehovych	HoncharLevOlehovych@school.ua	$2b$12$c8V.Cv1Ie/iIuPCqu5/UjueGny0MguX5m2Cq4tgdF3XOGEUNvW.lG
165	HoncharIevaVitaliiivna	HoncharIevaVitaliiivna@school.ua	$2b$12$pOewzJuYWmNEx7at.YS3dO25547.sau3fnaXOiJnLDEpPVbmMOMFa
166	MelnykZorianaRomanivna	MelnykZorianaRomanivna@school.ua	$2b$12$Km6B5BVoGas.x6tsW/3vGO8o2JQTwoyVsrucPdWNFajJ5kNVwFc6m
167	TkachenkoIaroslavVitaliiovych	TkachenkoIaroslavVitaliiovych@school.ua	$2b$12$poC5y6oS5RkX.Q7C6Wj7ueocs1MCYaYdHKsX9wsHGUXdOF46HfXLi
168	TkachenkoSofiiaVasylivna	TkachenkoSofiiaVasylivna@school.ua	$2b$12$JC0lyOlrIUMEKvBdBTmEleX89fZUom5acWCH5cdMpCHwaqhlGwcOG
169	KozakStepanTarasovych	KozakStepanTarasovych@school.ua	$2b$12$RBYbUtu2oaz.aakFB7HFNuSxnRPw71/MrOgrivCzWbnCcpdiP9O1u
170	KozakLiliiaVitalyiivna	KozakLiliiaVitalyiivna@school.ua	$2b$12$IwR5cWLd6bY3ely2QHV0qObuMsXyuqLpjczmQv8E7DGtfEbzIKhl6
171	RudenkoAlinaVitaliiivna	RudenkoAlinaVitaliiivna@school.ua	$2b$12$OgLxIq86es4NlGuUeTwTh.yDFXlGDAGVaaSipmmRn4Y7gf7nQfvj.
172	FedorenkoDanyloVitalyiovych	FedorenkoDanyloVitalyiovych@school.ua	$2b$12$jczVsYPuvHSJHysBouz3XeB.ur7g7Lyx1mRlHlmxYKoGrkShHZDgO
173	FedorenkoElinaLevivna	FedorenkoElinaLevivna@school.ua	$2b$12$5FAdQH6JYADHQMBe2Q/lcu7HPp4NcgFuGQ1HA4zO9HYSHbFRWPMxS
174	BilykArsenHennadiiovych	BilykArsenHennadiiovych@school.ua	$2b$12$5nh.0oNGu8sUEa000xQCHuQ7YfG23.6KOUbHddd8Y6xx0vxBNctRC
175	BilykMelaniiaMaksymivna	BilykMelaniiaMaksymivna@school.ua	$2b$12$XUJk/dUnjjf.HltzMOe4ZuLtHS7c5.VWqo5cp7Dus0cvBw8d/cq9i
176	SydorenkoDarynaVitalyiivna	SydorenkoDarynaVitalyiivna@school.ua	$2b$12$hK6SfxfFIxidyfFhUw//LeavzHs3Js/zlnEx.QGe7Q0LcgBW1zwge
177	KravchenkoVadymMaksymovych	KravchenkoVadymMaksymovych@school.ua	$2b$12$IVEHeBd7sKz4S9lUEhLrkOsuzTmvhNl6UsoaS2MaqYP52oTJjOUCS
178	KravchenkoPolinaStepanivna	KravchenkoPolinaStepanivna@school.ua	$2b$12$zrlg8eqp0PzoOr6tMmDK7egAe5TDKhhSUBQLIq6JHp8FDez0zYcq6
179	PetrenkoBohdanIaroslavovych	PetrenkoBohdanIaroslavovych@school.ua	$2b$12$xun2ImWRfxjU46guXiBFXu/I/nRb8fIfAxdQVDpplUBqAGalHBBCC
180	PetrenkoKarynaBorysivna	PetrenkoKarynaBorysivna@school.ua	$2b$12$OTvaf.zB.fWoH9fMWhTlT.PDDM8jXlZ5NIhe/KLVoQtCZiLajRT2e
181	DmytrenkoAnnaMaksymivna	DmytrenkoAnnaMaksymivna@school.ua	$2b$12$lDKLeoAeFk4dJWpGcEloXefzwTtl4X59V7kkp3U3mjszfheWiBY1W
182	MykytenkoIehorBorysovych	MykytenkoIehorBorysovych@school.ua	$2b$12$fDiOybGNoOsHivtU.fG/5e8A4yErI/5AIlpL9CijiT28ZBRHIkpSi
183	MykytenkoMariiaArsenivna	MykytenkoMariiaArsenivna@school.ua	$2b$12$hp4IeLdfHREUhZtRNYmv1.TYbR/UqCP.9uHKFRprhNiZNZwEg8zJ.
184	LytvynFedirDanyloovych	LytvynFedirDanyloovych@school.ua	$2b$12$PD5WKN8RLVm7vJipwnTukeguGeYz3DErtRKnuiA1jSrZD8xKamngW
185	LytvynNataliiaRostyslavivna	LytvynNataliiaRostyslavivna@school.ua	$2b$12$N6J05C6MvHcZ5tp0VOijheQ5YPx05Zaw3Bnzh93X5VmjOXDCOF.oW
186	KravchukOleksandrRostyslavovych	KravchukOleksandrRostyslavovych@school.ua	$2b$12$nGR4uXDfNCCmnxJ1ycG8duDzvCVutt0YrCDAxXKC3JD3BO9uOQPCm
187	SavchenkoMartaBorysivna	SavchenkoMartaBorysivna@school.ua	$2b$12$dFnXgs15o62wrjU0yXTxxeEzm0d1nxNWaGR2C79ZV2jbujcxdXbIG
188	KravchukOlenaBohdanivna	KravchukOlenaBohdanivna@school.ua	$2b$12$wFmHllj.7pveHoKymDpO0.mdVptczu4NbFwYTe.q1csRDyp3RnO8O
189	TkachVolodymyrVadymovych	TkachVolodymyrVadymovych@school.ua	$2b$12$PUNWdtL32hMJXwgUK7QHUu6ikWG.xbCvgSOfz3fV7W/F2Jv4i90uC
190	TkachTetianaKostiantynivna	TkachTetianaKostiantynivna@school.ua	$2b$12$dLa4yhh8.zZzQIhPUA/KK.xpcHbMdfBFb1V88VfDSoRFGW5jpvmCK
191	ShevchukIanaRostyslavivna	ShevchukIanaRostyslavivna@school.ua	$2b$12$X2SylAUIRYuNUlzTQSz.TenmkULl5nriN6yUG8d.XPWbfh4QWUK8W
192	HryshchenkoSerhiiKostiantynovych	HryshchenkoSerhiiKostiantynovych@school.ua	$2b$12$bIR46srpMMafJ0hC.psUqeRon.Bn9GWHDxsOKCRGRFL/MJT276wQK
193	HryshchenkoLiudmylaFedirivna	HryshchenkoLiudmylaFedirivna@school.ua	$2b$12$cCIuZ2YVfHxe9GxBznq9n.x4SKDMgFN7DEj4DegswNsOYcjH5HCBG
194	KotsiubynskaDmytroIehorovych	KotsiubynskaDmytroIehorovych@school.ua	$2b$12$QqtAJ9dq8Jh8jRC/FsVmeOtO9WSr2g.93gRUQ9bjhbr0L58rGGd2e
195	KotsiubynskaOksanaArtemivna	KotsiubynskaOksanaArtemivna@school.ua	$2b$12$QvZRGeecsbbjpQHJcBia6.BRwAb8sdlutmBlUajQcnqWGOB6Lfvpu
196	ChernenkoIrynaKostiantynivna	ChernenkoIrynaKostiantynivna@school.ua	$2b$12$uBPYRZphlTUvEytOfKXRTOjNgq7hA76oGF1sktcf63CQZfNPCkoC6
197	PolishchukIuriiArtemovych	PolishchukIuriiArtemovych@school.ua	$2b$12$OG3sl4ENu4zw48DJ8l46VOif2E9qxz41IqXamVDPElb4C11hyVBbW
198	PolishchukNadiiaVolodymyrivna	PolishchukNadiiaVolodymyrivna@school.ua	$2b$12$Kmou.dt361zm9z0NioDxMepghTtapLpTyCoXXOt2z6IGUgXx1fW3C
199	BondarenkoPavloOleksandrovych	BondarenkoPavloOleksandrovych@school.ua	$2b$12$GpPiiFPOXNSRPNpv1Eu2S..iQcomONpXKH.sNBU0Glv7dXfvqS5Ym
200	BondarenkoSvitlanaAndriiivna	BondarenkoSvitlanaAndriiivna@school.ua	$2b$12$p49mmeTmTkmmAU29a9mxhuDccG6BMCtHviMMniD7MuzSMzuvlLGUK
201	SoloviovaHannaArtemivna	SoloviovaHannaArtemivna@school.ua	$2b$12$97yCH6RT0VnAVpDJ3mLrQeHtm5nhg.EBPe3knCO./MrnxKZf66M2y
202	MatsiukIevhenAndriiovych	MatsiukIevhenAndriiovych@school.ua	$2b$12$hHRLwSWlBTT9iC8psOm1heXFzno5n.gn6ZuuVGWGhOp890Lvz5UYG
203	MatsiukMarynaDmytroivna	MatsiukMarynaDmytroivna@school.ua	$2b$12$8wAH6z9F4k9UnRJ03JmAK.CKS2/CJ1znbNeuv1BddNRXucYq1Ldne
204	IvanenkoTamaraMykolaivna	IvanenkoTamaraMykolaivna@school.ua	$2b$12$uY6RBE7B..OccbcZvCFGZO7X7d7n8Ih9lZkTcY94iGTEfWafdGfk6
205	IvanenkoRomanSerhiiovych	IvanenkoRomanSerhiiovych@school.ua	$2b$12$/15M3dUYDYJSHxUWua5rVeNra.ibs0h87ckww8Rnu2yaHdag7RPhu
206	LevchenkoViktoriiaAndriiivna	LevchenkoViktoriiaAndriiivna@school.ua	$2b$12$yduUDsuraqeD0k6JPWp5Re5q.0l371ewnbgx1EDHb.XK5R1CiRF9q
207	DemchenkoPetroMykolaovych	DemchenkoPetroMykolaovych@school.ua	$2b$12$xOk4KGuYCgHfh4hZvkcYv.ecSXQe50Ji163cqyu.dCGaC1EU5tPtG
208	DemchenkoValentynaPavloivna	DemchenkoValentynaPavloivna@school.ua	$2b$12$DdBQpEbq2Pb5ogUfA4p55OViI6n.UoL.9kwXIsYXHoB1hTCE9qVp6
209	KovalVitaliiIuriiovych	KovalVitaliiIuriiovych@school.ua	$2b$12$hqpzOMKdtlveUzvUXwm1CuKy7IoyYd4Ore3HWxLUM/U.ax4B0WoUC
210	KovalZorianaIhorivna	KovalZorianaIhorivna@school.ua	$2b$12$0//.JNXPfXBvpMhc6nU./u9AaChsOfcE.8Mh7NRYnMSJJhn72TiE.
211	RomanenkoLiubaMykolaivna	RomanenkoLiubaMykolaivna@school.ua	$2b$12$ILAodwPFvCj8SSW7y.jTneZ1N1AdZTPZOPnWlpyI5M/j9nXP02oyq
212	KovalskyiVasylIhorovych	KovalskyiVasylIhorovych@school.ua	$2b$12$W5.d3hScEDeGt2.COG9Xde7oSv6fH2NFZnUp.F8uqwokr40FlAJZi
213	KovalskyiKaterynaRomanivna	KovalskyiKaterynaRomanivna@school.ua	$2b$12$nyDzPSc.ei/.baEexkmqAeGE7W63DIJN5j6.ZYPrMrUjozqOAD6Bi
214	BoichenkoVitalyiIevhenovych	BoichenkoVitalyiIevhenovych@school.ua	$2b$12$.x/SBEVj2sJsixao94gH8eOWxxTDSvM985U1r9I8DL7YOUB/je0LS
215	BoichenkoAlinaOlehivna	BoichenkoAlinaOlehivna@school.ua	$2b$12$4UJsocqMBFOa7km6L.Sf3edVb3bQLXVNF0YVYCPD6dp4cP7wH6/Xm
216	PavlenkoRoksolanaIhorivna	PavlenkoRoksolanaIhorivna@school.ua	$2b$12$XAebxxGk.53/7P222EiFsOCfVofm5i9f4hpjP09mv4dE0V.FQMvCC
217	PonomarenkoLevOlehovych	PonomarenkoLevOlehovych@school.ua	$2b$12$3Un4ERizOKQSKDQDqIEOquMBFPSldFZG27z0bK1fSZWeufgLvxZj.
218	PonomarenkoIevaVitaliiivna	PonomarenkoIevaVitaliiivna@school.ua	$2b$12$ph6uK9p28XLUzoYZZC/orejEw5Fw9yc/3Yl0/vlfBJTFDeK1clRP.
219	KlymenkoMaksymPetroovych	KlymenkoMaksymPetroovych@school.ua	$2b$12$Ijjw7MQhXsucDzho5ZYUXu14f7pvmOEasHjRcmrbsbsdYaoedR9m6
220	KlymenkoDarynaTarasivna	KlymenkoDarynaTarasivna@school.ua	$2b$12$TS8WA.eGHzUWhiPaKThYn.j6e7zXyPjrJOdFPc/YcjoM39T.9GNIG
221	KyrychenkoOrysiaOlehivna	KyrychenkoOrysiaOlehivna@school.ua	$2b$12$GQaHNJqknEM3F2uol0c02uCLLR/28i2d6MEpyjJ1gzoCj27ICVbUC
222	MartyniukStepanTarasovych	MartyniukStepanTarasovych@school.ua	$2b$12$mG42UVaImF8zoHudkyr32e51Y/HpiEKe7puHPTyvSskDyfkGyRqZK
223	MartyniukLiliiaVitalyiivna	MartyniukLiliiaVitalyiivna@school.ua	$2b$12$BoBXgehJMoLJHPdqHZIQG.roHgCQE6U44nHY9ue9WGmesTcbeyxbS
224	ZaitsevBorysVasylovych	ZaitsevBorysVasylovych@school.ua	$2b$12$GNjbSL5RT61px//7cAzoEu2J9FxcDdSnU5xwe3H9gFQV.Pgp5bsPS
225	ZaitsevAnnaHennadiiivna	ZaitsevAnnaHennadiiivna@school.ua	$2b$12$8GIT/j/kSlj.3l6M2iO0W.lQHRmfqBsRFAo0FUAPCM9GAMd3/oYAy
226	OstapenkoArsenHennadiiovych	OstapenkoArsenHennadiiovych@school.ua	$2b$12$.NrXCRVXySZqZB6JpCJOneHHSoLV0Xwo0KwFJl6ZhCvBGJXf6G7gG
227	MartynenkoViraTarasivna	MartynenkoViraTarasivna@school.ua	$2b$12$xvQ8wAi5UBRG.1qztikriu92hKDUY9ZPVlzZUZyrxy8kPDGyrh3Ai
228	OstapenkoMelaniiaMaksymivna	OstapenkoMelaniiaMaksymivna@school.ua	$2b$12$Anr.Hi93L3Mlv1RCfqw2M.LdW1/Xt8k7d9Ky3pxnKf1YyT46.LH02
229	KuzmenkoRostyslavLevovych	KuzmenkoRostyslavLevovych@school.ua	$2b$12$Q5T1xm89/nSvpGzmcJ.aHOZX6XMy63rPmCa5Wo816ht2BEDG1Ntji
230	KuzmenkoMartaIaroslavivna	KuzmenkoMartaIaroslavivna@school.ua	$2b$12$wfqhgb65dURKW1sgBJ/rJeYUIoqah4a7pxggVX29uuGGFlSeEMT3K
231	PylypchukSofiiaHennadiiivna	PylypchukSofiiaHennadiiivna@school.ua	$2b$12$toZIobOjKm2Xs47ILSuVJ.BWb8BkkgViiLAXO8RRpzT3I.yDq6EuS
232	SymonenkoBohdanIaroslavovych	SymonenkoBohdanIaroslavovych@school.ua	$2b$12$56If9qV57dyvZN/xx.Nf2OVuxmg8lrNr8/C2VZcG//fOMm5rDvma2
233	SymonenkoKarynaBorysivna	SymonenkoKarynaBorysivna@school.ua	$2b$12$wKr/yVA3G8ye.IPS/JAU6.6aWVEUHP0hs1C7NdYNEryKZfHHMyqNK
234	ProtsenkoKostiantynStepanovych	ProtsenkoKostiantynStepanovych@school.ua	$2b$12$O15DxKMTAWyLRxKSUWhhY.hSiN0FIJVe.kUbJNQ7zZQujKYI0zaVa
235	ProtsenkoIanaDanyloivna	ProtsenkoIanaDanyloivna@school.ua	$2b$12$887XItOyYJLyMD/kV.cNLe8EE.2WbmYUzAEOmhC4V/M71DPErwKmu
236	OleksiienkoElinaIaroslavivna	OleksiienkoElinaIaroslavivna@school.ua	$2b$12$q9ghrXdSFCC0eExkD8PHw.40Iht6Tskayu6u.ZND./mb2sVq.Jt3e
237	KorsunFedirDanyloovych	KorsunFedirDanyloovych@school.ua	$2b$12$oI3IakPzP5J/4U36/psqSeqgpNYBa0nLvUTK1A.UhtlxG6aMRaYl.
238	KorsunNataliiaRostyslavivna	KorsunNataliiaRostyslavivna@school.ua	$2b$12$L/dceHcUx0ZOxNimSmj5MOx.mLsoDDQDS1OiybrQXtBylX34Moss2
239	NechyporenkoArtemArsenovych	NechyporenkoArtemArsenovych@school.ua	$2b$12$yp3hDxFE2tSvC.vLqzAtmeOFkNyvBIJrhQnASBk9yEbpYCDs4IZj2
240	NechyporenkoIrynaVadymivna	NechyporenkoIrynaVadymivna@school.ua	$2b$12$V5qG3xuiMvqWp.BtyO2tTOX7ei5sY3c9JWW4pxnxdLzU8MON0/h/O
241	MiroshnychenkoPolinaDanyloivna	MiroshnychenkoPolinaDanyloivna@school.ua	$2b$12$UCxgaZFZ1tmRL1Hb3qdYxOhkEIIRXGoJjtMTRmF2LE/8WRh0ml7CO
242	ShevchenkoVolodymyrVadymovych	ShevchenkoVolodymyrVadymovych@school.ua	$2b$12$sKjK/W6dlajKiTcLYoZh5uNcsX5W1eWignHdM.qN5HpMhe95gk3bO
243	ShevchenkoTetianaKostiantynivna	ShevchenkoTetianaKostiantynivna@school.ua	$2b$12$7.vgKa6znfaIYJHD6Q4fHe9VH2kNu3WxrEbskqC2rpLrPyoPmNP1.
244	KovalchukAndriiBohdanovych	KovalchukAndriiBohdanovych@school.ua	$2b$12$7EFx8oh.7Ng9GbuTFX1tUeIoe6AIKH8sNqqUFJSa7tR6MwS7kOYYy
245	KovalchukHannaIehorivna	KovalchukHannaIehorivna@school.ua	$2b$12$.fB7mSWvYn.ykEB9mV9HQ.xdiAO3R/2yixK2uNApJXCZ6VtIwVEFu
246	BoikoMariiaVadymivna	BoikoMariiaVadymivna@school.ua	$2b$12$bGypl6HYq4p8NK7vHgGxA.DFCvoFRYwq1thIDBJ26SKtbfC/snjD2
247	HoncharDmytroIehorovych	HoncharDmytroIehorovych@school.ua	$2b$12$vR2FvmKP.dCl8BQGAD0MxuZjsNo2NyLQtckyOsZQ3i5uOTZU.tWBi
248	HoncharOksanaArtemivna	HoncharOksanaArtemivna@school.ua	$2b$12$jsm3vCTnxIIZmCQNrJTpTuiFxA9dKE/KM7I.V72uhwrsVRkQfRb0S
249	MelnykMykolaFedirovych	MelnykMykolaFedirovych@school.ua	$2b$12$duh/o11H2DxDZ2E4g7YqPueZnv2P0wbmYQ9vFE.K/ZR7SKWYxbHQC
250	MelnykViktoriiaOleksandrivna	MelnykViktoriiaOleksandrivna@school.ua	$2b$12$wRQN4daaESgZtldUfRBKX.vb3El641yUcCdDuFyPvd1CI.F8B9yhm
251	TkachenkoOlenaIehorivna	TkachenkoOlenaIehorivna@school.ua	$2b$12$o0t.wBAooeRiDjxqTadXpOlAt32oHxQGRFbInBQsQNvUcmZxYJbKO
252	KozakPavloOleksandrovych	KozakPavloOleksandrovych@school.ua	$2b$12$yDw82E5nmeI/KVhr.weKHOuyCjMszCiOR82bX6zeGcWh2ofWpuOhC
253	KozakSvitlanaAndriiivna	KozakSvitlanaAndriiivna@school.ua	$2b$12$WrG1K6ZY/AvZVF3CGvrKBuPvJ82qQjXL354LNsnnpyiIZzGzvzKl6
254	RudenkoIhorVolodymyrovych	RudenkoIhorVolodymyrovych@school.ua	$2b$12$cCmp2jD4Mzcxp5l1SRyW9O1t69Sn9dZDrB37V19r7WcsohEHUPtqS
255	RudenkoLiubaSerhiiivna	RudenkoLiubaSerhiiivna@school.ua	$2b$12$nT7YakDu/Dv029zPPQ0VYemrSzGfA/kjpNqqVTsZv835QKCOvdOpO
256	FedorenkoLiudmylaOleksandrivna	FedorenkoLiudmylaOleksandrivna@school.ua	$2b$12$bXj03dm3eVbyGNIUAdFOvurJMv86IBu.FIKuIJkhwbRI4BbSOyVHq
257	BilykRomanSerhiiovych	BilykRomanSerhiiovych@school.ua	$2b$12$M16hv/WQNt30QYnuHiWzQuheDWL5to42/lW/gmvvfBPKG5du/bIFO
258	BilykTamaraMykolaivna	BilykTamaraMykolaivna@school.ua	$2b$12$vhJR0SjMRpe5SsJu7mZQeuwyp5tMCkXGWyst8ZsiYmHSOYkfIcBdy
259	SydorenkoOlehDmytroovych	SydorenkoOlehDmytroovych@school.ua	$2b$12$dQvOf8U7HJdsoWY9l3bww.Osi64hvQIG/Ky4js.OCVH8Qk1yFLyEG
260	SydorenkoRoksolanaIuriiivna	SydorenkoRoksolanaIuriiivna@school.ua	$2b$12$R7FXQpEddtJ1jZB3j9ddtemIGXK9AvtHkytiVEZH.Pk4m0wcpmJBC
261	KravchenkoNadiiaSerhiiivna	KravchenkoNadiiaSerhiiivna@school.ua	$2b$12$qkRFywCXWGU.0xhuCny2beQZkOb8qT518Vfa4ARjhKtw8A1KBY5oe
262	PetrenkoVitaliiIuriiovych	PetrenkoVitaliiIuriiovych@school.ua	$2b$12$9hnVlTUS/C3TK1MNYbKm4eQHl7WZwLvBU8GBaFMgKuNvk.TK3DAce
263	PetrenkoZorianaIhorivna	PetrenkoZorianaIhorivna@school.ua	$2b$12$wkAmtcsVY8hZm/wPPDuEt.UDCQ7nB4zam1vDCv7LRXFZbfoD0RU2i
264	DmytrenkoTarasPavloovych	DmytrenkoTarasPavloovych@school.ua	$2b$12$aBt2OzyXkxod/sGENy84Oe2SoO3zKOFIJEAv9DH9S3AG0O9rRte22
265	DmytrenkoOrysiaIevhenivna	DmytrenkoOrysiaIevhenivna@school.ua	$2b$12$o8seXNFhTu1/HU2gWvjQLeSZHe.RpBjukKJ4BM1LxE80uPZLQa6Qe
266	MykytenkoMarynaIuriiivna	MykytenkoMarynaIuriiivna@school.ua	$2b$12$i/sd0hqswq/pvo4T.cBoCeX53y2r6CmeQlgySWFVpUk2uMftWe0MC
267	LytvynVitalyiIevhenovych	LytvynVitalyiIevhenovych@school.ua	$2b$12$oN/JfN2WCPfVhSBSt8Iku.0slga.IsFtS5ziu1BYk1KXryhpSpmKe
268	LytvynAlinaOlehivna	LytvynAlinaOlehivna@school.ua	$2b$12$l6LVwCpjqNYprXPwBPddAOnmRFSGw6fk/Lx.fScZAXZhtEmTjCKXC
269	SavchenkoHennadiiRomanovych	SavchenkoHennadiiRomanovych@school.ua	$2b$12$kIVmcYEG2wPgim/5RgQpi.INkKPbgkH3R.jr6S60wIBfMvgc/imdq
270	SavchenkoViraPetroivna	SavchenkoViraPetroivna@school.ua	$2b$12$g3U5kJehS6W5dHJoaUnqvOdnxcnVFLYibnN31qGd3o0GYxEBRLfu6
271	KravchukValentynaIevhenivna	KravchukValentynaIevhenivna@school.ua	$2b$12$2RKPLDW6ghrrDQI50v6J8.nDOXtSk/hHH4p9ekGwdZNUSbH7TLrBi
272	TkachMaksymPetroovych	TkachMaksymPetroovych@school.ua	$2b$12$DVGjokjOhlYiQoc1ruJPmOcWZFzUyJ.5bZ3Y28hUBRK5sPd.m.9Te
273	TkachDarynaTarasivna	TkachDarynaTarasivna@school.ua	$2b$12$7jKMgcfP.F2Q9U7owRPKXusz0JGt6p4V708e8bdo.SQoZmV.hCTAi
274	ShevchukIaroslavVitaliiovych	ShevchukIaroslavVitaliiovych@school.ua	$2b$12$Z.Z/kVgYi9rnVAHsa1R/nezA7QKqncUQnDZwkUvkh2OoXI3O/bA1u
275	ShevchukSofiiaVasylivna	ShevchukSofiiaVasylivna@school.ua	$2b$12$rT0T1S1u4KQYvQOQfOuTvezrkEJokCAi9P5qOqU5JX2EVhsAeAgfe
276	HryshchenkoKaterynaPetroivna	HryshchenkoKaterynaPetroivna@school.ua	$2b$12$InozvLP4g/SrbTiJfOm/2OZ9NWhacIxzxA11rYvGwHk/sWww7nk0m
277	KotsiubynskaBorysVasylovych	KotsiubynskaBorysVasylovych@school.ua	$2b$12$BPuAMKkOiX6Iqki3XweeH.Vw3ncV5EXVOwuqzqgjnXwS6jiwXipqe
278	KotsiubynskaAnnaHennadiiivna	KotsiubynskaAnnaHennadiiivna@school.ua	$2b$12$UB3SIKEPJIuMBbLzRCmKqugh00YbXH28ZK19B0G4J.9N59/2hroXC
279	ChernenkoDanyloVitalyiovych	ChernenkoDanyloVitalyiovych@school.ua	$2b$12$TnVESANgNXn51879pkDOQ.tlD43GwkICRYI7XDk985rYYRdiANojm
280	ChernenkoElinaLevivna	ChernenkoElinaLevivna@school.ua	$2b$12$FXM7o0g.2ogkiSFfqSwlxuilS1utX9BqMqnxT/RK6U2BGnD5wu7dq
281	PolishchukIevaVasylivna	PolishchukIevaVasylivna@school.ua	$2b$12$VZLx1UF2Zd1r9w/pD1sx/.wCYMw5Mre266Wm981ZRFJBGfva8RhP.
282	BondarenkoRostyslavLevovych	BondarenkoRostyslavLevovych@school.ua	$2b$12$0yp5Y2CaF3SjsyIFEVZua.E78/gexMxBGmbBNYhwHAWMHyQdaoD6S
283	BondarenkoMartaIaroslavivna	BondarenkoMartaIaroslavivna@school.ua	$2b$12$1mHWH/M3wQsJoGVGGkH/ReDzxvZTrN9LUe3LV6aT31ocaFY.cXODK
284	SoloviovaVadymMaksymovych	SoloviovaVadymMaksymovych@school.ua	$2b$12$YJLOlhS52n25hXI/kVNTtOuchx1YbW2TCfTnTJOfG/8DOurjN6Tcm
285	SoloviovaPolinaStepanivna	SoloviovaPolinaStepanivna@school.ua	$2b$12$mDL61fU6Q7r3KSsImhk.BucUJiZ4hwQVrDMbDSfPGXfDOjCSbIUd6
286	MatsiukLiliiaLevivna	MatsiukLiliiaLevivna@school.ua	$2b$12$xRGRsigRtMv3jzuFKiTxreUzZjs8zSogobJ2VgNBZwBEVbLUzTQTG
287	IvanenkoKostiantynStepanovych	IvanenkoKostiantynStepanovych@school.ua	$2b$12$kGqExUNY9CbFfZoSp8zRjeo2KI.ov3rs/T27cWKJlhzIZeQSEJoGu
288	IvanenkoIanaDanyloivna	IvanenkoIanaDanyloivna@school.ua	$2b$12$m/KlXad0s0qPANiqVyaksO2dmLpF30z07mk/mRDNqi1n79BqXKlA2
289	LevchenkoIehorBorysovych	LevchenkoIehorBorysovych@school.ua	$2b$12$b.Xs7aocpyIEJIf.uKtmHey2q0pPnPXANvNngaCj9ghyRgtOYfznq
290	LevchenkoMariiaArsenivna	LevchenkoMariiaArsenivna@school.ua	$2b$12$yiJKt9/O8svOyv6WxOKIuOeElplJYN9QoGixnRKwjJsM.IcdZThy.
291	DemchenkoMelaniiaStepanivna	DemchenkoMelaniiaStepanivna@school.ua	$2b$12$88yT3k3.RZNMy1HQURBSc.3MrQGJyadvaAjdD3cygJuq8kntkj2ru
292	KovalArtemArsenovych	KovalArtemArsenovych@school.ua	$2b$12$tsgUVf7li.oLj/nZgO6MqOxMDtNaCW.YTd0mTIVNplzjSiKtp0Mja
293	KovalIrynaVadymivna	KovalIrynaVadymivna@school.ua	$2b$12$9TPSWNcfV8CS3FKt.9DuQ.3sKKecaK8lq8KjWWa8MQA17EMubgWsy
294	RomanenkoOleksandrRostyslavovych	RomanenkoOleksandrRostyslavovych@school.ua	$2b$12$DYQtambqpmVL9HAfNpclOO65tvqEjBXcauheSLkvn/W3knlVNmWOi
295	RomanenkoOlenaBohdanivna	RomanenkoOlenaBohdanivna@school.ua	$2b$12$IX8TJIGN7DBSKp5dWkRkTujKIEuz8HvHiopz5OitQyrITqWx1ZJja
296	KovalskyiKarynaArsenivna	KovalskyiKarynaArsenivna@school.ua	$2b$12$YcE./w.CM4nYiVprLTFEyuhfragsNY1JSZoCKGNXdEh1zPc6jyARW
297	BoichenkoAndriiBohdanovych	BoichenkoAndriiBohdanovych@school.ua	$2b$12$5MnvBhfS5s96oD68W3Jk..36hJ09pqwHRDHZk29oXPdAyI8SYMr2q
298	BoichenkoHannaIehorivna	BoichenkoHannaIehorivna@school.ua	$2b$12$EF6pJutJJrSE5ieUX2xfWOVZAKABz3ibekMBHg6DbvcF.Tw9li3N.
299	PavlenkoSerhiiKostiantynovych	PavlenkoSerhiiKostiantynovych@school.ua	$2b$12$kINXgJOkjDwzIKk4PA6cl.H7IIhx0DRpf3Yej0oCawM0gmKa1rtg2
300	PavlenkoLiudmylaFedirivna	PavlenkoLiudmylaFedirivna@school.ua	$2b$12$4baRxik0oTCWtHDUXYOWBOypbYeHN5jTfTrE1p2YjtqD4Mzf0.riO
301	PonomarenkoNataliiaBohdanivna	PonomarenkoNataliiaBohdanivna@school.ua	$2b$12$l5JrtCSjcZZ00.nYQf4iTucxg86339D2yCVStXdAi/Wx39pmm9avy
302	KlymenkoMykolaFedirovych	KlymenkoMykolaFedirovych@school.ua	$2b$12$Kxgy1DvIZce3DhZpxxy/Bu1S/52Q84bHzDtjU6XHI1DvFZTb1GPCq
303	KlymenkoViktoriiaOleksandrivna	KlymenkoViktoriiaOleksandrivna@school.ua	$2b$12$vo/AnBdsfpwm8YV5dbfvJuzeYiWyQ2JNtelGnC87V7ha46VGv5MnO
304	KyrychenkoIuriiArtemovych	KyrychenkoIuriiArtemovych@school.ua	$2b$12$zmCnvPYNdXnvrqEpfS.KW.49b.W02fjD004R36WdlRbbRgAjkVweG
305	KyrychenkoNadiiaVolodymyrivna	KyrychenkoNadiiaVolodymyrivna@school.ua	$2b$12$fcqYVFoZQP/ce1psgtoMDOTu2oYCPRTL22p/ibRj2LdFX7e.ANwZC
306	MartyniukTetianaFedirivna	MartyniukTetianaFedirivna@school.ua	$2b$12$0NZIJ//0ZZMLlQaTMPZbxeQlYpxOO7/maTgjaMMvVglG.zYsdnsfe
307	ZaitsevIhorVolodymyrovych	ZaitsevIhorVolodymyrovych@school.ua	$2b$12$Q7JGvG3xuawiI8WzGYEw6OZ.5sYw.mdsqdBr.yl6PtpR97knDmjt.
308	ZaitsevLiubaSerhiiivna	ZaitsevLiubaSerhiiivna@school.ua	$2b$12$A59Wbg93GRWceuy4YnS5LeuDeOVuc0RLljbShguP77/JRcK4vWreS
309	MartynenkoIevhenAndriiovych	MartynenkoIevhenAndriiovych@school.ua	$2b$12$WwQG9eZCcaBdoH/Q3TZgpe1QZrYNE4tNi/r.ZYYEjYooz9qfpmHsi
310	MartynenkoMarynaDmytroivna	MartynenkoMarynaDmytroivna@school.ua	$2b$12$aTpdkWnQXjyoxjpgcQ6WqOqnYkT2sjUKM0O/z3nmWMZgCDXYA.vQu
311	OstapenkoOksanaVolodymyrivna	OstapenkoOksanaVolodymyrivna@school.ua	$2b$12$qqQ3ykRfQ0nd69O.RKS80uPVEcky5A/7Fa6w59RFwAMmhdvHHKGsS
312	KuzmenkoOlehDmytroovych	KuzmenkoOlehDmytroovych@school.ua	$2b$12$zaogvrMhNRqxa5quQna4neSWaXhF.jKsD28n9DPBFB1tfFCj9X8Au
313	KuzmenkoRoksolanaIuriiivna	KuzmenkoRoksolanaIuriiivna@school.ua	$2b$12$A4x3Pku8XPM.so81whf8BO7p7gVp/RhMbGdR0nN9P.46p2tx28nRm
314	PylypchukPetroMykolaovych	PylypchukPetroMykolaovych@school.ua	$2b$12$a6k1VvIOkrpOu6R8T/er2eAUIdWN0SRXLSeQVmP8vtEYNGszCnZzC
315	PylypchukValentynaPavloivna	PylypchukValentynaPavloivna@school.ua	$2b$12$Cp3A/p.DoYJaD/SCdYxA5uyufsx5HE2Y3cfM7dx1lXxbN9DyKeuqu
316	SymonenkoSvitlanaDmytroivna	SymonenkoSvitlanaDmytroivna@school.ua	$2b$12$TJvE8mnjxwrsYfrFI6ka3uen1/06.gF8i3AYLLbNeHvS0MzeG12oa
317	ProtsenkoTarasPavloovych	ProtsenkoTarasPavloovych@school.ua	$2b$12$kTQRl2HqOmKFGyFErc8ISeeRxDMO/4b/nmFsurYvQ07jJ6wmr5aoC
318	ProtsenkoOrysiaIevhenivna	ProtsenkoOrysiaIevhenivna@school.ua	$2b$12$NnbY.a.riCZSExcmZG90IeOfNVzgpNJdCdU9xMXHCqklUNzcQvfo.
319	OleksiienkoVasylIhorovych	OleksiienkoVasylIhorovych@school.ua	$2b$12$VPgpxSrYGQK4U4f9HgYjLuv6iPreiaJ1pYRyre9aj/PfDYaL/lmcq
320	OleksiienkoKaterynaRomanivna	OleksiienkoKaterynaRomanivna@school.ua	$2b$12$HPi5O7vZSoi7wmJhILEUOuT2R4N2ueRVdpjfr4kmc.TPsxeQB3I9a
321	KorsunTamaraPavloivna	KorsunTamaraPavloivna@school.ua	$2b$12$MmJMmfEuIpu5qh3aIlbaReS8Br98g/1PjVikR8ZHBMVW/4saJt5Mu
322	NechyporenkoHennadiiRomanovych	NechyporenkoHennadiiRomanovych@school.ua	$2b$12$4vJHroPbG64KEJZitnUXoOq7.XKKseHKE.dwDLMjQC1lJBWPa6r3y
323	NechyporenkoViraPetroivna	NechyporenkoViraPetroivna@school.ua	$2b$12$/E7uB912//qgOq722ynlIu..wkH4HMhNzkc1M5urscupWB0QLXpla
324	MiroshnychenkoLevOlehovych	MiroshnychenkoLevOlehovych@school.ua	$2b$12$Tz6KHMeI.j1adKe3lJxiiuL.qUxeKtE/ph6RdK8Z//3RCLNttEUWW
325	MiroshnychenkoIevaVitaliiivna	MiroshnychenkoIevaVitaliiivna@school.ua	$2b$12$qxtlU5CP.dYHvRcM4XpeV.eVxoCWvruIvJYDqbLOmJyXpy8sO2qvm
326	ShevchenkoZorianaRomanivna	ShevchenkoZorianaRomanivna@school.ua	$2b$12$TEnp4Ay3pQUhcngAYmBihu76H0yXkuu/Wnp2PUvos4bpzkxa7dIBO
327	KovalchukIaroslavVitaliiovych	KovalchukIaroslavVitaliiovych@school.ua	$2b$12$ZxRWvl3joAae2D1SFlNoq.1KuMKBIAHjeZl99T9EeWNV2VPVKwptu
328	KovalchukSofiiaVasylivna	KovalchukSofiiaVasylivna@school.ua	$2b$12$ogc5mN5iiN4.LudkH4iITu.AjmS7F2.DaJtChsnlsKu7xp23nj/o6
329	BoikoStepanTarasovych	BoikoStepanTarasovych@school.ua	$2b$12$2szZqljSG7JZCSXObLq7temP9HZuuHjK3PIFIVSkoHvgVKbj4V.Ti
330	BoikoLiliiaVitalyiivna	BoikoLiliiaVitalyiivna@school.ua	$2b$12$W3im7sdJchJZZI40t5DKl.0AVqTwVDTaltVk6uERMvs55fgbcSsVy
331	HoncharAlinaVitaliiivna	HoncharAlinaVitaliiivna@school.ua	$2b$12$uCVhTUf012E7.4VQtuz3Cef3/joD/iPw9/4zrYYiv3e2wkhGq5aKW
332	MelnykDanyloVitalyiovych	MelnykDanyloVitalyiovych@school.ua	$2b$12$7QxnFUK3lPANZtbBytSVWujO3M9uZqjnYfjIZhj2RJs4xVtB6XTsy
333	TkachenkoArsenHennadiiovych	TkachenkoArsenHennadiiovych@school.ua	$2b$12$tZ6b5biXki2r8RzZshGVN.aOnl4cByeptAHTWGTw2OyLLRhEnMLzC
334	MelnykElinaLevivna	MelnykElinaLevivna@school.ua	$2b$12$YuxGoRHU/40X70Zf5EPHt.q9uEIpw/xgdRdoxC6R0CVV6mgbQhmfy
335	TkachenkoMelaniiaMaksymivna	TkachenkoMelaniiaMaksymivna@school.ua	$2b$12$G4LcKb.gc908KwYYQxIrROtgM5BcrKJ3HISYLkizm8xTM7hFULnqK
336	KozakDarynaVitalyiivna	KozakDarynaVitalyiivna@school.ua	$2b$12$UchjYDRY31PEwxVeo1.3XOBpc1m4XuQb1huUHBP6mJQE3l6jHTDO6
337	RudenkoVadymMaksymovych	RudenkoVadymMaksymovych@school.ua	$2b$12$12co/sEDUawis4TdChf1Ku4VHRqkGtJVRxhff4e3.iEDzClPqcrLK
338	RudenkoPolinaStepanivna	RudenkoPolinaStepanivna@school.ua	$2b$12$64HjUo4e.MXYsrg30nmpy.5ztQXrvU2iCFKomHZmAR/DoIto2Mb0S
339	FedorenkoBohdanIaroslavovych	FedorenkoBohdanIaroslavovych@school.ua	$2b$12$g85rFD81eMYnrQe7ER6nfOH073xIE9CQdDE4Pnq0ue0fdWavrkd6O
340	FedorenkoKarynaBorysivna	FedorenkoKarynaBorysivna@school.ua	$2b$12$CyxFus6asblxwfFeujMnM.DGQv/XrlJ2a5.1YRUnjsPxr5qC.GxXe
341	BilykAnnaMaksymivna	BilykAnnaMaksymivna@school.ua	$2b$12$n8.PJ1HTSIvZ.TdKtXZohe6QfI0/PCw8tgC9chw2b030b3qkLA40O
342	SydorenkoIehorBorysovych	SydorenkoIehorBorysovych@school.ua	$2b$12$Lyhbdwcoa1qHvum.hWPqXu5YvU/TPGXLG2lSNjVVDpVODXACTnaeG
343	SydorenkoMariiaArsenivna	SydorenkoMariiaArsenivna@school.ua	$2b$12$c3qxUfIwHxAorUPkH9gSfuUnii4hTRcmr0ZKXamUqo60AXcKRqt/S
344	KravchenkoFedirDanyloovych	KravchenkoFedirDanyloovych@school.ua	$2b$12$DzvSQwHBvUI7xN6xztj1Tu9KJqeeI/YrlCEV5I26VsbVxjN2myFBq
345	KravchenkoNataliiaRostyslavivna	KravchenkoNataliiaRostyslavivna@school.ua	$2b$12$p4FvqSJxY2x3vcYcdRJPv.FnNMOuCo0yCtPBW4sknhpmhJceE.5fq
346	PetrenkoMartaBorysivna	PetrenkoMartaBorysivna@school.ua	$2b$12$OR1f1jUvbky4pZ.ksFo.X.YSsKwdLXRFF/YDvDNGYfAJvwYj56seu
347	DmytrenkoOleksandrRostyslavovych	DmytrenkoOleksandrRostyslavovych@school.ua	$2b$12$1lzr693PXT.Gl7OdWhAPeuxAYfWZH8c5368VQ2oVWdXOZ1jCIwYoC
348	DmytrenkoOlenaBohdanivna	DmytrenkoOlenaBohdanivna@school.ua	$2b$12$Ue2M5zFrHAnMovchYvsCE.ddTTI8btiEJoqkgU4UMpqGsdSNewAba
349	MykytenkoVolodymyrVadymovych	MykytenkoVolodymyrVadymovych@school.ua	$2b$12$eIcqzeXSqfxsQehp8NILxeuFPb4vEtSDPGkfi6nuEQ81IbGnvX6rO
350	MykytenkoTetianaKostiantynivna	MykytenkoTetianaKostiantynivna@school.ua	$2b$12$io3in1fBtMqOq.QwVXUx0.RYqd6UxI0xe/XZ9a3olh3r7ubRWKSi.
351	LytvynIanaRostyslavivna	LytvynIanaRostyslavivna@school.ua	$2b$12$Ijm4ZvbeuajuyxLQVyC5QeauoGSqWOJ4KCzP3cFQVCZMFWifeO5Ua
352	SavchenkoSerhiiKostiantynovych	SavchenkoSerhiiKostiantynovych@school.ua	$2b$12$B3TkjDuM0tnml1CpdwcoguJgorBjcDHf6WWgFNS/nW5OqBZlIG.Ke
353	SavchenkoLiudmylaFedirivna	SavchenkoLiudmylaFedirivna@school.ua	$2b$12$awqTzKfmZf8zjG.XAz8ce.uLtiXEEyNbxWzcNVJE9H.VVCTB.z6uG
354	KravchukDmytroIehorovych	KravchukDmytroIehorovych@school.ua	$2b$12$5CCnjEaYBcUS3oID8AsIRexhR6s2Oikvm7VhkERiLdjKYI2Joxw4i
355	KravchukOksanaArtemivna	KravchukOksanaArtemivna@school.ua	$2b$12$uHQHWwjc.bGmFNivPHEkDOOS74AF0JXYEBl51HT8gxH1L5xHVP91C
356	TkachIrynaKostiantynivna	TkachIrynaKostiantynivna@school.ua	$2b$12$o1MgOZn9YCn5n0tZk.Qk/exMhZKOxMrEOCiwydWUB2g8wmoK2Yjpy
357	ShevchukIuriiArtemovych	ShevchukIuriiArtemovych@school.ua	$2b$12$f3v2ga0aW8UIt09o3zefQ.tGi72KWmFgA9KrxL/DI5/1tCvM81jIS
358	ShevchukNadiiaVolodymyrivna	ShevchukNadiiaVolodymyrivna@school.ua	$2b$12$JvtyMY1rE8s0y0/4Oa2GwO5YhE.fRZ2Z1IufXEMDV0NZokO.fNhWq
359	HryshchenkoPavloOleksandrovych	HryshchenkoPavloOleksandrovych@school.ua	$2b$12$n4oEWUAYkge63T.yt57oAOwvQauXr7/bZqJ.B8hzELZN6nNiPN1kC
360	HryshchenkoSvitlanaAndriiivna	HryshchenkoSvitlanaAndriiivna@school.ua	$2b$12$ZkWc/URgiI1iLLGapN6kD.3ZAKR9Of5KJ9UhtQqQsI8dPJQHYFw5a
361	KotsiubynskaHannaArtemivna	KotsiubynskaHannaArtemivna@school.ua	$2b$12$dOMfVawjJRTIe5nM944niO3hnws6mgxJiUFKHJOPB/rXky7qUf60C
362	ChernenkoIevhenAndriiovych	ChernenkoIevhenAndriiovych@school.ua	$2b$12$IGu34tQ27GRwj25lyKOPW.xm4QU5F1Skmiozd1hD06XdGaqw3/6r6
363	ChernenkoMarynaDmytroivna	ChernenkoMarynaDmytroivna@school.ua	$2b$12$UOhbl4TmgAbr/9CbZ0IH0ul7u5yKZ7Kerjs8ckQ5BXrkoVNzL6lG2
364	PolishchukRomanSerhiiovych	PolishchukRomanSerhiiovych@school.ua	$2b$12$lb2CaQ3tDeWb3eSZDS68Ou5.JKvuWtbmn72niKX4v1DYKiQFHMl7u
365	PolishchukTamaraMykolaivna	PolishchukTamaraMykolaivna@school.ua	$2b$12$ySzSxEPz4C3DJSfLC7fJcetW1GX5Of0wBGPGqs95SCoGpF5WjHdve
366	BondarenkoViktoriiaAndriiivna	BondarenkoViktoriiaAndriiivna@school.ua	$2b$12$6TXkg8s1/7lUcxwF5XRhGezdQX/HsxgUnMiDsRmTIslpFQwGVAMpG
367	SoloviovaPetroMykolaovych	SoloviovaPetroMykolaovych@school.ua	$2b$12$t9eACh33/kOQOmdDHyqmkOg1zIPYcxgA.6jjgDTOaFf6kjuNUD1Fi
368	SoloviovaValentynaPavloivna	SoloviovaValentynaPavloivna@school.ua	$2b$12$vkR7K4EnFx8tuibAX9/Xau4q16Qd7YzboycIofEfjExJDYJT9h0vq
369	MatsiukVitaliiIuriiovych	MatsiukVitaliiIuriiovych@school.ua	$2b$12$qtDsJFjJrVaisrqTTAg37eN60cO7b4aJB4BSAAqUTDmtaVSYIJ7NG
370	MatsiukZorianaIhorivna	MatsiukZorianaIhorivna@school.ua	$2b$12$ZOjg73Zct.gvaX0OlaRqfO7tgZQ1LXEFCPq8Axqg7bAJKLYrbiasq
371	IvanenkoLiubaMykolaivna	IvanenkoLiubaMykolaivna@school.ua	$2b$12$D.zeUoD9GhF.C2BpmHx6huXnsUIexa4hEScdnuCMw0b5mAPpkvLuq
372	LevchenkoVasylIhorovych	LevchenkoVasylIhorovych@school.ua	$2b$12$EUNz0ybK3dd74cveb0PCY.rb0nUWZzXt3uR66IwjcD8RUekvqGm6S
373	LevchenkoKaterynaRomanivna	LevchenkoKaterynaRomanivna@school.ua	$2b$12$EQIvjospWJ/J0gfPD90BjOw.nNWPmD9yyBwazxgUcNxdRssl/mbQK
374	DemchenkoVitalyiIevhenovych	DemchenkoVitalyiIevhenovych@school.ua	$2b$12$7A9699eZAluycZSMcsA5NOzxggQBJiKb3vkcyhyN5CuG8n9dF1XOm
375	DemchenkoAlinaOlehivna	DemchenkoAlinaOlehivna@school.ua	$2b$12$rBYyPmwothvUcFCBLk.wG./YKaduKCAY/FZrWBdHtWOGA8Qu0vtbq
376	KovalRoksolanaIhorivna	KovalRoksolanaIhorivna@school.ua	$2b$12$ZuEaKMfeveWqEo1AtdjO3uBP5PNNQZDqt2qcKtlvOOBGwjZHv50Di
377	RomanenkoLevOlehovych	RomanenkoLevOlehovych@school.ua	$2b$12$NNJOxWqXj8KeiQVFD8x0muoDlvKT8TuHdE.BM4FW.mnRlRKwvxZ8q
378	RomanenkoIevaVitaliiivna	RomanenkoIevaVitaliiivna@school.ua	$2b$12$ij.AlbiHO87JU7PDujGGtOXLG93oVardn5UDk4jO2TOIcfpsRz4b2
379	KovalskyiMaksymPetroovych	KovalskyiMaksymPetroovych@school.ua	$2b$12$LI74s0J0kKvFwSLFb/MKC.gfGjofedwTrx9ZsO4xKHlppFTOym44S
380	KovalskyiDarynaTarasivna	KovalskyiDarynaTarasivna@school.ua	$2b$12$s8tD9EvLDK5FODThDIkogumBqA9pYZRJupZpPttpmIjAYBIN33FO.
381	BoichenkoOrysiaOlehivna	BoichenkoOrysiaOlehivna@school.ua	$2b$12$bn91qu52P.Y7NOerbo0GHeJvE7EvrY0B3gkJK/EByb0TRUNYBIRGC
382	PavlenkoStepanTarasovych	PavlenkoStepanTarasovych@school.ua	$2b$12$qoFFbO47myG9DMPZIGnBteNJPhHw1WgWWACM9cgp2I8K3WUkQlRde
383	PonomarenkoBorysVasylovych	PonomarenkoBorysVasylovych@school.ua	$2b$12$UdG1mCSm6J57mKowfmR7Qun4iohKSee2Du755/GbrOTbPkpq71dXy
384	PonomarenkoAnnaHennadiiivna	PonomarenkoAnnaHennadiiivna@school.ua	$2b$12$R5c16TzvwCSsUdCHcO.a4O.6xWubPxsPmC1VwyyerUuaZJBIKXUh6
385	KlymenkoViraTarasivna	KlymenkoViraTarasivna@school.ua	$2b$12$9yJFuyr4CDO3uesPiFutmeI7ZaHAGu5AEsET1vqsAr23qpTR5AO/2
386	KyrychenkoArsenHennadiiovych	KyrychenkoArsenHennadiiovych@school.ua	$2b$12$hLYVQdBJeypDzjuPtjoDquadqId0fbb/hLhHcK5fx6KpBFl69hsIm
387	PavlenkoLiliiaVitalyiivna	PavlenkoLiliiaVitalyiivna@school.ua	$2b$12$IueRD5KlBH2Yy594dF1y0eUmqbQnmo2dQK/N9dE1DBmIvvV5E1OmS
388	KyrychenkoMelaniiaMaksymivna	KyrychenkoMelaniiaMaksymivna@school.ua	$2b$12$qctpqenoLxr.V3BPD54s6uXE.L5d2/g3gkI0afNscUfV/2cqhXBx2
389	MartyniukRostyslavLevovych	MartyniukRostyslavLevovych@school.ua	$2b$12$NcGOp04wzlb9Liq0GxjTHe7hpzTJ6iChJWuVZ1o9sL9qIP8q6ZZtK
390	MartyniukMartaIaroslavivna	MartyniukMartaIaroslavivna@school.ua	$2b$12$LrVseN9dmBTT7xAoZH0Ml.pwq1IntIjgBl7lRqoFqukp5QjUf1H7K
391	MartynenkoBohdanIaroslavovych	MartynenkoBohdanIaroslavovych@school.ua	$2b$12$nS51q4kGT6HApAC/wcrgTO5aZ4vMEVjXUFnFNQmv38ZZjZcQ1AMFy
392	MartynenkoKarynaBorysivna	MartynenkoKarynaBorysivna@school.ua	$2b$12$q1wB7fCtNHMsr1lV38VTZePdy23yY2JQVz7wBpKOQhPjpuaOosQ2y
393	OstapenkoKostiantynStepanovych	OstapenkoKostiantynStepanovych@school.ua	$2b$12$OFP2poX6jM.Jwp8FzKTVqOtazF8lmLgZdruRHUC0iqljGi044mTyi
394	OstapenkoIanaDanyloivna	OstapenkoIanaDanyloivna@school.ua	$2b$12$glnRaWaCjKMofkx8DPuTD.1bP.aIcj1Z7XmBItJSAgbmSlbSXjk2C
395	KuzmenkoElinaIaroslavivna	KuzmenkoElinaIaroslavivna@school.ua	$2b$12$dmJFFp5PC5GiVbJ/P8aWQ.kXZ4ccL5gtr9c/vdVV2vBoHIRm/jujW
396	ZaitsevSofiiaHennadiiivna	ZaitsevSofiiaHennadiiivna@school.ua	$2b$12$x8EJiEA9olibspxQLneyf.wpmOIc.CSRa09uANyqCd14ZI7dj/c3.
397	PylypchukFedirDanyloovych	PylypchukFedirDanyloovych@school.ua	$2b$12$QE4XjplGW8RctICDL2Gws.7YW3lx7f0Ft3BQXNJFrtb4GCHPowtai
398	PylypchukNataliiaRostyslavivna	PylypchukNataliiaRostyslavivna@school.ua	$2b$12$xjx6ImhMC.mSW0NvtpnJHevKOAoW3Zf6c1v31li41O0.Wndaesbq.
399	SymonenkoArtemArsenovych	SymonenkoArtemArsenovych@school.ua	$2b$12$bqOCKCQQpGD1DqjFB66xCOV.U.BI3xpLjcPLAGsPorR21i1D.SHhC
400	SymonenkoIrynaVadymivna	SymonenkoIrynaVadymivna@school.ua	$2b$12$.5ye8ZCYrMnZ8r/3/0sAp.bDgWNAHVa4ilIRKG6mOy.qom3.1sKVy
401	ProtsenkoPolinaDanyloivna	ProtsenkoPolinaDanyloivna@school.ua	$2b$12$M8QKzYu.ybu7d2VYwiTE7OrSS4GjHBj5njki2dtyaqlWtQ3pOINE6
402	OleksiienkoVolodymyrVadymovych	OleksiienkoVolodymyrVadymovych@school.ua	$2b$12$IXj3fzUqCjn8waauC.raAukcKUrLNT1g.PEa6DUZA4mQ9j/JiW9P.
403	OleksiienkoTetianaKostiantynivna	OleksiienkoTetianaKostiantynivna@school.ua	$2b$12$lT7kIkZZskM3PMzJ6lnwS.TXT2ZF6qua/.cdw6ogEMq70ZfTOGcIm
404	KorsunAndriiBohdanovych	KorsunAndriiBohdanovych@school.ua	$2b$12$Xq9Z5VsXRs36fzfAHKTyUOjVYCEuCsfi3bz3C9/McfJA/BsniirDW
405	KorsunHannaIehorivna	KorsunHannaIehorivna@school.ua	$2b$12$1l32G/5SpIZb7hT2hnGjrOvlrBIpfu8IDNHQ9Wun89miv8xyISNeq
406	MiroshnychenkoDmytroIehorovych	MiroshnychenkoDmytroIehorovych@school.ua	$2b$12$fmQQHvBCjyN9ppcQGmJWDufOp/j89SAFjoUdRUfyqjuP4ak5nipF2
407	NechyporenkoMariiaVadymivna	NechyporenkoMariiaVadymivna@school.ua	$2b$12$LwltHFw9MO8xEIyeGVC1uOsSQbWhDEmSORayN..8/rAFhmSn8tR6m
786	sniffy	sniffy@school.edu.ua	$2b$12$R9h/lIPzMZfG6sz.u62.4u9Bbi7Z9.T9j.L/nQp6E7Q6mY5M2m8G2
408	ShevchenkoMykolaFedirovych	ShevchenkoMykolaFedirovych@school.ua	$2b$12$LzZDJE4hzE19ZRXqg9tEIu2EVzxqhsB5p6H8cmWPYOYlgZq6P7pZy
409	MiroshnychenkoOksanaArtemivna	MiroshnychenkoOksanaArtemivna@school.ua	$2b$12$kKTGMg/jsKbnp1DLHOxBLuPfCCWr11uFdah2q3Re8AAJqe3NzomVW
410	ShevchenkoViktoriiaOleksandrivna	ShevchenkoViktoriiaOleksandrivna@school.ua	$2b$12$xpAmNh0ut6t3kDMIjG0KEejUUJ9NZHPlWoLHnW0/5vYyyeycO.oMK
411	KovalchukOlenaIehorivna	KovalchukOlenaIehorivna@school.ua	$2b$12$ch48YVKXgCVZL5VUj64nqeP3IEL2mablUZk61nhKhhcBwUqnHyl16
412	BoikoPavloOleksandrovych	BoikoPavloOleksandrovych@school.ua	$2b$12$57guO8jY7i7lsPJUkZc/COJyFn.JDpr2CJRV4EnBtlG6nLLVm6Boa
413	BoikoSvitlanaAndriiivna	BoikoSvitlanaAndriiivna@school.ua	$2b$12$uVYC1nsLLw.Ha0tZ2.Vl8eNmir3NeW8NLEkm/C4Hnq9BIO2TnlQ9u
414	HoncharIhorVolodymyrovych	HoncharIhorVolodymyrovych@school.ua	$2b$12$js3hXt71OvJEMqwzx1brIOCddqkZLLTYmGsqvAUzWVj0qld1PEvYe
415	HoncharLiubaSerhiiivna	HoncharLiubaSerhiiivna@school.ua	$2b$12$OBxFo34TldeeDF9/4ygIEOvDMHFFfoThpEaHBqpeQqCop5xfZRDAi
416	MelnykLiudmylaOleksandrivna	MelnykLiudmylaOleksandrivna@school.ua	$2b$12$vNiGZsyfOAH3xybZ.VoRAuMgeXPcVT/aQEHJj/9Rde03n1SDtqyf2
417	TkachenkoRomanSerhiiovych	TkachenkoRomanSerhiiovych@school.ua	$2b$12$H4I8KuYZM7Wrm/T.tyzSk.80/0.tDDzKJ8i334lulw8KeEzD1qxWi
418	TkachenkoTamaraMykolaivna	TkachenkoTamaraMykolaivna@school.ua	$2b$12$F1HPsnAQycwSOgoR5i59U.NacrfqNS5XsC3Mnpax/1Rjq6JY4dhyq
419	KozakOlehDmytroovych	KozakOlehDmytroovych@school.ua	$2b$12$aFNQH0YIdq2xHCoSc1xRhuiOk79G4FenocllgDgLhqU1fsVeRo.o6
420	KozakRoksolanaIuriiivna	KozakRoksolanaIuriiivna@school.ua	$2b$12$VYaU1UTZRLS3/ej79M.2HuTOZMKGCj8fjofNdtTm1Rbv9GkymWP6m
421	RudenkoNadiiaSerhiiivna	RudenkoNadiiaSerhiiivna@school.ua	$2b$12$J3lLytlWBqwGzrA9KJw3L.huJW.eKQqhBbuNGxmvWOZjj4QLOwVGy
422	FedorenkoVitaliiIuriiovych	FedorenkoVitaliiIuriiovych@school.ua	$2b$12$6hvDIjx9p0Ftol6xfjpone0u240IDjfPjbTQESjabEVxiF.iUhDr2
423	FedorenkoZorianaIhorivna	FedorenkoZorianaIhorivna@school.ua	$2b$12$LAjpO2W25IiaPIA5MGM/U.e9CA1Bbp4puUcAk8wEz0/57xRKuDgNG
424	BilykTarasPavloovych	BilykTarasPavloovych@school.ua	$2b$12$/ag4PmACId5tVaJgZUXYn.e1lE7JyU8reXhIGYo/vEIcJ4rI3JsUO
425	BilykOrysiaIevhenivna	BilykOrysiaIevhenivna@school.ua	$2b$12$b5z7HWIOPdNWXgfNupdp9uGpzZFeRz6/cfICWjdXR0O4WbvBhW44W
426	SydorenkoMarynaIuriiivna	SydorenkoMarynaIuriiivna@school.ua	$2b$12$pGP3pwJbJ1FLDvG48tvInuJ2WAXciwNd86/n1BCNciE8tdRTXE7/y
427	KravchenkoVitalyiIevhenovych	KravchenkoVitalyiIevhenovych@school.ua	$2b$12$pNY2aVg41gMdex8/L3X6..Ssj8cAjW49x/vSPZyjI2Pav4tdHxu2i
428	KravchenkoAlinaOlehivna	KravchenkoAlinaOlehivna@school.ua	$2b$12$Kv9cwftk2r0o0VnFzqK5EeYw31V7f6xOWOmjXcE5DbI/umn9R.RBy
429	PetrenkoHennadiiRomanovych	PetrenkoHennadiiRomanovych@school.ua	$2b$12$TL.WuY4/RX4HW0qLxd3z1.YcTULLwg01cRJcABgI3yJLuE8YVavPK
430	PetrenkoViraPetroivna	PetrenkoViraPetroivna@school.ua	$2b$12$9zqDRk/OVf84JjVtmd7/f.xAIu9jJ28Fboob7apAkml2/itjeVeYu
431	DmytrenkoValentynaIevhenivna	DmytrenkoValentynaIevhenivna@school.ua	$2b$12$YDL2T/pWy6AAGRimmEqWbu.12TWEPzHE/x9uMEnD3sG15/uzMzY2.
432	MykytenkoMaksymPetroovych	MykytenkoMaksymPetroovych@school.ua	$2b$12$/fH2WaLQrzz8XcRf5rUYIuOYdJCmNm16CHFBDPlB2or9O5eyZwTxK
433	MykytenkoDarynaTarasivna	MykytenkoDarynaTarasivna@school.ua	$2b$12$7lqqds661OtzsiFr5fTT2O0pZpvLpI7vtpK/W7wx2uOPDKduN7PLq
434	LytvynIaroslavVitaliiovych	LytvynIaroslavVitaliiovych@school.ua	$2b$12$RUCzgfMxwjzuEqUDXQ74TOzUWbnEtUS10vslo9gYXCaqGNUQK03RO
435	LytvynSofiiaVasylivna	LytvynSofiiaVasylivna@school.ua	$2b$12$FSte1yCJTIbYvP2OaBZ3YulvRc6pvMjVa9nkojtkmU7hkyjZuEVmW
436	SavchenkoKaterynaPetroivna	SavchenkoKaterynaPetroivna@school.ua	$2b$12$W9OfX5yX.fTMIhrzvjg0f.3cWJdDVdlyP2XaHR75JoJv9JHHrfREq
437	KravchukBorysVasylovych	KravchukBorysVasylovych@school.ua	$2b$12$NqycAKOW.Ix7azRXXhalcu2ZjYQ/GhQN0Xqq2nfOU/aNaHXNjAOl.
438	KravchukAnnaHennadiiivna	KravchukAnnaHennadiiivna@school.ua	$2b$12$P3FOK3k54tk0U5uXwvucf.J3ClBHJbaNO532i2gjyD4/N73lO8I..
439	TkachDanyloVitalyiovych	TkachDanyloVitalyiovych@school.ua	$2b$12$X6j4khxsjE17ZLx.3obCmOdCDC1DWVbUZoV.cq72wwVfLpBlywzVm
440	TkachElinaLevivna	TkachElinaLevivna@school.ua	$2b$12$HImZCJ10OYF5FmMJ2z3cCOAYZsYi7csJZta1.JIUUTHHL5Gq9V6SO
441	ShevchukIevaVasylivna	ShevchukIevaVasylivna@school.ua	$2b$12$s7Fj4e4wMTSZnT3qYlh.jeDV9QItT/yGAMKXtMhY3OKZrIBCyCVaq
442	HryshchenkoRostyslavLevovych	HryshchenkoRostyslavLevovych@school.ua	$2b$12$dHMt0CYlgw2vrKIhrB0U0.AE54DpAhAARnqPGEuYIhU2X.boba9Ki
443	KotsiubynskaVadymMaksymovych	KotsiubynskaVadymMaksymovych@school.ua	$2b$12$pnZ9HGVsXEFAjhZuFdm0NOwzLOvTOzP7lqsUeTo9oDIF.y/d7eqE6
444	KotsiubynskaPolinaStepanivna	KotsiubynskaPolinaStepanivna@school.ua	$2b$12$0TERIm04c395gb07q2AYzuVuwi29I0acJo.RlCXCkWZPFQeWfwmAe
445	ChernenkoLiliiaLevivna	ChernenkoLiliiaLevivna@school.ua	$2b$12$1mhWbPDuOxKU5oaFEBg5jOXDf6tquYpApoZMJ2g/oSSWcY1wOJe3m
446	PolishchukKostiantynStepanovych	PolishchukKostiantynStepanovych@school.ua	$2b$12$dDuF9bT7gxianMHGWeYkt.GWk/p3eo0ujS.Tl4BRP/BGPLr3iV5l6
447	HryshchenkoMartaIaroslavivna	HryshchenkoMartaIaroslavivna@school.ua	$2b$12$7u3OcKT1yqlwsRmTZG0NweIqK1SvX6NfVUYPu8NYuoi2Z6Uq3IR1e
448	PolishchukIanaDanyloivna	PolishchukIanaDanyloivna@school.ua	$2b$12$9JwPvdNzIpl0CdBhAF11kOxxK8UD7YdElN2rEUx5pyseTwTAisIWu
449	BondarenkoIehorBorysovych	BondarenkoIehorBorysovych@school.ua	$2b$12$LBfo/lU4pF1t9AGUytzI4e56.VuAOEfdjrjWHZH0OFFIGBiHiPjGa
450	SoloviovaMelaniiaStepanivna	SoloviovaMelaniiaStepanivna@school.ua	$2b$12$e5g5LPQgkwJgt2jzRI4AEeIdT60oaBq3eGLzWajfSW5CIl2AdYvQW
451	BondarenkoMariiaArsenivna	BondarenkoMariiaArsenivna@school.ua	$2b$12$4mHJ2c0MhNn4jvd6nxT3a.7qeg953u721VVL9xAbNDCGn46P4N46G
452	MatsiukArtemArsenovych	MatsiukArtemArsenovych@school.ua	$2b$12$GuveWxod6HiukJIJPO1MlOgmYdtawD8o7BB0ljoO1502MR3fIllte
453	MatsiukIrynaVadymivna	MatsiukIrynaVadymivna@school.ua	$2b$12$OhQs7z8WTx7K5U/EDvRutuQY0Ad.sd4oClSmFw0c47V99P6RafxC.
454	IvanenkoOleksandrRostyslavovych	IvanenkoOleksandrRostyslavovych@school.ua	$2b$12$nTds9Ld36FcvN/skTsz7W.qGXQF.hlkht8nDVY4u5dd2UxQoQwnKG
455	IvanenkoOlenaBohdanivna	IvanenkoOlenaBohdanivna@school.ua	$2b$12$8gfsj0Y8IAMYXATJH3f2we4JQZ0EMlwjN3xMrcOzrdKW3WaTsXYXq
456	KovalchukPetroMykolaovych	KovalchukPetroMykolaovych@school.ua	$2b$12$2zizCsuikKX342JPq3vUSe6XZYywpZtpf4FvFWAJ0S4CCnnlXI.6.
457	ShevchenkoRoksolanaIuriiivna	ShevchenkoRoksolanaIuriiivna@school.ua	$2b$12$fnaDQRnoE6s9cviGAxqWZeId55IVPRNL9NcXxT1J.RmfFG7qR/TPe
459	TkachenkoTamaraPavloivna	TkachenkoTamaraPavloivna@school.ua	$2b$12$G/3P5J2cevgSRguRqceFiOeEWSyUumi2hMv44mQ4prwZ4Ov0VHyhS
458	HoncharOrysiaIevhenivna	HoncharOrysiaIevhenivna@school.ua	$2b$12$WFzWRYNZmB9F7fDBLiB2IeSmgaakwZNlBKXcsNwLuhu9fIOTluW1W
460	ShevchenkoOlehDmytroovych	ShevchenkoOlehDmytroovych@school.ua	$2b$12$1QCJ/vIiEfKYGi7zBJ26Qu1EnDmZneWT7to4/wrVC8WOD8nPWa4iC
461	PetrenkoDanyloVitalyiovych	PetrenkoDanyloVitalyiovych@school.ua	$2b$12$0EohF86husJA9yxpkbG0VOWl7s6.ZymVduIKaFquFYYS5opdaImzS
462	KotsiubynskaOleksandrRostyslavovych	KotsiubynskaOleksandrRostyslavovych@school.ua	$2b$12$d6PInxZS1TeCP8G4z5X9teQJDrMbzvx1QeiAcU.eKAe9FGGDsXJHK
463	ChernenkoTetianaKostiantynivna	ChernenkoTetianaKostiantynivna@school.ua	$2b$12$OKz0A8kC6nTnStdkmSsif.wdx7.YSYzraIOztAzcFsdu37DB6op0i
464	ShevchukFedirDanyloovych	ShevchukFedirDanyloovych@school.ua	$2b$12$jaxfZIVb8waA4j7YSN9zoeHYqKH492UQac4NGAy8R5JRoEF8qtoKG
465	LevchenkoKarynaArsenivna	LevchenkoKarynaArsenivna@school.ua	$2b$12$R16C144dE8jfogk14r4CXekOVd1cQibFftmGE5FNBgo5lQct7sEeG
466	DemchenkoAndriiBohdanovych	DemchenkoAndriiBohdanovych@school.ua	$2b$12$Qibz0XzFkvC6j.bR.rhZYOQYBdVCjw1vJoDYhG6qI24H0Z.p29v1m
467	DemchenkoHannaIehorivna	DemchenkoHannaIehorivna@school.ua	$2b$12$sYaH/tzzQ83aHxLucUZAFOtqDJ9ww.81tRb7EvCmT194vxzEIJp0e
471	TkachenkoHannaRomanivna	TkachenkoHannaRomanivna@school.ua	$2b$12$LdLdMaoVD8TAXo2E707VWuTSV/TPn7hhUJA.O8kXLOb/42X3Mi5.i
472	ShevchenkoArtemSerhiiovych	ShevchenkoArtemSerhiiovych@school.ua	$2b$12$L12.djihHr2Euwo9rdIIfeN2BU/qMs/P7hyQQJcxVlZF35mlgyZQK
473	BoikoVolodymyrMykolaovych	BoikoVolodymyrMykolaovych@school.ua	$2b$12$WOHNeqwB1tJ8zOE40GbOyejzpUAQDG1yEby5/hJPFyiPSDeqbuVk.
474	RudenkoOksanaPetroivna	RudenkoOksanaPetroivna@school.ua	$2b$12$LXP8LdHGS5mNP7T3gOcp1.H5BrEsn/YYtDncikpsyqDuhSEY1uzJi
475	KozakMykolaIevhenovych	KozakMykolaIevhenovych@school.ua	$2b$12$TGmwYpaVlzYwN8KGmWNJn.pRCUECTNknLOTBKp8Y5coFFM8TnAcU2
476	FedorenkoPavloOlehovych	FedorenkoPavloOlehovych@school.ua	$2b$12$fxsHw9q8YGKcBJhKGoGscOEe2eSxH6F/GJZRIPbcPV3fEzR6QWfVC
477	BilykNadiiaTarasivna	BilykNadiiaTarasivna@school.ua	$2b$12$g6C6h6FN/QCD02iVbPi0xeSE40vjIn4r9dX1LlQeaMpfvJpkWsJO2
478	KravchenkoLiubaVitalyiivna	KravchenkoLiubaVitalyiivna@school.ua	$2b$12$9e/kV409F8O.rWDSBOFDNeqzp8bwKblGywYVTYdE6h1BTZS4bGUeG
479	SydorenkoIevhenVitaliiovych	SydorenkoIevhenVitaliiovych@school.ua	$2b$12$vtxtuvFSCwuYcqs0d7FR3.XAur/OSwvxNzlsmf/2ZrV4IfGeiXuvu
480	PetrenkoOlehVasylovych	PetrenkoOlehVasylovych@school.ua	$2b$12$QaLCs0pyQtqDPBvvOqtR2em/FCKWHwk6ATSfaeL/JgHSDpmPV7/yS
481	MykytenkoVitaliiHennadiiovych	MykytenkoVitaliiHennadiiovych@school.ua	$2b$12$L5LzkLDoLSC5FwqVWqMfTe8k20JbzLOtyFt1qqjEk9GxJd.Be/2bS
482	LytvynValentynaIaroslavivna	LytvynValentynaIaroslavivna@school.ua	$2b$12$rUpPCZw0fU685Hpm4zW3CePTX7YqWDiMbfjeta.dNZ8LPIdHmUCBu
483	KravchukOrysiaBorysivna	KravchukOrysiaBorysivna@school.ua	$2b$12$.xYpZYU.Dio8NcGzRI14ZOHdTZ.T74gzUugNrtRU0fjBEgxd7B/fy
484	TkachHennadiiStepanovych	TkachHennadiiStepanovych@school.ua	$2b$12$.UfjppN9gIri1E8mqT8gBeeRu5YQF.RGNMTgKC8LfyTGdAleRKi1C
485	ShevchukAlinaArsenivna	ShevchukAlinaArsenivna@school.ua	$2b$12$mSDhS2hgdubxRyfRGGOFnOhk.kKLuY22SrPAX13mZMt3iGfcva0IC
486	HryshchenkoMaksymDanyloovych	HryshchenkoMaksymDanyloovych@school.ua	$2b$12$QTs13PxLsaZHNEQ/BaABNeMesI.rs.q7nOyRDx9UX1NfhKzBuyQ7K
487	KotsiubynskaIevaVadymivna	KotsiubynskaIevaVadymivna@school.ua	$2b$12$CsOuCiBnJnxvWhDdc90LXu1KFWpWqHCp0QDDpvm7qMWbt6LDAWAd2
488	SavchenkoVasylMaksymovych	SavchenkoVasylMaksymovych@school.ua	$2b$12$xoE5d4M3Qr/cOcIVVo7D4O1rhGkR5rriX0ylt/s6ICESdTZ7Jhm1e
489	ChernenkoStepanRostyslavovych	ChernenkoStepanRostyslavovych@school.ua	$2b$12$QC2hvTP0d4RbGc94wLzb5uDMyJ1NEHbs3QwytxamwhXivqGpVf5XG
490	PolishchukSofiiaKostiantynivna	PolishchukSofiiaKostiantynivna@school.ua	$2b$12$kb7A55mbOf4tsNV/MhrD6uYdlQ0ImlO9J9uXkv5DE0abe/ETbzxfK
491	BondarenkoDanyloBohdanovych	BondarenkoDanyloBohdanovych@school.ua	$2b$12$bT7SGC5ZB62DmVDU/gmp6ePOabvORABKk8uFbej74c27Zci2eJk/O
492	SoloviovaAnnaFedirivna	SoloviovaAnnaFedirivna@school.ua	$2b$12$D/yXSXyMeAWpAmZXgx4pFObvKtMOkb5TQ6iO1ef2bemWsCaEGqZv.
493	LevchenkoBohdanArtemovych	LevchenkoBohdanArtemovych@school.ua	$2b$12$TSvumgJHKeGLabiB.BGiJ.4xCD0CkvVpNggndNmDZ4G3kzcOkr5e6
494	DemchenkoPolinaAndriiivna	DemchenkoPolinaAndriiivna@school.ua	$2b$12$8zUv3An/8wAmaHhxIR3yi.oVyX9mJ1lADLyviI7P0IVf6y9WsuJB.
495	KovalIehorVolodymyrovych	KovalIehorVolodymyrovych@school.ua	$2b$12$xy.ALes6LtNnucdVfYqqeOnIFQPQ30ZkAEOV5.Peky6yAMMrIvUYK
496	IvanenkoMelaniiaOleksandrivna	IvanenkoMelaniiaOleksandrivna@school.ua	$2b$12$DzbIcHYkl9F.ljTzDtKx5OIH1DJpvYb9xNeMUzAEfOojKEpclebFi
497	KovalskyiArtemSerhiiovych	KovalskyiArtemSerhiiovych@school.ua	$2b$12$iznRIY8XGHx.fmGkAnjVeO4738HFwf/q6uB.e3Ubc7Nr8bDivJsbO
498	BoichenkoNataliiaIuriiivna	BoichenkoNataliiaIuriiivna@school.ua	$2b$12$gOq/Mj1Wajrzq/XPR/Rl8uuHwyRFQ/4roaMaviQnpbELUMNsaexKm
499	PavlenkoVolodymyrMykolaovych	PavlenkoVolodymyrMykolaovych@school.ua	$2b$12$0ryNVlXjcHlLwSngyzqCuuAbPQK7YKNLEySZblS2Gup1s74fsqRou
500	MartyniukMykolaIevhenovych	MartyniukMykolaIevhenovych@school.ua	$2b$12$pqNpKck8VmVvtCu8rKDheOkahNmTRy2GbytDbrN4kj4LgHJzdMDBC
501	KlymenkoSerhiiPavloovych	KlymenkoSerhiiPavloovych@school.ua	$2b$12$jvFNKrsRZ2T3cNwm7SA2P.9IfFstlSvxgazCMuc86E4n/h0bL1XiW
502	ZaitsevOksanaPetroivna	ZaitsevOksanaPetroivna@school.ua	$2b$12$l/5jkywFbxyRhAezH1aGYOajfF8XsMEeuarE7DP96b873W8N445Pi
503	KyrychenkoHannaRomanivna	KyrychenkoHannaRomanivna@school.ua	$2b$12$W4Uunmr1vbD/mxSObnKAnO8L6ZjjbWRNTywJ4axbhQH2Fg/5UF1SC
504	MartynenkoPavloOlehovych	MartynenkoPavloOlehovych@school.ua	$2b$12$oUrrTIQIH3ipRgqUs1oE6uLvgX/yXT18ZNS/6gY/hs0LPijbtwHGS
505	OstapenkoNadiiaTarasivna	OstapenkoNadiiaTarasivna@school.ua	$2b$12$wn6GTeJWm8dHClkUMQc6v.hYIBWuGHUlFewmpZP2zCf12hm8W/nti
506	PylypchukLiubaVitalyiivna	PylypchukLiubaVitalyiivna@school.ua	$2b$12$yabBGtpCqTPSNx.HfShHy.IAJ1HAaym2zy6J0gZ/eE4vhYAWM/gjG
507	KuzmenkoIevhenVitaliiovych	KuzmenkoIevhenVitaliiovych@school.ua	$2b$12$SoDCnN.VpPd3KQY/fphyB.60Y.ul7/08rtvexGL8MGyE7EeDYDKNu
508	SymonenkoOlehVasylovych	SymonenkoOlehVasylovych@school.ua	$2b$12$bGPg.Y5CjdULtClTDygsZOKtKyc970uSd81vgIQiBMqJRHT.sgXvK
509	ProtsenkoTamaraLevivna	ProtsenkoTamaraLevivna@school.ua	$2b$12$ekMxLJxT3caRG7CoGsuEeeV1/UkgLdS5PL6Zx/Bofm5DtfD1p5jj.
510	OleksiienkoVitaliiHennadiiovych	OleksiienkoVitaliiHennadiiovych@school.ua	$2b$12$scIQeQ/pn0H1q8Mpdkzz8.YATrU1saKriM/ZGalMzt2dz/8Z5zSLe
511	NechyporenkoVasylMaksymovych	NechyporenkoVasylMaksymovych@school.ua	$2b$12$8W1vEzCeB67srnruKcYBoe/oleQ/g9qMG0y5gqkrwFGpWAK1hFQd.
512	MiroshnychenkoOrysiaBorysivna	MiroshnychenkoOrysiaBorysivna@school.ua	$2b$12$XLbaa6TqxW5v7Ac83/6IV.a/GXCR5EWoQNyFn4G/dk24XQUvbSYHK
513	KovalchukAlinaArsenivna	KovalchukAlinaArsenivna@school.ua	$2b$12$X/ie4njnDVThvn2rPGwr5O/Mp1ZkkeTXX4j10jj12GXcaGwfyf8K2
514	BoikoMaksymDanyloovych	BoikoMaksymDanyloovych@school.ua	$2b$12$Adrp/coFWA0AFF9W4PU8V.K/aSPfqDkNo4yv6tEcFQi5TmnEl9oSS
515	HoncharIevaVadymivna	HoncharIevaVadymivna@school.ua	$2b$12$qi637E7LmOeNOfBEFPvbJ.Im9.tXPc9ldnDVRFmNM1QoQLdrfNbza
516	MelnykStepanRostyslavovych	MelnykStepanRostyslavovych@school.ua	$2b$12$Z3KrGFbUnWTMkYWdgNlg2epcJg7OYpKpnekTjMQROBqky//Ia7Gge
517	TkachenkoSofiiaKostiantynivna	TkachenkoSofiiaKostiantynivna@school.ua	$2b$12$YGWnTCCVeF2yRzgrTWbuKOxS6gi3fM1d5pxUx90bYyJjFxFMUPKce
518	KozakDanyloBohdanovych	KozakDanyloBohdanovych@school.ua	$2b$12$zmx/lJdXk4PBgn0IT98qL.9CK51NwCwhLTvm2E3I7.iK6FK1vwPMC
519	FedorenkoRostyslavIehorovych	FedorenkoRostyslavIehorovych@school.ua	$2b$12$.xrdx/SyM.dsPri762SllOR3KBbBr4TfxUXq13bxL6OwiS3764Fzi
520	BilykMelaniiaOleksandrivna	BilykMelaniiaOleksandrivna@school.ua	$2b$12$kJdcR/VAITlSfte0.u3i/.PLPz80dbjoWY.T4MTDmix4SP5vO420.
521	SydorenkoBohdanArtemovych	SydorenkoBohdanArtemovych@school.ua	$2b$12$yM4bz/N1JMDGiNcM17MIheB.ioTKLHrp6J1gQfi82SBdmw3vjDQyq
522	RudenkoAnnaFedirivna	RudenkoAnnaFedirivna@school.ua	$2b$12$mtVOIpicdQpA5TCbLVPnL.5.I7VZo8zIEo3rq6dzBX37abCMBkIWG
523	KravchenkoPolinaAndriiivna	KravchenkoPolinaAndriiivna@school.ua	$2b$12$1hPqkupp7p6qwmi8PnkfYejLi13ILDCGfiTJLi2vpkBk8lLRsHyXe
524	PetrenkoIehorVolodymyrovych	PetrenkoIehorVolodymyrovych@school.ua	$2b$12$BZk27X7aQesafiBHCpmTjug7cFTCaYhMFlhaUNVtCN652tEMdKSzm
525	DmytrenkoIanaDmytroivna	DmytrenkoIanaDmytroivna@school.ua	$2b$12$MxBLAzyrsoRMVFNg0p.Ndu2eBCDSzDLmrsrCDOE1NrVpZxJk9SF5e
526	LytvynNataliiaIuriiivna	LytvynNataliiaIuriiivna@school.ua	$2b$12$yEfQb/HWPjryzVoY4HKDCOT.UyNDvJH7q9HojzwFJXSuLvqaIFr0W
527	SavchenkoVolodymyrMykolaovych	SavchenkoVolodymyrMykolaovych@school.ua	$2b$12$X2qBiRnpxKmMBoxeqVcZlOjWJ/0LjBgO64Yrx2rjSC0gdarCgLuQK
528	MykytenkoArtemSerhiiovych	MykytenkoArtemSerhiiovych@school.ua	$2b$12$wCjx.Z1qFeiVeohaakCoC.P/YeZxqAr.USDHmiSeN7PyKQPLxXj6q
529	KravchukOlenaIhorivna	KravchukOlenaIhorivna@school.ua	$2b$12$KQs.Rt7CDsdisaENBfJYQOUQy7AP8lCxgAvvrp2DSevNSukd4TFHm
530	TkachSerhiiPavloovych	TkachSerhiiPavloovych@school.ua	$2b$12$JY8qrm5tAjgpMILAm/134OQ1EV8ecCZqghBxbRiAY8Y5dg4HdUvyS
531	ShevchukHannaRomanivna	ShevchukHannaRomanivna@school.ua	$2b$12$tVqeWnHGywRnHNjyCWpD2e7ZeKhZUmS4IX9bT1fzhfESJ85ewu.o.
532	HryshchenkoMykolaIevhenovych	HryshchenkoMykolaIevhenovych@school.ua	$2b$12$lmmVitK5.VqEWgToQ9r.QOAZZ47hZrDWjVwvsQJKLWC51DvA76p5y
533	KotsiubynskaOksanaPetroivna	KotsiubynskaOksanaPetroivna@school.ua	$2b$12$jxHjXXwdPSPykh50AEjeY.6fWfaAObVmmeneBK4TPaP.KK62rsA.a
534	ChernenkoPavloOlehovych	ChernenkoPavloOlehovych@school.ua	$2b$12$VT0fAw./Ku606CdlSgv5VeEMiK4G432B4jDnO6G5mWllws8XckskS
535	PolishchukNadiiaTarasivna	PolishchukNadiiaTarasivna@school.ua	$2b$12$wSoBwaqqPzVUsKnoNerSzO4wqeFvaT2slwcxxHwEAuE8.34vVfM1a
536	BondarenkoIevhenVitaliiovych	BondarenkoIevhenVitaliiovych@school.ua	$2b$12$NCdssx0mvL3bV6Q4dfSwBO0YfhRZWJ/fS8HD2CuH32w7SLK5Ktyt.
537	SoloviovaLiubaVitalyiivna	SoloviovaLiubaVitalyiivna@school.ua	$2b$12$77tk8S2OrpU.GnG75M21Fe4f5TwIqROfThUAjMn4YBZ5Jk2V8IRC.
538	MatsiukOlehVasylovych	MatsiukOlehVasylovych@school.ua	$2b$12$QcdcFzAOt271QP32l8CQdObKpGJTLx7ZzR5aJo4kdQyLmBKbDZkJu
539	IvanenkoTamaraLevivna	IvanenkoTamaraLevivna@school.ua	$2b$12$31TVy.xJcylmW257usnRlOo6vkxF8Kcw68CW1kj059rJJU3T8bZKK
540	DemchenkoValentynaIaroslavivna	DemchenkoValentynaIaroslavivna@school.ua	$2b$12$Fy9e9QIusHSz5ZIoMBu5z.7E17ClYnNv1Mz5U42ORImerNd..nbhq
541	LevchenkoVitaliiHennadiiovych	LevchenkoVitaliiHennadiiovych@school.ua	$2b$12$6fv.QQkM7LgIY47fmDM13.ooCM23lo6tePYN0qQpow3AHT5UyWIp.
542	KovalVasylMaksymovych	KovalVasylMaksymovych@school.ua	$2b$12$pbYs0kwxyFbzD3vzlbBK0OZSv/o8jhxyXDSymi6IvCBHY7scqGnDm
543	RomanenkoOrysiaBorysivna	RomanenkoOrysiaBorysivna@school.ua	$2b$12$HPZiK2H7IDISSy3hWkx6Au9OOhLqw2/ANq5IXauO2C7fmTgQJD/JW
544	KovalskyiHennadiiStepanovych	KovalskyiHennadiiStepanovych@school.ua	$2b$12$ahusMaD2akElgExh/0dxPebr8H1lLLW2sCwP3X7SxoSyMqWbx8FCm
545	BoichenkoAlinaArsenivna	BoichenkoAlinaArsenivna@school.ua	$2b$12$bh4Y6dcoRMhRERu8/YgYJ.CZ/ynUo5KRZNwl4gSkFaR7FbSEoyOSm
546	PavlenkoMaksymDanyloovych	PavlenkoMaksymDanyloovych@school.ua	$2b$12$t4OhRivbFMEJ.zbb2K3yGeg9DKcyu3s6nec1Yi0/ifIlvbN8EL9fm
547	PonomarenkoIevaVadymivna	PonomarenkoIevaVadymivna@school.ua	$2b$12$8/Fb7FFTxMfQKecp/CHWNucpAvhulFus07vEMKk8nN3.tsxZm9GXO
548	KlymenkoStepanRostyslavovych	KlymenkoStepanRostyslavovych@school.ua	$2b$12$F/21J1drltwinNKU7PeIeOm75rVJDSwUH36hA7fpc8AbE2NMpNQDy
549	KyrychenkoSofiiaKostiantynivna	KyrychenkoSofiiaKostiantynivna@school.ua	$2b$12$kGQvgmXaIF8aG8WSKGzZoOowWUdeqazF3EGxX7ndUFn3bVdMcRWWG
550	MartyniukDanyloBohdanovych	MartyniukDanyloBohdanovych@school.ua	$2b$12$lu8dX.2xlFQdc0/j0NXpaOSlyzOsbEnv3PdiA0aPIRZ.ciOS36CCW
551	ZaitsevAnnaFedirivna	ZaitsevAnnaFedirivna@school.ua	$2b$12$PxN53wxXZTKrb.qIX0dxfuQXw1zKFV6oa2QZb.1xJKRhVWgJGcy7u
552	MartynenkoRostyslavIehorovych	MartynenkoRostyslavIehorovych@school.ua	$2b$12$Uk1tFxLZf6K6QjEuLW9EROkkXUY1R5/cuplNYi0dcos3yg.nHXhxi
553	OstapenkoMelaniiaOleksandrivna	OstapenkoMelaniiaOleksandrivna@school.ua	$2b$12$f/osPxFmNOd5GIEDKCBXOuFfyTkxVEcDJWcFKQCslSicKORJQWeH2
554	PylypchukPolinaAndriiivna	PylypchukPolinaAndriiivna@school.ua	$2b$12$3pT5wGmMqIFam.wnQu1HPe1eOY6B0ZZmwMskOyjFVYpOuAC1pOtka
555	SymonenkoIehorVolodymyrovych	SymonenkoIehorVolodymyrovych@school.ua	$2b$12$Wc58kE/rU//ZOiRqvT0iO.wcRzHhnjLVF5hztJyVuGqrUGHZoJkce
556	KuzmenkoBohdanArtemovych	KuzmenkoBohdanArtemovych@school.ua	$2b$12$bC8sC2RmEP5Du3vFcRBZPew60HjP83mzSUa2gf8jsv8V5EReK6xoi
557	ProtsenkoIanaDmytroivna	ProtsenkoIanaDmytroivna@school.ua	$2b$12$/dC0FQZn6pWYSVpbA/LWDOo7gVp7qMCE1PGWPRTogmGJ6qO6gp9jW
558	OleksiienkoArtemSerhiiovych	OleksiienkoArtemSerhiiovych@school.ua	$2b$12$Xb79NxoMkeORrUnJpa0vcOThwtJ1SLhrmsHROO6BV94Pzd4Uh1f..
559	KorsunNataliiaIuriiivna	KorsunNataliiaIuriiivna@school.ua	$2b$12$0CXnv8GIUV4kTCo9LroWD.yuRw614STkip8YjQqHgbGzjaYMik7Dm
560	NechyporenkoVolodymyrMykolaovych	NechyporenkoVolodymyrMykolaovych@school.ua	$2b$12$9JQjN34FddHRIT6GvyakielEYAITFmS.Q6ci.I4kaOhk2Lv9VLT9K
561	MiroshnychenkoOlenaIhorivna	MiroshnychenkoOlenaIhorivna@school.ua	$2b$12$wTMH71k7fLc7W16kBJl8/um.uZDQSJyav1hbjz.i..P3HK7xYcivC
562	ShevchenkoSerhiiPavloovych	ShevchenkoSerhiiPavloovych@school.ua	$2b$12$NzqRaivKILkmgMjjPqdqUOH3nhTDy7NSEE2cmpg7XrfNk/wfnOSQm
563	KovalchukHannaRomanivna	KovalchukHannaRomanivna@school.ua	$2b$12$lUKPZMdE5pDgiICUiWRkkeoQNsCksFfFRP/Fh.cdJ9qAAztLd91sq
564	BoikoMykolaIevhenovych	BoikoMykolaIevhenovych@school.ua	$2b$12$IO1Jt1RwHzYMUzEc1VVnceTSYnVipuxxepFjqaqtrvVFGJNA3DXLu
565	HoncharOksanaPetroivna	HoncharOksanaPetroivna@school.ua	$2b$12$5NtNT26u1VnG3PNuC75cp.gYUnxGvi/bzi9/d/Z8AvuqArScT4V..
566	MelnykPavloOlehovych	MelnykPavloOlehovych@school.ua	$2b$12$KZ1Sjc0d1LKNoAzjCwfhIeeESdwxBrmI9P3WPtyWB6lGX1ZQW.zPS
567	TkachenkoNadiiaTarasivna	TkachenkoNadiiaTarasivna@school.ua	$2b$12$Vu8kT7TP2N.EpyDzdW1N2.FkiJe5M.JywcjbdaoZ8cfMXIHSMX0Oe
568	RudenkoLiubaVitalyiivna	RudenkoLiubaVitalyiivna@school.ua	$2b$12$9nkw9Wkxr8lZmt9J/uSAs.M9dRj7Vuq6FnTasb6vBS8g2PcD9/ATq
569	KozakIevhenVitaliiovych	KozakIevhenVitaliiovych@school.ua	$2b$12$fn50zKyXJmN5StT3R8FUDeSyxIfGylO6SJgIQfK7aJgWKcXaKJx0K
570	FedorenkoOlehVasylovych	FedorenkoOlehVasylovych@school.ua	$2b$12$KKyAQjnzzGNOIq00/5h4LOO7zFhUsERfwETn1ob4eAqSO4Dd6ZCay
571	BilykTamaraLevivna	BilykTamaraLevivna@school.ua	$2b$12$CK8tWlY4A1oFKfu9CEswPuYLlxx0Um9TaOeqe2V581L6uCa/mV4gS
572	KravchenkoValentynaIaroslavivna	KravchenkoValentynaIaroslavivna@school.ua	$2b$12$ETWNvyzk2pgxfNpfIhJVY.vbwI2.KAYpgSIRIuEKqC6IJAVvV2PZq
573	SydorenkoVitaliiHennadiiovych	SydorenkoVitaliiHennadiiovych@school.ua	$2b$12$9FE.JPsnta0ik.FZkjMIE.NOgslj/qgA3VeYhgXBOOnLq39rTP1pm
574	PetrenkoVasylMaksymovych	PetrenkoVasylMaksymovych@school.ua	$2b$12$C00fWAqwHHe0E1M7V8xKCO.CurAAz2kBvCkKc8r34sPp/Iv5m1G0G
575	DmytrenkoOrysiaBorysivna	DmytrenkoOrysiaBorysivna@school.ua	$2b$12$fgDVBfIZSVtSWQCJFmV.veXJ4HgRLHuEwRxtp5STuSqxjoHsYDW56
576	MykytenkoHennadiiStepanovych	MykytenkoHennadiiStepanovych@school.ua	$2b$12$.UplHFcEZT35yhKSkzow1e6yBbb/FUtVMSJvRlW./EM3hQzKiFUkC
577	LytvynAlinaArsenivna	LytvynAlinaArsenivna@school.ua	$2b$12$AsD1eMQ0phSusqnKHTL0DO12PwmIPdmXTVP1C/LIwosXpvBW6bTqS
578	SavchenkoMaksymDanyloovych	SavchenkoMaksymDanyloovych@school.ua	$2b$12$g3ke7bUBbTHMi38oIa8h4.9gKM683VbNeqF.tATlVb8Qgjt80Ob.C
579	KravchukIevaVadymivna	KravchukIevaVadymivna@school.ua	$2b$12$sZU85/SgBchijWUKPJ0Ag.B6FucHsPL15mQUVDHxTfI1UgDrCKrxu
580	ShevchukSofiiaKostiantynivna	ShevchukSofiiaKostiantynivna@school.ua	$2b$12$XfxwDEfOC2R75q/3lN8EEOCD1gYfD.atvjrnU1hFEqaXm6mvwjXFW
581	TkachStepanRostyslavovych	TkachStepanRostyslavovych@school.ua	$2b$12$l3XHhLTdydL0b1t137A7a.mYzEOEjUjgOypThF3/ZPmgheoAH9ILa
582	HryshchenkoDanyloBohdanovych	HryshchenkoDanyloBohdanovych@school.ua	$2b$12$5s/DMKYbLUsp2zvYdTtLMunJ64H.457bv0M7codHsMsARQTU8NlXe
583	KotsiubynskaAnnaFedirivna	KotsiubynskaAnnaFedirivna@school.ua	$2b$12$MiDn4XRMqachxj0JnShrfu39Vta0hWw2TfkMiDjVOcRHZEaMMIDwy
584	ChernenkoRostyslavIehorovych	ChernenkoRostyslavIehorovych@school.ua	$2b$12$jFbO/UvzDzzAPLuEcT5l5.HmbXaNzHbQ4qtfQl.IzO5uxxRgzLJiC
585	PolishchukMelaniiaOleksandrivna	PolishchukMelaniiaOleksandrivna@school.ua	$2b$12$ID7HiuCM3Jtw0mms2nKX6O5J1rQBRYGvABGHSG/GiDuQs80K/nYMS
586	BondarenkoBohdanArtemovych	BondarenkoBohdanArtemovych@school.ua	$2b$12$ejWrRb07YtJGBf5XAG7toOHPl4t00xwPic5BcUEOxo.NdZN4rIx06
587	MatsiukIehorVolodymyrovych	MatsiukIehorVolodymyrovych@school.ua	$2b$12$b2nL4ngsXoua0RKgzEX0OuY/cxeTApP0AkysU38lW9pLUByIMiShG
588	SoloviovaPolinaAndriiivna	SoloviovaPolinaAndriiivna@school.ua	$2b$12$gwmUrtxYqcKd4ikYu3dW/O4sLJSqEykBk/QwOy/qLc5YU1shAEGCy
589	IvanenkoIanaDmytroivna	IvanenkoIanaDmytroivna@school.ua	$2b$12$AZ/0DCj.iFeKcrgZzfwo..eRn1AYRJStqE9S4F3687C3/DTq4EQQK
590	LevchenkoArtemSerhiiovych	LevchenkoArtemSerhiiovych@school.ua	$2b$12$5tWW9oT1NDYe2qeh.ayXruxCRzKvxC42qIX8TBcJhEORdmpzCZH2i
591	DemchenkoNataliiaIuriiivna	DemchenkoNataliiaIuriiivna@school.ua	$2b$12$6.8deo4gB8W0Ym92XMOBGO5PH3xH9Kes6hAGTRVZiU99zn8HNgyke
592	KovalVolodymyrMykolaovych	KovalVolodymyrMykolaovych@school.ua	$2b$12$H8yM8P8rqqaXz.EPaJhPieSi9GTZiQpPYHvR1t.7nc8ZDUbvyJsSy
593	RomanenkoOlenaIhorivna	RomanenkoOlenaIhorivna@school.ua	$2b$12$hQ77LJb/GhHnx3Ms8NiCful.ZyHuRzRuec6DqpxG2/38veV5khvNa
594	KovalskyiSerhiiPavloovych	KovalskyiSerhiiPavloovych@school.ua	$2b$12$sdhhq.4Hn7LaWWvFKtzoK.93atKJjORojozwCJ1E5JfDJR69jsz3C
595	BoichenkoHannaRomanivna	BoichenkoHannaRomanivna@school.ua	$2b$12$sjuDpW2zBXiodL30PjUkBOuGsLOwEjMzRmu4EF2Z7GXeBpGcvUW/W
596	PonomarenkoOksanaPetroivna	PonomarenkoOksanaPetroivna@school.ua	$2b$12$nUgbhnMyhBau4Ci3Zjv7jOjV3M0oamtCIR7WLLnnJj1mxPoxvvhNa
597	PavlenkoMykolaIevhenovych	PavlenkoMykolaIevhenovych@school.ua	$2b$12$rQdZf4hnLvKq.iu1GDPJmemFjS84E5XJcdR6y9xoDHId.2yNvJ9GS
598	KlymenkoPavloOlehovych	KlymenkoPavloOlehovych@school.ua	$2b$12$AbbjZnx0glphstQ.dJSJb.xtZ09YdXO/8tRspsLZdJ1UTQDVWm0ZO
599	KyrychenkoNadiiaTarasivna	KyrychenkoNadiiaTarasivna@school.ua	$2b$12$ztYbuAL6mdFFzl07TiRRXuUPgVCk9WqpGl1k3shm8OqZwMoeQ3XZu
600	MartyniukIevhenVitaliiovych	MartyniukIevhenVitaliiovych@school.ua	$2b$12$86Jo9WMK6gRGPHTHo8e7CeB8LHSISSZxJG/.QnepJFIoz7poNJSXW
601	ZaitsevLiubaVitalyiivna	ZaitsevLiubaVitalyiivna@school.ua	$2b$12$cfrV4/H7iwLuLnbNa/sgCel1oqr3XJb57P6kWIXtyECRjCEWTncnO
602	MartynenkoOlehVasylovych	MartynenkoOlehVasylovych@school.ua	$2b$12$sT29vuAvbq7jFrqSGmKh8u6eSHiWbChQC0c0v3k/FQzPBTU2.PeGq
603	OstapenkoTamaraLevivna	OstapenkoTamaraLevivna@school.ua	$2b$12$c5r62B8jIlUyaFgVb//BJu/3ljiLZ6GVxy8zl8sy6JRi3MaANQhim
604	KuzmenkoVitaliiHennadiiovych	KuzmenkoVitaliiHennadiiovych@school.ua	$2b$12$RJHeBBwPZOkvmDid2x4nh.KkuIX03yLREqoub99LdSRnfrRxPyyKy
605	PylypchukValentynaIaroslavivna	PylypchukValentynaIaroslavivna@school.ua	$2b$12$zeRefPCGmZSRn7gNIjhyGuvHTPWAEB6c8Kc.kfTlqgDbdUSov/rTe
606	SymonenkoVasylMaksymovych	SymonenkoVasylMaksymovych@school.ua	$2b$12$XgCf5kWkRoJhXQK4SPySR.NH95U6gW0UrJ.liT8tmOAPhdKC.rjwC
607	ProtsenkoOrysiaBorysivna	ProtsenkoOrysiaBorysivna@school.ua	$2b$12$f1zGv36HUcvXEYw/Hk5E.Og6KnqqzQMbilHx9Juk99f3vtvN/xrU.
608	KorsunAlinaArsenivna	KorsunAlinaArsenivna@school.ua	$2b$12$lBJY0AzR4kco7EtrXqGYr.ZuCnAi5YE3WjEzdU/M2w9qB6URMrphq
609	OleksiienkoHennadiiStepanovych	OleksiienkoHennadiiStepanovych@school.ua	$2b$12$P/5iKGeoG9aGKpAEdFLulOBOuCSlttLfUU5uNOPjKLCElyYgrsZCi
610	NechyporenkoMaksymDanyloovych	NechyporenkoMaksymDanyloovych@school.ua	$2b$12$CtliOO0yvyxMfukaswaoB.zBdk28rpiTu.ZCUQE1TgtXNd0mAqVla
611	MiroshnychenkoIevaVadymivna	MiroshnychenkoIevaVadymivna@school.ua	$2b$12$sfjXv008mcgh08Q6ybMmSeuYBEs7.oXXuemHbWCv0ay9lEDQos2Ju
612	KovalchukSofiiaKostiantynivna	KovalchukSofiiaKostiantynivna@school.ua	$2b$12$YpjLlDByn6fUx0wwzwh2EOnh5gtzthVlXRJs89qqUbxB0Sp6vPEme
613	ShevchenkoStepanRostyslavovych	ShevchenkoStepanRostyslavovych@school.ua	$2b$12$fncCrzy37HEYJh.E7nQ5A.OXL5v.bf6q2vJugtJDz.FREZiWD5HHe
614	BoikoDanyloBohdanovych	BoikoDanyloBohdanovych@school.ua	$2b$12$koJVUyBwSg.i197.53UmR.84qUYonjb/AYvlIu2msMSUSri5hD1mm
615	HoncharAnnaFedirivna	HoncharAnnaFedirivna@school.ua	$2b$12$lbdWk9taaRYlGfUcjhrtoe5FQUuov8kcfW2DvduhUFZo7jYvrU7JG
616	KozakBohdanArtemovych	KozakBohdanArtemovych@school.ua	$2b$12$s8CBwqeY2tdlueMg.rRW4eA1IGB.gwvbWRIUpAnKDrsT7VZ//pj7y
617	TkachenkoMelaniiaOleksandrivna	TkachenkoMelaniiaOleksandrivna@school.ua	$2b$12$bMme0Xly3D1xyRpjJXRfT.rwCkw/Rui9m/D4mC0uMrxmnsCG0qvCu
618	MelnykRostyslavIehorovych	MelnykRostyslavIehorovych@school.ua	$2b$12$/gMKZ5CLUeIpW9cUWg7RWODIounpVILvRuar/1uBUEjIncRxtB/Ha
619	RudenkoPolinaAndriiivna	RudenkoPolinaAndriiivna@school.ua	$2b$12$1wxdBCmZZ.aJCNrBUJ6Qk.5a8kXMyMwP6OGyISNQh4QC72uUzb4Lm
620	BilykIanaDmytroivna	BilykIanaDmytroivna@school.ua	$2b$12$wL0t7NsZ2.MoxdGPwkAQ5..LcpPab6V9BbKuem7z/Zz6uyZxcm9fe
621	FedorenkoIehorVolodymyrovych	FedorenkoIehorVolodymyrovych@school.ua	$2b$12$5/H4ffYeicT4r81emzilX.ekd9WhDVCC2IMSbKlYNQHslhrwqZ.S6
622	SydorenkoArtemSerhiiovych	SydorenkoArtemSerhiiovych@school.ua	$2b$12$S3pGfWHzwWkZpxy/MTjKmeqOBZDau7vFYebP/d0p8Lj6E03eaVp4e
623	KravchenkoNataliiaIuriiivna	KravchenkoNataliiaIuriiivna@school.ua	$2b$12$ysiEUyNFwKgvuVYtLe6o8.OA4A3HpgW2gu4o63LGibquMvLW4lfGi
624	PetrenkoVolodymyrMykolaovych	PetrenkoVolodymyrMykolaovych@school.ua	$2b$12$HiUYC5whx2qSueDOLveBi.h7UZzFg4GHIggPAJp0Mg6LmjTNKmV.W
625	DmytrenkoOlenaIhorivna	DmytrenkoOlenaIhorivna@school.ua	$2b$12$/830h3TsKdO2g5.KyyRKHOL2npSyBjFe58E62kJPkdVkM9DMjezE2
626	MykytenkoSerhiiPavloovych	MykytenkoSerhiiPavloovych@school.ua	$2b$12$1dBmkNBNShiTvml2B6tND.JrDBgyvN51vAMR0Fdq9GNxzTV4LbP2q
627	LytvynHannaRomanivna	LytvynHannaRomanivna@school.ua	$2b$12$cPlo0J./usrca0dOKCLHAuVTits.cI6ty9uxP2nF/xP.Y65gdkHT.
628	SavchenkoMykolaIevhenovych	SavchenkoMykolaIevhenovych@school.ua	$2b$12$URyrGdWTqITfwjGBZ0BjQuDa02QViW0.KwLj.zvcerZk4/34wWllS
629	KravchukOksanaPetroivna	KravchukOksanaPetroivna@school.ua	$2b$12$JFGul8DDlPI3qhyJbFMkDOA292LbJQffxM6IiQlMibWKCAPPh1Wfy
630	TkachPavloOlehovych	TkachPavloOlehovych@school.ua	$2b$12$6N3qN7jWI6sc4IOftHDMweKHr4XSW.s/c2gCt2jyufcfPiwfKt/S2
631	ShevchukNadiiaTarasivna	ShevchukNadiiaTarasivna@school.ua	$2b$12$DPn19wI63D9EXGDCiVKBn.Eac0ONMiDaBeWZ2IVWvrISxqh69H.nS
632	HryshchenkoIevhenVitaliiovych	HryshchenkoIevhenVitaliiovych@school.ua	$2b$12$MfF46LlMvit5XRov.Jq/hupvcNGD1Mn2wpZlzFBbkXysGi/auwAP.
633	KotsiubynskaLiubaVitalyiivna	KotsiubynskaLiubaVitalyiivna@school.ua	$2b$12$A4fhM.RIOjNQBBUJKP8f4OTMGLi8HXQIUgJ1e5sycAeQOz5kvqKx2
634	ChernenkoOlehVasylovych	ChernenkoOlehVasylovych@school.ua	$2b$12$I9Y.nP8.IVLdKrRI/xv4GeyC72bccGsqgtqqP6n3.HUZI.6V2wxIy
635	PolishchukTamaraLevivna	PolishchukTamaraLevivna@school.ua	$2b$12$6Tc0pjQ2n3OciPLKKnaN0Of8cmu9VqK8TYJARllocnFs4xK77q7qW
636	BondarenkoVitaliiHennadiiovych	BondarenkoVitaliiHennadiiovych@school.ua	$2b$12$fQ0STVe3cteyXOpgOL51WOXBySGdfCuRuW61fpv0yQVoSwPH8o.qq
637	SoloviovaValentynaIaroslavivna	SoloviovaValentynaIaroslavivna@school.ua	$2b$12$OqRj0Ja.MZ.hAyj4JWzUy.bLSEAD0B2rgXKv7hZvFb/LnumiOuz06
638	MatsiukVasylMaksymovych	MatsiukVasylMaksymovych@school.ua	$2b$12$68sXc6r/a7jHWlWh35Aj5OGS6hdFKSUFoazODVp0qfpRcCmFS9Zz.
639	IvanenkoOrysiaBorysivna	IvanenkoOrysiaBorysivna@school.ua	$2b$12$z2j1RH3T.XYn1pyBWmpxeubBgQOM2MtLETkZscsKHyyQAjTZywNCe
640	LevchenkoHennadiiStepanovych	LevchenkoHennadiiStepanovych@school.ua	$2b$12$6c/a3cuziatdfdRqqZxRtO7DrltXvA4LGS9brjrhPuLSNY0XG0XAS
641	DemchenkoAlinaArsenivna	DemchenkoAlinaArsenivna@school.ua	$2b$12$PxTsJb9biGddE5nEWHlrAePXQRh0pFf1ErvMw.r8fYJLBwakAT2T.
642	KovalMaksymDanyloovych	KovalMaksymDanyloovych@school.ua	$2b$12$jeY2yZD.0H1i0L4MhIIpm.VpEolJOIyXbm.yivZ2ivcB4KvAVDdR2
643	RomanenkoIevaVadymivna	RomanenkoIevaVadymivna@school.ua	$2b$12$8.aXyQ45S1iZqhqK4XQ7.uelFtaO.lUcfEPyPi0BHwNmohZwokVgy
644	KovalskyiStepanRostyslavovych	KovalskyiStepanRostyslavovych@school.ua	$2b$12$gevR9iNxeWfjTJLb4t/i/OIq/lbWhdAj3poT1h6o.U3nVM6pyeP1W
645	BoichenkoSofiiaKostiantynivna	BoichenkoSofiiaKostiantynivna@school.ua	$2b$12$Qmd6Ee7pfAH7htPFNIZkp.SWeCh4PmrzSRO6WGwpqlYr7ecnWVUOC
646	PavlenkoDanyloBohdanovych	PavlenkoDanyloBohdanovych@school.ua	$2b$12$lofx9pIoIW9m6O0ewfIii./VLJNUOPaJTWoga6aL.yCoCO7q8x9mG
647	PonomarenkoAnnaFedirivna	PonomarenkoAnnaFedirivna@school.ua	$2b$12$sA2be0LC4FUcy4u2XZa7E.lZvDfTBv0rwvk1/O7WLvhFLcpfvIYWK
648	KlymenkoRostyslavIehorovych	KlymenkoRostyslavIehorovych@school.ua	$2b$12$VB4d25LbAVLMorRulkqNOePM/wluBzJomWTHdw7rpJLOBVukQb6j6
649	KyrychenkoMelaniiaOleksandrivna	KyrychenkoMelaniiaOleksandrivna@school.ua	$2b$12$o7UKNDxAQ0Bzm1lVRjobZeJ/2AnJMKVeFIapVR0y/CBLg7QxYpfu2
650	MartyniukBohdanArtemovych	MartyniukBohdanArtemovych@school.ua	$2b$12$pknz7dUvQNrVUdSck6UJMuqNI/Pq6XQb.IEBoH8Joxq2rGKhqX8ju
651	ZaitsevPolinaAndriiivna	ZaitsevPolinaAndriiivna@school.ua	$2b$12$Y7KLcTk7xfrv0lBi9FUMR.DBiOXcvkFpYwY3gD7NMvN6C8YUfrES2
652	MartynenkoIehorVolodymyrovych	MartynenkoIehorVolodymyrovych@school.ua	$2b$12$Q/2piWeNo8AAn9JrRi55RuioxadeCiGK5wTv2aQua0K35OanQ2q8i
653	OstapenkoIanaDmytroivna	OstapenkoIanaDmytroivna@school.ua	$2b$12$qNk0JkH6Vg64nGtgZKaojOdOMPJW/Zo3LZSSfzh3YpNakaYyCC0R2
654	KuzmenkoArtemSerhiiovych	KuzmenkoArtemSerhiiovych@school.ua	$2b$12$St7uSASBL8RVRx4u/50P0u8bChyxSdXLZ/fjQj9f261gIVcCa5o9e
655	PylypchukNataliiaIuriiivna	PylypchukNataliiaIuriiivna@school.ua	$2b$12$ld.c2XFtcvCTWMfGdqnINOWYTc8gwnE9EQwaNZupVJPsKiGJeL2B2
656	SymonenkoVolodymyrMykolaovych	SymonenkoVolodymyrMykolaovych@school.ua	$2b$12$ABQe4zXKexFvd2sRMpeSO.40tCqH6QIvHjdwSIiZDGwBowTqApvxG
657	ProtsenkoOlenaIhorivna	ProtsenkoOlenaIhorivna@school.ua	$2b$12$unkMsO8Gt6ra6fjYCcjv8OyHF0Gq19OZDrDtTm.Z1vlBIZbD3klBq
658	OleksiienkoSerhiiPavloovych	OleksiienkoSerhiiPavloovych@school.ua	$2b$12$oFWTOVhGn3qhaNelW2U4IuWGThxDnhXRz0KbMb.eY9PMjj8FclyXe
659	KorsunHannaRomanivna	KorsunHannaRomanivna@school.ua	$2b$12$9.Z9nxDLgftweDVOCghcHeitK8vhfpdHRIN4WLDea4s.kU9MvdqcS
660	NechyporenkoMykolaIevhenovych	NechyporenkoMykolaIevhenovych@school.ua	$2b$12$AVmPVH7yJ0Eikl4NXs2LEuGtMI2b7V2vj2W0pXBgBYGX5j7ARjn1C
661	MiroshnychenkoOksanaPetroivna	MiroshnychenkoOksanaPetroivna@school.ua	$2b$12$X7ugr8wLYxUlZyaHeVYYC.YuIrfU/GSbHhRJ5eBFGswYnVDa5ny2e
662	ShevchenkoPavloOlehovych	ShevchenkoPavloOlehovych@school.ua	$2b$12$vlMOMZF05MQwYnV2TjUBPu7pkLhYuwL0uRAzi7rVcFbYqc2No./Zy
663	KovalchukNadiiaTarasivna	KovalchukNadiiaTarasivna@school.ua	$2b$12$WYA8Aa728ts5Cq.9oky16.JTPb8/P5eoyWEoOXK02TtzNdJgxMFDO
664	BoikoIevhenVitaliiovych	BoikoIevhenVitaliiovych@school.ua	$2b$12$rXSG.9uD4Zxlh6O/I5iebeU9mwuT/wuQtqnUHFrRrJfJm8HJi5J/e
665	HoncharLiubaVitalyiivna	HoncharLiubaVitalyiivna@school.ua	$2b$12$wKfybRrSYUi4CC5HeLIu.Oksnl0t68df6G1daT4wExymvfK8CRBZG
666	MelnykOlehVasylovych	MelnykOlehVasylovych@school.ua	$2b$12$3C5VduN6ra9Bp2/yVpWpvOV.Nenj15HQjQCgZL7b9uGnLNqhUP.XW
667	TkachenkoTamaraLevivna	TkachenkoTamaraLevivna@school.ua	$2b$12$OIKH3TdVeDj9EOYekXMKi.IXWbwJRXBxvPw8nwMHpzD357ylO7zFK
668	KozakVitaliiHennadiiovych	KozakVitaliiHennadiiovych@school.ua	$2b$12$ea0YtnHmnFL1U2sbdTpYbeIP7KmbUe39p3o5UJdYHX29bxNykberO
669	RudenkoValentynaIaroslavivna	RudenkoValentynaIaroslavivna@school.ua	$2b$12$nyvQI2zeKKuGzaI7BndHJOx88dBP/6.bSKVHUJQVCSxEcIW1Ls9gy
670	FedorenkoVasylMaksymovych	FedorenkoVasylMaksymovych@school.ua	$2b$12$5IpsBWmFcIJlxOODI/hsmO7qJzVrIiu.88cm3IrxDuHocwOvts9Hq
671	BilykOrysiaBorysivna	BilykOrysiaBorysivna@school.ua	$2b$12$tJdGWanBSiN/z2wRf/OP4uzXT2PTZqOvt6IxQ0HbXEl4n21Fl8vLC
672	SydorenkoHennadiiStepanovych	SydorenkoHennadiiStepanovych@school.ua	$2b$12$7Nalyirh1kqPb6eRd.gi0e69U0OE6vLWkeZp4Tw9OFvqSiwiAiExu
673	KravchenkoAlinaArsenivna	KravchenkoAlinaArsenivna@school.ua	$2b$12$2yM8XjcgHdZNCXZ7a7vePOv3wRp7OAOoZ0jttieLkd3tRhxvMeMlm
674	PetrenkoMaksymDanyloovych	PetrenkoMaksymDanyloovych@school.ua	$2b$12$fgneUW18ePpNCgvs0IZHU.kHll34Zr/s7bxXyhhCMRJDwCMIM5B2u
675	DmytrenkoIevaVadymivna	DmytrenkoIevaVadymivna@school.ua	$2b$12$MArSBT52fOtj2f1Ne6I7XuKy1YDB6LwzdD5dhAgt4rxttMOMfw5S2
676	MykytenkoStepanRostyslavovych	MykytenkoStepanRostyslavovych@school.ua	$2b$12$x8r.LNOnh1EJdnOpbCuuPOXvmS3WE0eaCDn4Wuz4PO6kuCdYblamG
677	SavchenkoDanyloBohdanovych	SavchenkoDanyloBohdanovych@school.ua	$2b$12$.WxUxQEvlFdLtJsCRRU0S.Nl1s7.miO5Vl6adC6tEyn3X9oy6pT4e
678	LytvynSofiiaKostiantynivna	LytvynSofiiaKostiantynivna@school.ua	$2b$12$mrrEtJZbUDhfV8VJizidMOqVk0b7m9cRXMl5Ckpfdh9CIPxHlRKkS
679	KravchukAnnaFedirivna	KravchukAnnaFedirivna@school.ua	$2b$12$VNzLO3arRPBvu68appUdSew56EUHJdwfiqDFkpJfhuCpAFCIVvNm.
680	TkachRostyslavIehorovych	TkachRostyslavIehorovych@school.ua	$2b$12$Ewf28bKX2KkUcC6225wfOuUc66wxZRkNZZjVt.0pbqnRaa48Ojm/W
681	ShevchukMelaniiaOleksandrivna	ShevchukMelaniiaOleksandrivna@school.ua	$2b$12$T0otyXJwVZmtMC/s7nyJxe25slBfne15jsgSo.l7qSW.tytC.Re4.
682	HryshchenkoBohdanArtemovych	HryshchenkoBohdanArtemovych@school.ua	$2b$12$0y1fYGjNNFDVg/YBElTRnOMfCg95IRoLZ9VplibRiMrXssFv7tAX2
683	KotsiubynskaPolinaAndriiivna	KotsiubynskaPolinaAndriiivna@school.ua	$2b$12$tPtjsrhVYEFewq2Q.OTR6uLabxQI1WsiJvg5CG3LEHDvw1U9AdJ0O
684	ChernenkoIehorVolodymyrovych	ChernenkoIehorVolodymyrovych@school.ua	$2b$12$E/2QAL8tf.chd3gXwvkOMO0ID8OHWyhgdoHHKIoSKhzs7y10W4opu
685	PolishchukIanaDmytroivna	PolishchukIanaDmytroivna@school.ua	$2b$12$wgh4/GUMqygkxJ1wnZKWP.kcMNaxvcHtvj7MqdFMk9U5KsSP/86bu
686	BondarenkoArtemSerhiiovych	BondarenkoArtemSerhiiovych@school.ua	$2b$12$q43x4sAR25r/WZqjzKaKYOsE2vzirWsf7BYBTRhGmihqU/Uwjd8xC
687	SoloviovaNataliiaIuriiivna	SoloviovaNataliiaIuriiivna@school.ua	$2b$12$6z8SSWsX7AeZw6mSdk8/LeEwq4GnTf.ICoHVYqr7K7sO7HrIXpm/W
688	MatsiukVolodymyrMykolaovych	MatsiukVolodymyrMykolaovych@school.ua	$2b$12$CELAUFAdWUGL/c1qu/sVIufh8fBW/q3QuDUJ5/a/QVotM/WejA9qG
689	IvanenkoOlenaIhorivna	IvanenkoOlenaIhorivna@school.ua	$2b$12$udziK/HBzFp6hh8EFTVeUe1/lofi7Uf6kfDZoPonkoAF8ulWbvP6e
690	LevchenkoSerhiiPavloovych	LevchenkoSerhiiPavloovych@school.ua	$2b$12$2zMIbUeoiHFO4Pr4G8UAHe2xV/ZaqgWEdjgCS97K90Fow38G0U9y6
691	DemchenkoHannaRomanivna	DemchenkoHannaRomanivna@school.ua	$2b$12$MlHFMFm7ZBwxZTpuqPlgAebHBgtHAPzEiiiKmGqDnhppibFIkLtmm
692	KovalMykolaIevhenovych	KovalMykolaIevhenovych@school.ua	$2b$12$Us7I/xyow2oc0U4vl3vn3OUUlg11yvZVzKnqkLd14A6HYM0tkfAh.
693	RomanenkoOksanaPetroivna	RomanenkoOksanaPetroivna@school.ua	$2b$12$N1/kOIcowbkhu5KeqRTwK.PziXyMeMAZ0OGp9cGAn8mS5J5cYYV56
694	KovalskyiPavloOlehovych	KovalskyiPavloOlehovych@school.ua	$2b$12$nAYKT7HRHzGuskHvRzLMJOt7Hs5CgYvjP.yWwRfdUuCNnIb88ZMq6
695	BoichenkoNadiiaTarasivna	BoichenkoNadiiaTarasivna@school.ua	$2b$12$EWFZ77iXt88YIXgBLsUiv.E8XJjOCYXCa8lQUHAIaa2ZmlZwJpPi.
696	PonomarenkoLiubaVitalyiivna	PonomarenkoLiubaVitalyiivna@school.ua	$2b$12$AXMLgSoZrq66YmRWEkaBQeIT4bjHC4NdeBLQmx3h3Lc5RRrHypwba
697	PavlenkoIevhenVitaliiovych	PavlenkoIevhenVitaliiovych@school.ua	$2b$12$7JkpX1oa9x1W364qYB8.eeFWfKvbFDwT3KNeAyMdSxn4EmSfsU1ry
698	KlymenkoOlehVasylovych	KlymenkoOlehVasylovych@school.ua	$2b$12$ChTaiXiQnKWvXr7Q/nPy2.r/pGFH5HxrTcr9zHkRcmi8Sp1zzRY/K
699	KyrychenkoTamaraLevivna	KyrychenkoTamaraLevivna@school.ua	$2b$12$sRPXqCzd5.k52E8ULqAhjuahSJPxUigZJUWfczDa9HxAkZnQklQGK
700	MartyniukVitaliiHennadiiovych	MartyniukVitaliiHennadiiovych@school.ua	$2b$12$jhkJ9W5SHYImkJIsxrPu2eUZqNfL3qv/WIqxS.1F8zGZwS4j7JLNu
701	ZaitsevValentynaIaroslavivna	ZaitsevValentynaIaroslavivna@school.ua	$2b$12$hHzjdjuCsRhF4yTUE06J.eLMOy2nBEBO2QRqTLZdasRYF2h4wSE8K
702	MartynenkoVasylMaksymovych	MartynenkoVasylMaksymovych@school.ua	$2b$12$ct4AqgLbxJPdcEzs64AjlODKMcjb/APBaRBV1r6/uOlW3kCSGkrSm
703	OstapenkoOrysiaBorysivna	OstapenkoOrysiaBorysivna@school.ua	$2b$12$OcRh1fGtQ7vWrkrxOv1p6.uhEM6JoW9kUfMOfTSAx0zuB7T0nqUO6
704	KuzmenkoHennadiiStepanovych	KuzmenkoHennadiiStepanovych@school.ua	$2b$12$dMHn5lSVEQgSR2PUpdUYNe/JIMZ74OdRYb7TFmDLgJ1wcdPq/8FFy
705	PylypchukAlinaArsenivna	PylypchukAlinaArsenivna@school.ua	$2b$12$q1PtSQdmCKi0U56L1GxgXeiesDrJDufWtQNEEAWBmsJDHYNGGp9oO
706	SymonenkoMaksymDanyloovych	SymonenkoMaksymDanyloovych@school.ua	$2b$12$E9OnyPpzvzlgDmETvc77G.Kq6FESbR/OVTWr5n5pyOxPdPXXrM/Fy
707	ProtsenkoIevaVadymivna	ProtsenkoIevaVadymivna@school.ua	$2b$12$7kke8DTPCk1KFkQB4pSxFONz.mxd/7LYsywBhYwIg3gXQIS.d29xu
708	KorsunSofiiaKostiantynivna	KorsunSofiiaKostiantynivna@school.ua	$2b$12$WCHC4Nz.ujaLlbpKScpT/OP.qpTgYD7wsgqwMOJiEejn/wpUD80bu
709	OleksiienkoStepanRostyslavovych	OleksiienkoStepanRostyslavovych@school.ua	$2b$12$9NwCaJZORrR3SfwDUMGhaeejjmHrx60hiRsU7xuptZRaBJW6Vbcpi
710	NechyporenkoDanyloBohdanovych	NechyporenkoDanyloBohdanovych@school.ua	$2b$12$D19t7tInvmvZf4/5EwAc8OYn2FfBdVSAMqXQXiP02ytdfiIJQ/cg.
711	MiroshnychenkoAnnaFedirivna	MiroshnychenkoAnnaFedirivna@school.ua	$2b$12$VbAP6euMyeUm7pLBbgjQu.i8opPATKFWNb9WbfXXS/huDuq3ApDN.
712	ShevchenkoRostyslavIehorovych	ShevchenkoRostyslavIehorovych@school.ua	$2b$12$Y/yXCPB8R1NsA2W.Mag62eO2zOtbHFSDdgrlT59iaYt5BVaPbZQ4y
713	KovalchukMelaniiaOleksandrivna	KovalchukMelaniiaOleksandrivna@school.ua	$2b$12$Lhj/.YebNYdN3/5SFSP6RuchfHDdxCnryhwEcGGZbOswCPLFEdAjS
714	BoikoBohdanArtemovych	BoikoBohdanArtemovych@school.ua	$2b$12$MPQQ5NoLjqypuMOfafRttOzlUzy//Mq07tCGgFGP8BwkJc6uA2c7G
715	HoncharPolinaAndriiivna	HoncharPolinaAndriiivna@school.ua	$2b$12$LyttxSQEloN3IfS/feEhwepmlyvuzGwSz2yFLZvZKdDP1d5Jv.j/.
716	MelnykIehorVolodymyrovych	MelnykIehorVolodymyrovych@school.ua	$2b$12$1l/OvggjBMvtzelIeQQSjebmhvMagSl/SqH6.fwwve.tkGDIt6ata
717	TkachenkoIanaDmytroivna	TkachenkoIanaDmytroivna@school.ua	$2b$12$GuA7.q2t8I7DzOqOQi2UMuIbU8f5PlC/4tMtTRlT5DfpGp8Q5skR6
718	KozakArtemSerhiiovych	KozakArtemSerhiiovych@school.ua	$2b$12$OIe1/1lMbJxKoA2bZ7PNxuJm.YfO9QyayDsWGHD4eXwxbUW5NHST6
719	RudenkoNataliiaIuriiivna	RudenkoNataliiaIuriiivna@school.ua	$2b$12$Qwrkuej4ijzh2LAhCy4XP.vGr2swynlksAyMYCGsuB09O8ugkVr9O
720	FedorenkoVolodymyrMykolaovych	FedorenkoVolodymyrMykolaovych@school.ua	$2b$12$xjbY.MWcZx9NFmAQYYAl8eC0OREMSUnVi/fhBlw6Ie.kNvKhpIQOW
721	SydorenkoSerhiiPavloovych	SydorenkoSerhiiPavloovych@school.ua	$2b$12$fqzGo4SxU/lRCrtXhQnJROPvrSW6mP9lgnyubR4CLagFRiUPGYq7y
722	KravchenkoHannaRomanivna	KravchenkoHannaRomanivna@school.ua	$2b$12$YBOOrGXMn7eZML2NA2ZLMuyctwLC4xHxCIKlOGOtR5lA9ljSJIIh2
723	PetrenkoMykolaIevhenovych	PetrenkoMykolaIevhenovych@school.ua	$2b$12$IwCkudBEYKg0YeHOPXxIWePuxvq2LkGHKbriOBkh06Ap7eGvdgnCK
724	DmytrenkoOksanaPetroivna	DmytrenkoOksanaPetroivna@school.ua	$2b$12$.OkRx0tE48V/m2662fkgpuEui7b.WnDd5vvPAgIph/Z2U4Q6gqVyC
725	MykytenkoPavloOlehovych	MykytenkoPavloOlehovych@school.ua	$2b$12$ELW1tmbrxFSZFz8noRX4een.IKQW7JqC5p9QoK4uAYWx1emoMmxmu
726	BilykOlenaIhorivna	BilykOlenaIhorivna@school.ua	$2b$12$8ECtm6/K7tYCmUeoziEY4uGvCn/qa9J4EY/GtOaaJ.V6YCwM4hw8a
727	LytvynNadiiaTarasivna	LytvynNadiiaTarasivna@school.ua	$2b$12$.IQztD8oTgCl9bcoVb1Ti.3C4BGsna2Qnvqw8hlC/tdjNEY5RLP8.
728	SavchenkoIevhenVitaliiovych	SavchenkoIevhenVitaliiovych@school.ua	$2b$12$si0MNDySQzSfWWkI9EaLxOzNcxyNF9br.iVKuyhGaqRwUEsEs1/K6
729	KravchukLiubaVitalyiivna	KravchukLiubaVitalyiivna@school.ua	$2b$12$hu7tCDtow49BJhli9NoLV.GRF3OqHNQeRQ31BB32.VbCa996xaO1S
730	TkachOlehVasylovych	TkachOlehVasylovych@school.ua	$2b$12$ztaFmaiZzip..LZuO.BKzut5eG7SayN.9Uv2zIKpi4hF1v.aC81nm
731	ShevchukTamaraLevivna	ShevchukTamaraLevivna@school.ua	$2b$12$lurAIn.RC5uCMmPA30ECVObW7plxCGIPsXgwdQ1h.lpg6z9d.LynS
732	HryshchenkoVitaliiHennadiiovych	HryshchenkoVitaliiHennadiiovych@school.ua	$2b$12$CXlsWJSkLHb7OnVycfA.MuRpVgstIaEPtrer3cFsm1JXKOodoiF2i
733	KotsiubynskaValentynaIaroslavivna	KotsiubynskaValentynaIaroslavivna@school.ua	$2b$12$HO0WZhqiPlKmT20taeTRQumYiizgEb5r6dctctUB0rdYueFNXApee
734	ChernenkoVasylMaksymovych	ChernenkoVasylMaksymovych@school.ua	$2b$12$wC0Wh95JCE9tvCQMn14s9uszOV0JVJH0vavES5qkQT5gpik6/t9jy
735	PolishchukOrysiaBorysivna	PolishchukOrysiaBorysivna@school.ua	$2b$12$fa9Y6WvzTRtZTjkKLxcB1ebDOmDqaWR05viLkthj8G5YST2Z8lWAe
736	BondarenkoHennadiiStepanovych	BondarenkoHennadiiStepanovych@school.ua	$2b$12$YFKyKZdXY1oUdaHpSr6jFuFfMKN6KxUxp3JSSW6LQU7lkglk8MCpe
737	SoloviovaAlinaArsenivna	SoloviovaAlinaArsenivna@school.ua	$2b$12$y5bv7v2zDmc84lsSTgfYCuP4PHOxDh7WGDPL8Xyca2604OsePGyrK
738	MatsiukMaksymDanyloovych	MatsiukMaksymDanyloovych@school.ua	$2b$12$UemjWK6w/5jEwEWnidGJouqakxzOKuLS5lxyVllr2PGWGvBHaO4RK
739	IvanenkoIevaVadymivna	IvanenkoIevaVadymivna@school.ua	$2b$12$x3I0s7k7aFLUd.11EvHvAeI.XKs/H58TaXuikpfmSynnvgbonxQI.
742	HoncharOlenaIhorivna	HoncharOlenaIhorivna@school.ua	$2b$12$o2cdJw9PAOXXCFMYXafS/OKAWQlOTG2qDYEisjYPMTwO5WkIr1gfq
743	KorsunValentynaIaroslavivna	KorsunValentynaIaroslavivna@school.ua	$2b$12$jEvwkiIHnTY7PUX4emTxT.boMsBqEjtXrwbR1bL0OSdI6QZ.JJoB.
744	RomanenkoIanaDmytroivna	RomanenkoIanaDmytroivna@school.ua	$2b$12$4l2DYDSiTd05AWxvaL1mAONtGsi1sPHBDwkTHtWDbe6PUHdhganeK
740	MelnykSerhiiPavloovych	MelnykSerhiiPavloovych@school.ua	$2b$12$Y/wGHxKy/k1fZHUEoYVjYeIUbrsc.g2fhn4xFPRSlQou7q97RanFy
741	KovalchukNataliiaIuriiivna	KovalchukNataliiaIuriiivna@school.ua	$2b$12$oUj5HcIKqlg8v6H./gQ/YeB6Mje.yjXd9hTi/zLSK.XsNaY4beXpW
745	MatsiukRostyslavIehorovych	MatsiukRostyslavIehorovych@school.ua	$2b$12$p7WM2MI8vdg2siQg.v8a9O.A4yujuiz.Pfmvah6ffv02zxZHuGf7C
746	PonomarenkoOlenaIhorivna	PonomarenkoOlenaIhorivna@school.ua	$2b$12$cvN5XcJBX4lMpybewU12D.tQqrJZ12988MGCKQeIy.YNg/A5eiLnq
747	DmytrenkoTamaraLevivna	DmytrenkoTamaraLevivna@school.ua	$2b$12$9lVI4A9U5T0euL/YbqhfkeTnJMj5F1SdfZhaoWcX7v6pzImBbYdey
748	ShevchenkoHennadiiStepanovych	ShevchenkoHennadiiStepanovych@school.ua	$2b$12$EcGX00yYMK98gnszkcjt3O6UARVWTj62KU9NHtsWax6Fu52Qh6y3K
749	DemchenkoSofiiaKostiantynivna	DemchenkoSofiiaKostiantynivna@school.ua	$2b$12$.ErEDENpgiGJhbnEoi0dQufAmIQEcEvs9VN7Qu2DLFfKyDjJG6hzu
750	LevchenkoStepanRostyslavovych	LevchenkoStepanRostyslavovych@school.ua	$2b$12$.ZTPX/FFuz4KdtXnOOadQejnvR9wIik/fgbqjt2BoLa1dNwvvcwAe
754	MelnykAndriiOleksiiovych	MelnykAndriiOleksiiovych@school.ua	$2b$12$n9YrMOABKw7gnv1IbNYAVeVOjl.9Hma4R0VIPMZ.TCPpK4lXcauTK
755	HoncharNataliiaAndriivna	HoncharNataliiaAndriivna@school.ua	$2b$12$a3uyqUB9DC3L373Jp2YbhOAUCw0foLpepVQgSn2W/RRI/Z3rjQKb.
756	RudenkoOlenaAnatoliivna	RudenkoOlenaAnatoliivna@school.ua	$2b$12$tRDYr/RIA610aFC080/wLuScJ6wwPgN8LrLwnBCvr44EVKCZuFwtm
757	BilykTetianaIhorivna	BilykTetianaIhorivna@school.ua	$2b$12$3vSPjAFVSnZFtbCrlyR58.Sv22BQFT.A2YfuaJEJ2Rqrin60VjdR.
758	SydorenkoMykolaOleksandrovych	SydorenkoMykolaOleksandrovych@school.ua	$2b$12$0G.A4S1QUPwvRt7JaIkbJu6Vlr8LQv.Uf0OiYc930TKzOhUtNUKmm
759	KravchenkoLiudmylaMykhailivna	KravchenkoLiudmylaMykhailivna@school.ua	$2b$12$dI5eOho828Z1YZUenYUDme9sN45djT8cXnUtGRYO7jAaldusHgywi
760	PetrenkoIuriiViktorovych	PetrenkoIuriiViktorovych@school.ua	$2b$12$5SLqjgWWLKyE4gvliQGXxu0.IYYBgAM60qsTc325RlEGWjKT7lCUq
761	DmytrenkoOksanaSerhiivna	DmytrenkoOksanaSerhiivna@school.ua	$2b$12$HlnNjpL5K7HyjEpz3ufBNexUCxcGPmRucbK.FeuJLem2rTZKqJxdy
762	MykytenkoViktorAnatoliiovych	MykytenkoViktorAnatoliiovych@school.ua	$2b$12$jvsJrTjLNSTW2ebYV9oYvuXOiV8Da4UivkQEu1mWKP3BD/5qe4Ise
763	SavchenkoIevhenOleksandrovych	SavchenkoIevhenOleksandrovych@school.ua	$2b$12$iKcYiF6CW1lYVNy6LJfqbe1bg0hvqxHL4XUo/vZbWZlo1wv638kN.
764	KravchukSvitlanaViktorivna	KravchukSvitlanaViktorivna@school.ua	$2b$12$P3QG0drA664WMemMJl4Yo.jROFCwwhXQ5dqKSMcTVJwt/I/TChY1O
765	ShevchukLiubaIvanivna	ShevchukLiubaIvanivna@school.ua	$2b$12$QOS0bcyHJ1VLegiKYoyUDuk3wQ/VngZuTmtMTYrbAY3xIevew2UB.
766	HryshchenkoOlehSerhiiovych	HryshchenkoOlehSerhiiovych@school.ua	$2b$12$3cbtuYcY062hrm0CtyGqEuOG8z9XHiMyNWkFw2we690lzFoRu7DAy
767	PolishchukValentynaMykolaivna	PolishchukValentynaMykolaivna@school.ua	$2b$12$u7xsezzsq5nizcP0kxavzeTBONuljsegwSK3ZFEZtN18VNPsGkTN6
768	ChernenkoIhorAnatoliiovych	ChernenkoIhorAnatoliiovych@school.ua	$2b$12$m.2sh6R69dkUovcf0tgLBuWIXgPWnb.Q/VrimKUg9ArKU/7iJmooa
769	BondarenkoAnatoliiViktorovych	BondarenkoAnatoliiViktorovych@school.ua	$2b$12$zAyPezqQ7rm4EqcAE4Zpq..54wlBabUr/VO1HjnyoGSgh7svpZh/W
770	SoloviovaOlhaSerhiivna	SoloviovaOlhaSerhiivna@school.ua	$2b$12$OltBtvau5BjdgVM9HYBYj.tVoYYQeEJD4xBSIPzQ3y24Ifn95HYXy
771	MatsiukRomanOleksandrovych	MatsiukRomanOleksandrovych@school.ua	$2b$12$LcgKOX2KmpemTnuffopdoeu8VbGNEkWXx7DGQVUaMTpeME0gSqZn.
772	IvanenkoTamaraPetrivna	IvanenkoTamaraPetrivna@school.ua	$2b$12$EOSKMQJ7y7STqDBv984SGuVut6n8fhxRFPuaYmbUn0V94squkfn6S
773	LevchenkoViktoriiaAnatoliivna	LevchenkoViktoriiaAnatoliivna@school.ua	$2b$12$yhXVVAT8/tlnArqNpNH0ruBz0islSR03GboO0lQ395PCIHZNGvU.W
774	ShevchenkoOleksandrIvanovych	ShevchenkoOleksandrIvanovych@school.ua	$2b$12$R/wQLf8yFbDVaYekF4auvec6CofZdYlqRmWXnrRsX7ZJUDayuBOJS
776	DemchenkoIehorSerhiiovych	DemchenkoIehorSerhiiovych@school.ua	$2b$12$wJbDAxTj9i9Usb6cEJ7X..FcppC45SauKyv7M8J.yFXN3qbzHoYl2
775	KovalchukMariiaPetrivna	KovalchukMariiaPetrivna@school.ua	$2b$12$gxr.wrFM1hc0pYlNC2dZdeJNmzDi/CmcO.uEtgDGzO24jBAwUH4R.
777	TkachenkoIrynaViktorivna	TkachenkoIrynaViktorivna@school.ua	$2b$12$qCP8uBxEyz5lArdoyo6yz.5FML0HhIVNk6zKzeXyPHdQKZAZSrea.
778	KozakSerhiiPetrovych	KozakSerhiiPetrovych@school.ua	$2b$12$6pG9fDJvx234vzWApMIxqeQV.MxiuI4wfn9xO2iVSt9cX89V8b5sK
779	BoikoVolodymyrSerhiiovych	BoikoVolodymyrSerhiiovych@school.ua	$2b$12$tpzX/4zdyEPLDmKgvfjsIO7NCaVjdT56k6I58qfvFxcv824Pj33mK
780	LytvynHannaPetrivna	LytvynHannaPetrivna@school.ua	$2b$12$n5q/pBjy7ECD6xpVV9TcD.sAz0YjADuEW.3DHbq2JzvNc3dvZhkBy
781	FedorenkoDmytroVolodymyrovych	FedorenkoDmytroVolodymyrovych@school.ua	$2b$12$Hq3uRoke6X.5MZAU.9ScRuQhRQKCYs0AUmpXCuyHq.PnI30brxaVK
782	KovalMarynaMykhailivna	KovalMarynaMykhailivna@school.ua	$2b$12$JSzOC4lRVcv4s9NdKnOwX.HPeN2k2Zt/OH1JEON3n9RojdZ.54e6i
783	KotsiubynskaNadiiaPetrivna	KotsiubynskaNadiiaPetrivna@school.ua	$2b$12$teZjNahxLqGmNyp0XNNfVOCUWGWsJ1jB1YqMxEIIic5fo1y65cTNy
784	TkachPavloMykhailovych	TkachPavloMykhailovych@school.ua	$2b$12$N5CgkUncZh3FrQUAk6A4XOhBK1goEcsMH2PU7mB9uCJHQEZd.LQmu
785	RomanenkoDenysOleksiiovych	RomanenkoDenysOleksiiovych@school.ua	$2b$12$OHXLOCyCYCp2IoWFJDwIo.PRvfTqjrUh.h6rt4b9yCRbsSBmcMnai
787	sniffy2	sniffy2@school.ua	$2b$12$BYZbKQS8Z6ePUYtsKMTXDe6zNu/0E4AbA4gfUDQZYcuwLEkdJ/Etu
788	guest1	guest1@school.edu.ua	$2a$06$Xv/RR8l17WSwzJDG6QYan.bAmBI3eGz7Kw01ktJuumshQjni45AY2
823	ivan.petrenko.ole	ivanpetrenkoole@school.edu.ua	$2a$06$Oj4kbpfH5nuEW7wokaqk1eSXknKDZJ3IXheG7bY4Yv.jAVRjdenAO
824	ivanapetrenkoole	ivanapetrenkoole@school.edu.ua	$2a$06$CF8v2Z6MAcnZoDXooNMI.eSdpGYMWwJCYJLl5vCo2ZY4S5o1pYwxe
825	ivanypetrenkoole	ivanypetrenkoole@school.edu.ua	$2a$06$Xh.v8L2H2/IyE6lP.qfJP.YCAA6pm7EV4eIjDVsMD7MfpXlYGfdOG
827	teacher	teacher@school.edu.ua	$2a$06$gE8kSE8w5W0dp0f6Uu70teKVfbAjlrQ5iFHq9viiOU/qcqdWCzBa6
828	parent	parent@school.edu.ua	$2a$06$rx0SxcdzOqpz2aTj61CODu.G7Y0anoCP1btjdtAf/m2CRZoTJXntu
830	admin	admin@school.edu.ua	$2a$06$2QpJHWC8mCCoI7T3tcaqhu.MlxwROnMPOSWtaZZJwkAz70DyMsrwC
836	test22test22tes	test22test22tes@school.edu.ua	$2a$06$rUk6xk2nsxi.f5002KE64eEEd1EYbJfhRMiWx5vts5dnaZlhBK1xm
826	eaty	eaty@shitty.ass	$2a$06$XOyQIpEVN1y4nE7nchJDFeq7nkHDzjUClBXWj3scCFZfTFCihes9y
831	sadmin	sadmin@school.edu.ua	$2a$06$K9NCzeWWMGZycUD3D9FXIeBXULRBv1QrUg3uZla6kKcfyKPAsbvmq
834	test2test2tes	test2test2tes@school.edu.ua	$2a$06$2NJJfKuWVreU2639H6ffDOIJd10Odsoj3xgWdNBTiuNznay/iB2dm
835	test21test2tes	test21test2tes@school.edu.ua	$2a$06$GxHIhT.AsBvfPvyKlIINcu20wk6qj0uP9z41gy0RChQ7l3qo2OWse
840	teststestsxxx	teststestsxxx@school.edu.ua	$2a$06$hufcMA2jWQeCB2fdqM6Ie.VoIk8t8izLVwSkoqZbdBuF8yX2AEBFy
839	serhiikursovole	serhiikursovole@school.edu.ua	$2a$06$wSRlMnr9fo6o3B8fQs47m.AZe9X3bex8PVuHyWbOUMXD6J7IBtjae
\.


--
-- Name: auditlog_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auditlog_log_id_seq', 67, true);


--
-- Name: days_day_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.days_day_id_seq', 702, true);


--
-- Name: homework_homework_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.homework_homework_id_seq', 129, true);


--
-- Name: journal_journal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.journal_journal_id_seq', 31, true);


--
-- Name: lessons_lesson_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lessons_lesson_id_seq', 210, true);


--
-- Name: material_material_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_material_id_seq', 125, true);


--
-- Name: parents_parent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parents_parent_id_seq', 469, true);


--
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_role_id_seq', 8, true);


--
-- Name: studentdata_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.studentdata_data_id_seq', 1514, true);


--
-- Name: students_student_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.students_student_id_seq', 290, true);


--
-- Name: subjects_subject_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subjects_subject_id_seq', 22, true);


--
-- Name: teacher_teacher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_teacher_id_seq', 38, true);


--
-- Name: timetable_timetable_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.timetable_timetable_id_seq', 33, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 840, true);


--
-- Name: auditlog auditlog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditlog
    ADD CONSTRAINT auditlog_pkey PRIMARY KEY (log_id);


--
-- Name: class class_class_mainteacher_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_class_mainteacher_key UNIQUE (class_mainteacher);


--
-- Name: class class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_pkey PRIMARY KEY (class_name);


--
-- Name: days days_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days
    ADD CONSTRAINT days_pkey PRIMARY KEY (day_id);


--
-- Name: homework homework_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.homework
    ADD CONSTRAINT homework_pkey PRIMARY KEY (homework_id);


--
-- Name: journal journal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (journal_id);


--
-- Name: lessons lessons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT lessons_pkey PRIMARY KEY (lesson_id);


--
-- Name: material material_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material
    ADD CONSTRAINT material_pkey PRIMARY KEY (material_id);


--
-- Name: parents parents_parent_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parents
    ADD CONSTRAINT parents_parent_phone_key UNIQUE (parent_phone);


--
-- Name: parents parents_parent_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parents
    ADD CONSTRAINT parents_parent_user_id_key UNIQUE (parent_user_id);


--
-- Name: parents parents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parents
    ADD CONSTRAINT parents_pkey PRIMARY KEY (parent_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- Name: studentdata studentdata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studentdata
    ADD CONSTRAINT studentdata_pkey PRIMARY KEY (data_id);


--
-- Name: studentparent studentparent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studentparent
    ADD CONSTRAINT studentparent_pkey PRIMARY KEY (student_id_ref, parent_id_ref);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (student_id);


--
-- Name: students students_student_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_phone_key UNIQUE (student_phone);


--
-- Name: students students_student_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_user_id_key UNIQUE (student_user_id);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (subject_id);


--
-- Name: subjects subjects_subject_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_subject_name_key UNIQUE (subject_name);


--
-- Name: teacher teacher_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher
    ADD CONSTRAINT teacher_pkey PRIMARY KEY (teacher_id);


--
-- Name: teacher teacher_teacher_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher
    ADD CONSTRAINT teacher_teacher_phone_key UNIQUE (teacher_phone);


--
-- Name: teacher teacher_teacher_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher
    ADD CONSTRAINT teacher_teacher_user_id_key UNIQUE (teacher_user_id);


--
-- Name: timetable timetable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable
    ADD CONSTRAINT timetable_pkey PRIMARY KEY (timetable_id);


--
-- Name: userrole userrole_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.userrole
    ADD CONSTRAINT userrole_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: vw_student_ranking _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.vw_student_ranking AS
 SELECT s.student_id,
    s.student_name,
    s.student_surname,
    s.student_class,
    round(avg(sd.mark), 2) AS avg_mark,
    rank() OVER (PARTITION BY s.student_class ORDER BY (avg(sd.mark)) DESC) AS class_rank
   FROM ((public.students s
     JOIN public.studentdata sd ON ((sd.student_id = s.student_id)))
     JOIN public.lessons l ON ((l.lesson_id = sd.lesson)))
  WHERE ((sd.mark IS NOT NULL) AND ((l.lesson_date >= '2025-09-01 00:00:00'::timestamp without time zone) AND (l.lesson_date <= '2026-06-30 00:00:00'::timestamp without time zone)))
  GROUP BY s.student_id, s.student_name, s.student_class;


--
-- Name: vws_teacher_profile _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.vws_teacher_profile AS
 SELECT t.teacher_id,
    t.teacher_name,
    t.teacher_surname,
    t.teacher_patronym,
    t.teacher_phone,
    u.email,
    count(c.class_name) AS classes_managed
   FROM ((public.teacher t
     LEFT JOIN public.users u ON ((t.teacher_user_id = u.user_id)))
     LEFT JOIN public.class c ON ((t.teacher_id = c.class_mainteacher)))
  GROUP BY t.teacher_id, u.email;


--
-- Name: lessons check_timetable_conflict; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_timetable_conflict BEFORE INSERT ON public.lessons FOR EACH ROW EXECUTE FUNCTION public.trg_check_timetable_conflict();


--
-- Name: studentdata prevent_fast_double_mark; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER prevent_fast_double_mark BEFORE INSERT ON public.studentdata FOR EACH ROW EXECUTE FUNCTION public.trg_prevent_fast_double_mark();


--
-- Name: users unique_user_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unique_user_check BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.trg_unique_user_fields();


--
-- Name: class class_class_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_class_journal_id_fkey FOREIGN KEY (class_journal_id) REFERENCES public.journal(journal_id) ON DELETE SET NULL;


--
-- Name: class class_class_mainteacher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_class_mainteacher_fkey FOREIGN KEY (class_mainteacher) REFERENCES public.teacher(teacher_id) ON DELETE SET NULL;


--
-- Name: days days_day_subject_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days
    ADD CONSTRAINT days_day_subject_fkey FOREIGN KEY (day_subject) REFERENCES public.subjects(subject_id) ON DELETE SET NULL;


--
-- Name: days days_day_timetable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days
    ADD CONSTRAINT days_day_timetable_fkey FOREIGN KEY (day_timetable) REFERENCES public.timetable(timetable_id) ON DELETE CASCADE;


--
-- Name: homework homework_homework_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.homework
    ADD CONSTRAINT homework_homework_class_fkey FOREIGN KEY (homework_class) REFERENCES public.class(class_name) ON DELETE CASCADE;


--
-- Name: homework homework_homework_lesson_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.homework
    ADD CONSTRAINT homework_homework_lesson_fkey FOREIGN KEY (homework_lesson) REFERENCES public.lessons(lesson_id) ON DELETE CASCADE;


--
-- Name: homework homework_homework_teacher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.homework
    ADD CONSTRAINT homework_homework_teacher_fkey FOREIGN KEY (homework_teacher) REFERENCES public.teacher(teacher_id) ON DELETE SET NULL;


--
-- Name: journal journal_journal_teacher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.journal
    ADD CONSTRAINT journal_journal_teacher_fkey FOREIGN KEY (journal_teacher) REFERENCES public.teacher(teacher_id) ON DELETE SET NULL;


--
-- Name: journal journal_teacher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.journal
    ADD CONSTRAINT journal_teacher_fkey FOREIGN KEY (journal_teacher) REFERENCES public.teacher(teacher_id) ON DELETE SET NULL;


--
-- Name: lessons lessons_lesson_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT lessons_lesson_class_fkey FOREIGN KEY (lesson_class) REFERENCES public.class(class_name) ON DELETE CASCADE;


--
-- Name: lessons lessons_lesson_material_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT lessons_lesson_material_fkey FOREIGN KEY (lesson_material) REFERENCES public.material(material_id) ON DELETE SET NULL;


--
-- Name: lessons lessons_lesson_subject_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT lessons_lesson_subject_fkey FOREIGN KEY (lesson_subject) REFERENCES public.subjects(subject_id) ON DELETE SET NULL;


--
-- Name: lessons lessons_lesson_teacher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT lessons_lesson_teacher_fkey FOREIGN KEY (lesson_teacher) REFERENCES public.teacher(teacher_id) ON DELETE SET NULL;


--
-- Name: parents parents_parent_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parents
    ADD CONSTRAINT parents_parent_user_id_fkey FOREIGN KEY (parent_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: studentdata studentdata_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studentdata
    ADD CONSTRAINT studentdata_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES public.journal(journal_id) ON DELETE CASCADE;


--
-- Name: studentdata studentdata_lesson_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studentdata
    ADD CONSTRAINT studentdata_lesson_fkey FOREIGN KEY (lesson) REFERENCES public.lessons(lesson_id) ON DELETE CASCADE;


--
-- Name: studentdata studentdata_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studentdata
    ADD CONSTRAINT studentdata_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: studentparent studentparent_parent_id_ref_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studentparent
    ADD CONSTRAINT studentparent_parent_id_ref_fkey FOREIGN KEY (parent_id_ref) REFERENCES public.parents(parent_id) ON DELETE CASCADE;


--
-- Name: studentparent studentparent_student_id_ref_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studentparent
    ADD CONSTRAINT studentparent_student_id_ref_fkey FOREIGN KEY (student_id_ref) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: students students_student_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_class_fkey FOREIGN KEY (student_class) REFERENCES public.class(class_name) ON DELETE SET NULL;


--
-- Name: students students_student_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_user_id_fkey FOREIGN KEY (student_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: teacher teacher_teacher_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher
    ADD CONSTRAINT teacher_teacher_user_id_fkey FOREIGN KEY (teacher_user_id) REFERENCES public.users(user_id);


--
-- Name: teacher teacher_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher
    ADD CONSTRAINT teacher_user_id_fkey FOREIGN KEY (teacher_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: timetable timetable_timetable_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable
    ADD CONSTRAINT timetable_timetable_class_fkey FOREIGN KEY (timetable_class) REFERENCES public.class(class_name) ON DELETE CASCADE;


--
-- Name: userrole userrole_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.userrole
    ADD CONSTRAINT userrole_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- Name: userrole userrole_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.userrole
    ADD CONSTRAINT userrole_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO guest;
GRANT USAGE ON SCHEMA public TO student;
GRANT USAGE ON SCHEMA public TO parent;
GRANT USAGE ON SCHEMA public TO teacher;
GRANT USAGE ON SCHEMA public TO admin;
GRANT USAGE ON SCHEMA public TO sadmin;


--
-- Name: FUNCTION absents_more_than_x(p_class character varying, p_x integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.absents_more_than_x(p_class character varying, p_x integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.absents_more_than_x(p_class character varying, p_x integer) TO teacher;
GRANT ALL ON FUNCTION public.absents_more_than_x(p_class character varying, p_x integer) TO admin;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.armor(bytea) FROM PUBLIC;
GRANT ALL ON FUNCTION public.armor(bytea) TO admin;
GRANT ALL ON FUNCTION public.armor(bytea) TO sadmin;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.armor(bytea, text[], text[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO admin;
GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO sadmin;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.crypt(text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.crypt(text, text) TO admin;
GRANT ALL ON FUNCTION public.crypt(text, text) TO sadmin;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.dearmor(text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.dearmor(text) TO admin;
GRANT ALL ON FUNCTION public.dearmor(text) TO sadmin;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.decrypt(bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.digest(bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.digest(bytea, text) TO admin;
GRANT ALL ON FUNCTION public.digest(bytea, text) TO sadmin;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.digest(text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.digest(text, text) TO admin;
GRANT ALL ON FUNCTION public.digest(text, text) TO sadmin;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.encrypt(bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.gen_random_bytes(integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO admin;
GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO sadmin;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.gen_random_uuid() FROM PUBLIC;
GRANT ALL ON FUNCTION public.gen_random_uuid() TO admin;
GRANT ALL ON FUNCTION public.gen_random_uuid() TO sadmin;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.gen_salt(text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.gen_salt(text) TO admin;
GRANT ALL ON FUNCTION public.gen_salt(text) TO sadmin;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.gen_salt(text, integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO admin;
GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO sadmin;


--
-- Name: FUNCTION get_data_by_user_id(p_user_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_data_by_user_id(p_user_id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_data_by_user_id(p_user_id integer) TO guest;
GRANT ALL ON FUNCTION public.get_data_by_user_id(p_user_id integer) TO admin;


--
-- Name: FUNCTION get_homework_by_createdate(p_class character varying, p_date date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) TO student;
GRANT ALL ON FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) TO parent;
GRANT ALL ON FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) TO teacher;
GRANT ALL ON FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) TO admin;
GRANT ALL ON FUNCTION public.get_homework_by_createdate(p_class character varying, p_date date) TO sadmin;


--
-- Name: FUNCTION get_homework_by_date_class(p_class character varying, p_date date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_homework_by_date_class(p_class character varying, p_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_homework_by_date_class(p_class character varying, p_date date) TO student;
GRANT ALL ON FUNCTION public.get_homework_by_date_class(p_class character varying, p_date date) TO parent;
GRANT ALL ON FUNCTION public.get_homework_by_date_class(p_class character varying, p_date date) TO admin;


--
-- Name: FUNCTION get_homework_by_duedate(p_class character varying, p_date date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) TO student;
GRANT ALL ON FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) TO parent;
GRANT ALL ON FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) TO teacher;
GRANT ALL ON FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) TO admin;
GRANT ALL ON FUNCTION public.get_homework_by_duedate(p_class character varying, p_date date) TO sadmin;


--
-- Name: FUNCTION get_student_marks(p_student_id integer, p_from date, p_to date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_student_marks(p_student_id integer, p_from date, p_to date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_student_marks(p_student_id integer, p_from date, p_to date) TO student;
GRANT ALL ON FUNCTION public.get_student_marks(p_student_id integer, p_from date, p_to date) TO parent;
GRANT ALL ON FUNCTION public.get_student_marks(p_student_id integer, p_from date, p_to date) TO admin;


--
-- Name: FUNCTION get_teacher_salary(p_teacher_id integer, p_from date, p_to date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_teacher_salary(p_teacher_id integer, p_from date, p_to date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_teacher_salary(p_teacher_id integer, p_from date, p_to date) TO teacher;
GRANT ALL ON FUNCTION public.get_teacher_salary(p_teacher_id integer, p_from date, p_to date) TO admin;


--
-- Name: FUNCTION get_timetable_id_by_student_id(p_student_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_timetable_id_by_student_id(p_student_id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_timetable_id_by_student_id(p_student_id integer) TO student;
GRANT ALL ON FUNCTION public.get_timetable_id_by_student_id(p_student_id integer) TO parent;
GRANT ALL ON FUNCTION public.get_timetable_id_by_student_id(p_student_id integer) TO admin;
GRANT ALL ON FUNCTION public.get_timetable_id_by_student_id(p_student_id integer) TO sadmin;


--
-- Name: FUNCTION get_user_role(p_user_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_user_role(p_user_id integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_user_role(p_user_id integer) TO guest;
GRANT ALL ON FUNCTION public.get_user_role(p_user_id integer) TO admin;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.hmac(bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.hmac(text, text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.hmac(text, text, text) TO admin;
GRANT ALL ON FUNCTION public.hmac(text, text, text) TO sadmin;


--
-- Name: FUNCTION homework_by_date_subject(p_date date, p_subject integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.homework_by_date_subject(p_date date, p_subject integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.homework_by_date_subject(p_date date, p_subject integer) TO student;
GRANT ALL ON FUNCTION public.homework_by_date_subject(p_date date, p_subject integer) TO parent;
GRANT ALL ON FUNCTION public.homework_by_date_subject(p_date date, p_subject integer) TO admin;


--
-- Name: FUNCTION login_user(p_login text, p_password text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.login_user(p_login text, p_password text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.login_user(p_login text, p_password text) TO guest;
GRANT ALL ON FUNCTION public.login_user(p_login text, p_password text) TO admin;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO admin;
GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO sadmin;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_key_id(bytea) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO admin;
GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO sadmin;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO sadmin;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO sadmin;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO sadmin;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO sadmin;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO sadmin;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO sadmin;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO sadmin;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_encrypt(text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO sadmin;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO admin;
GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO sadmin;


--
-- Name: PROCEDURE proc_assign_role_to_user(IN p_user_id integer, IN p_role_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_assign_role_to_user(IN p_user_id integer, IN p_role_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_assign_role_to_user(IN p_user_id integer, IN p_role_id integer) TO sadmin;


--
-- Name: PROCEDURE proc_assign_student_parent(IN p_student_id integer, IN p_parent_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_assign_student_parent(IN p_student_id integer, IN p_parent_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_assign_student_parent(IN p_student_id integer, IN p_parent_id integer) TO admin;


--
-- Name: PROCEDURE proc_assign_user_to_entity(IN p_user_id integer, IN p_entity_type text, IN p_entity_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_assign_user_to_entity(IN p_user_id integer, IN p_entity_type text, IN p_entity_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_assign_user_to_entity(IN p_user_id integer, IN p_entity_type text, IN p_entity_id integer) TO sadmin;


--
-- Name: PROCEDURE proc_create_audit_log(IN p_table_name character varying, IN p_operation character varying, IN p_record_id text, IN p_details text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_audit_log(IN p_table_name character varying, IN p_operation character varying, IN p_record_id text, IN p_details text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_audit_log(IN p_table_name character varying, IN p_operation character varying, IN p_record_id text, IN p_details text) TO teacher;
GRANT ALL ON PROCEDURE public.proc_create_audit_log(IN p_table_name character varying, IN p_operation character varying, IN p_record_id text, IN p_details text) TO admin;


--
-- Name: PROCEDURE proc_create_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer) TO admin;


--
-- Name: PROCEDURE proc_create_day(IN p_subject integer, IN p_timetable integer, IN p_day_time time without time zone, IN p_day_weekday character varying, OUT new_day_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_day(IN p_subject integer, IN p_timetable integer, IN p_day_time time without time zone, IN p_day_weekday character varying, OUT new_day_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_day(IN p_subject integer, IN p_timetable integer, IN p_day_time time without time zone, IN p_day_weekday character varying, OUT new_day_id integer) TO admin;


--
-- Name: PROCEDURE proc_create_homework(INOUT p_name character varying, IN p_teacher integer, IN p_lesson integer, INOUT p_duedate date, INOUT p_desc text, IN p_class character varying, OUT new_homework_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_homework(INOUT p_name character varying, IN p_teacher integer, IN p_lesson integer, INOUT p_duedate date, INOUT p_desc text, IN p_class character varying, OUT new_homework_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_homework(INOUT p_name character varying, IN p_teacher integer, IN p_lesson integer, INOUT p_duedate date, INOUT p_desc text, IN p_class character varying, OUT new_homework_id integer) TO teacher;
GRANT ALL ON PROCEDURE public.proc_create_homework(INOUT p_name character varying, IN p_teacher integer, IN p_lesson integer, INOUT p_duedate date, INOUT p_desc text, IN p_class character varying, OUT new_homework_id integer) TO admin;


--
-- Name: PROCEDURE proc_create_journal(IN p_journal_teacher integer, IN p_journal_name character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_journal(IN p_journal_teacher integer, IN p_journal_name character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_journal(IN p_journal_teacher integer, IN p_journal_name character varying) TO admin;


--
-- Name: PROCEDURE proc_create_lesson(IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone, OUT new_lesson_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_lesson(IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone, OUT new_lesson_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_lesson(IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone, OUT new_lesson_id integer) TO teacher;
GRANT ALL ON PROCEDURE public.proc_create_lesson(IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone, OUT new_lesson_id integer) TO admin;


--
-- Name: PROCEDURE proc_create_material(IN p_name character varying, IN p_desc text, IN p_link text, OUT new_material_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_material(IN p_name character varying, IN p_desc text, IN p_link text, OUT new_material_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_material(IN p_name character varying, IN p_desc text, IN p_link text, OUT new_material_id integer) TO admin;


--
-- Name: PROCEDURE proc_create_parent(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_parent_id integer, OUT generated_password text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_parent(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_parent_id integer, OUT generated_password text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_parent(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_parent_id integer, OUT generated_password text) TO admin;


--
-- Name: PROCEDURE proc_create_role(IN p_role_name character varying, IN p_role_desc text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_role(IN p_role_name character varying, IN p_role_desc text) FROM PUBLIC;


--
-- Name: PROCEDURE proc_create_student(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying, OUT new_student_id integer, OUT generated_password text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_student(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying, OUT new_student_id integer, OUT generated_password text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_student(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying, OUT new_student_id integer, OUT generated_password text) TO admin;


--
-- Name: PROCEDURE proc_create_studentdata(IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, INOUT p_note text, OUT new_data_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_studentdata(IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, INOUT p_note text, OUT new_data_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_studentdata(IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, INOUT p_note text, OUT new_data_id integer) TO teacher;


--
-- Name: PROCEDURE proc_create_subject(IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_subject(IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_subject(IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text) TO admin;


--
-- Name: PROCEDURE proc_create_teacher(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_teacher_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_teacher(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_teacher_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_teacher(IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, OUT new_teacher_id integer) TO admin;


--
-- Name: PROCEDURE proc_create_timetable(IN p_timetable_name character varying, IN p_timetable_class character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_timetable(IN p_timetable_name character varying, IN p_timetable_class character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_timetable(IN p_timetable_name character varying, IN p_timetable_class character varying) TO admin;


--
-- Name: PROCEDURE proc_create_user(IN p_username character varying, IN p_email character varying, IN p_password character varying, OUT new_user_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_create_user(IN p_username character varying, IN p_email character varying, IN p_password character varying, OUT new_user_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_create_user(IN p_username character varying, IN p_email character varying, IN p_password character varying, OUT new_user_id integer) TO sadmin;


--
-- Name: PROCEDURE proc_delete_class(IN p_class_name character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_class(IN p_class_name character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_class(IN p_class_name character varying) TO admin;


--
-- Name: PROCEDURE proc_delete_day(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_day(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_day(IN p_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_homework(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_homework(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_homework(IN p_id integer) TO teacher;
GRANT ALL ON PROCEDURE public.proc_delete_homework(IN p_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_journal(IN p_journal_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_journal(IN p_journal_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_journal(IN p_journal_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_lesson(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_lesson(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_lesson(IN p_id integer) TO teacher;
GRANT ALL ON PROCEDURE public.proc_delete_lesson(IN p_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_material(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_material(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_material(IN p_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_parent(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_parent(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_parent(IN p_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_role(IN p_role_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_role(IN p_role_id integer) FROM PUBLIC;


--
-- Name: PROCEDURE proc_delete_student(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_student(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_student(IN p_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_studentdata(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_studentdata(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_studentdata(IN p_id integer) TO teacher;


--
-- Name: PROCEDURE proc_delete_subject(IN p_subject_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_subject(IN p_subject_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_subject(IN p_subject_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_teacher(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_teacher(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_teacher(IN p_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_timetable(IN p_timetable_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_timetable(IN p_timetable_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_timetable(IN p_timetable_id integer) TO admin;


--
-- Name: PROCEDURE proc_delete_user(IN p_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_delete_user(IN p_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_delete_user(IN p_id integer) TO sadmin;


--
-- Name: PROCEDURE proc_register_user(IN p_username character varying, IN p_email character varying, IN p_password text, OUT new_user_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_register_user(IN p_username character varying, IN p_email character varying, IN p_password text, OUT new_user_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_register_user(IN p_username character varying, IN p_email character varying, IN p_password text, OUT new_user_id integer) TO guest;


--
-- Name: PROCEDURE proc_remove_role_from_user(IN p_user_id integer, IN p_role_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_remove_role_from_user(IN p_user_id integer, IN p_role_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_remove_role_from_user(IN p_user_id integer, IN p_role_id integer) TO sadmin;


--
-- Name: PROCEDURE proc_reset_user_password(IN p_user_id integer, IN p_new_password character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_reset_user_password(IN p_user_id integer, IN p_new_password character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_reset_user_password(IN p_user_id integer, IN p_new_password character varying) TO admin;


--
-- Name: PROCEDURE proc_unassign_student_parent(IN p_student_id integer, IN p_parent_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_unassign_student_parent(IN p_student_id integer, IN p_parent_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_unassign_student_parent(IN p_student_id integer, IN p_parent_id integer) TO admin;


--
-- Name: PROCEDURE proc_update_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_class(IN p_class_name character varying, IN p_class_journal_id integer, IN p_class_mainteacher integer) TO admin;


--
-- Name: PROCEDURE proc_update_day(IN p_id integer, IN p_subject integer, IN p_timetable integer, IN p_time time without time zone, IN p_weekday character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_day(IN p_id integer, IN p_subject integer, IN p_timetable integer, IN p_time time without time zone, IN p_weekday character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_day(IN p_id integer, IN p_subject integer, IN p_timetable integer, IN p_time time without time zone, IN p_weekday character varying) TO admin;


--
-- Name: PROCEDURE proc_update_homework(IN p_id integer, IN p_name character varying, IN p_teacher integer, IN p_lesson integer, IN p_duedate date, IN p_desc text, IN p_class character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_homework(IN p_id integer, IN p_name character varying, IN p_teacher integer, IN p_lesson integer, IN p_duedate date, IN p_desc text, IN p_class character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_homework(IN p_id integer, IN p_name character varying, IN p_teacher integer, IN p_lesson integer, IN p_duedate date, IN p_desc text, IN p_class character varying) TO teacher;
GRANT ALL ON PROCEDURE public.proc_update_homework(IN p_id integer, IN p_name character varying, IN p_teacher integer, IN p_lesson integer, IN p_duedate date, IN p_desc text, IN p_class character varying) TO admin;


--
-- Name: PROCEDURE proc_update_journal(IN p_journal_id integer, IN p_journal_teacher integer, IN p_journal_name character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_journal(IN p_journal_id integer, IN p_journal_teacher integer, IN p_journal_name character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_journal(IN p_journal_id integer, IN p_journal_teacher integer, IN p_journal_name character varying) TO admin;


--
-- Name: PROCEDURE proc_update_lesson(IN p_lesson_id integer, IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_lesson(IN p_lesson_id integer, IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_lesson(IN p_lesson_id integer, IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone) TO teacher;
GRANT ALL ON PROCEDURE public.proc_update_lesson(IN p_lesson_id integer, IN p_name character varying, IN p_class character varying, IN p_subject integer, IN p_material integer, IN p_teacher integer, IN p_date timestamp without time zone) TO admin;


--
-- Name: PROCEDURE proc_update_material(IN p_id integer, IN p_name character varying, IN p_desc text, IN p_link text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_material(IN p_id integer, IN p_name character varying, IN p_desc text, IN p_link text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_material(IN p_id integer, IN p_name character varying, IN p_desc text, IN p_link text) TO admin;


--
-- Name: PROCEDURE proc_update_parent(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_parent(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_parent(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer) TO admin;


--
-- Name: PROCEDURE proc_update_role(IN p_role_id integer, IN p_role_name character varying, IN p_role_desc text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_role(IN p_role_id integer, IN p_role_name character varying, IN p_role_desc text) FROM PUBLIC;


--
-- Name: PROCEDURE proc_update_student(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_student(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_student(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer, IN p_class character varying) TO admin;


--
-- Name: PROCEDURE proc_update_studentdata(IN p_id integer, IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, IN p_note text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_studentdata(IN p_id integer, IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, IN p_note text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_studentdata(IN p_id integer, IN p_journal_id integer, IN p_student_id integer, IN p_lesson integer, IN p_mark smallint, IN p_status public.journal_status_enum, IN p_note text) TO teacher;


--
-- Name: PROCEDURE proc_update_subject(IN p_subject_id integer, IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_subject(IN p_subject_id integer, IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_subject(IN p_subject_id integer, IN p_subject_name text, IN p_cabinet integer, IN p_subject_program text) TO admin;


--
-- Name: PROCEDURE proc_update_teacher(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_teacher(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_teacher(IN p_id integer, IN p_name character varying, IN p_surname character varying, IN p_patronym character varying, IN p_phone character varying, IN p_user_id integer) TO admin;


--
-- Name: PROCEDURE proc_update_timetable(IN p_timetable_id integer, IN p_timetable_name character varying, IN p_timetable_class character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_timetable(IN p_timetable_id integer, IN p_timetable_name character varying, IN p_timetable_class character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_timetable(IN p_timetable_id integer, IN p_timetable_name character varying, IN p_timetable_class character varying) TO admin;


--
-- Name: PROCEDURE proc_update_user(IN p_id integer, IN p_username character varying, IN p_email character varying, IN p_password character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.proc_update_user(IN p_id integer, IN p_username character varying, IN p_email character varying, IN p_password character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.proc_update_user(IN p_id integer, IN p_username character varying, IN p_email character varying, IN p_password character varying) TO sadmin;


--
-- Name: FUNCTION student_attendance_report(p_student_id integer, p_from date, p_to date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.student_attendance_report(p_student_id integer, p_from date, p_to date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.student_attendance_report(p_student_id integer, p_from date, p_to date) TO student;
GRANT ALL ON FUNCTION public.student_attendance_report(p_student_id integer, p_from date, p_to date) TO parent;
GRANT ALL ON FUNCTION public.student_attendance_report(p_student_id integer, p_from date, p_to date) TO admin;


--
-- Name: FUNCTION student_day_plan(p_student_id integer, p_date date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.student_day_plan(p_student_id integer, p_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.student_day_plan(p_student_id integer, p_date date) TO student;
GRANT ALL ON FUNCTION public.student_day_plan(p_student_id integer, p_date date) TO parent;
GRANT ALL ON FUNCTION public.student_day_plan(p_student_id integer, p_date date) TO admin;


--
-- Name: FUNCTION translit_uk_to_lat(p_text text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.translit_uk_to_lat(p_text text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.translit_uk_to_lat(p_text text) TO guest;
GRANT ALL ON FUNCTION public.translit_uk_to_lat(p_text text) TO admin;


--
-- Name: FUNCTION trg_check_timetable_conflict(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_check_timetable_conflict() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_check_timetable_conflict() TO admin;
GRANT ALL ON FUNCTION public.trg_check_timetable_conflict() TO sadmin;


--
-- Name: FUNCTION trg_prevent_fast_double_mark(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_prevent_fast_double_mark() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_prevent_fast_double_mark() TO admin;
GRANT ALL ON FUNCTION public.trg_prevent_fast_double_mark() TO sadmin;


--
-- Name: FUNCTION trg_unique_user_fields(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_unique_user_fields() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_unique_user_fields() TO admin;
GRANT ALL ON FUNCTION public.trg_unique_user_fields() TO sadmin;


--
-- Name: FUNCTION unaccent(text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.unaccent(text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.unaccent(text) TO admin;
GRANT ALL ON FUNCTION public.unaccent(text) TO sadmin;


--
-- Name: FUNCTION unaccent(regdictionary, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.unaccent(regdictionary, text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.unaccent(regdictionary, text) TO admin;
GRANT ALL ON FUNCTION public.unaccent(regdictionary, text) TO sadmin;


--
-- Name: FUNCTION unaccent_init(internal); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.unaccent_init(internal) FROM PUBLIC;
GRANT ALL ON FUNCTION public.unaccent_init(internal) TO admin;
GRANT ALL ON FUNCTION public.unaccent_init(internal) TO sadmin;


--
-- Name: FUNCTION unaccent_lexize(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.unaccent_lexize(internal, internal, internal, internal) FROM PUBLIC;
GRANT ALL ON FUNCTION public.unaccent_lexize(internal, internal, internal, internal) TO admin;
GRANT ALL ON FUNCTION public.unaccent_lexize(internal, internal, internal, internal) TO sadmin;


--
-- Name: TABLE class; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.class TO student;
GRANT SELECT ON TABLE public.class TO parent;
GRANT SELECT ON TABLE public.class TO teacher;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.class TO admin;
GRANT ALL ON TABLE public.class TO sadmin;
GRANT SELECT ON TABLE public.class TO guest;


--
-- Name: TABLE days; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.days TO admin;
GRANT ALL ON TABLE public.days TO sadmin;
GRANT SELECT ON TABLE public.days TO student;
GRANT SELECT ON TABLE public.days TO guest;


--
-- Name: SEQUENCE days_day_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.days_day_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.days_day_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.days_day_id_seq TO sadmin;


--
-- Name: TABLE homework; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.homework TO student;
GRANT SELECT ON TABLE public.homework TO parent;
GRANT SELECT ON TABLE public.homework TO starosta;
GRANT SELECT ON TABLE public.homework TO teacher;
GRANT SELECT ON TABLE public.homework TO moderator;
GRANT SELECT ON TABLE public.homework TO admin;
GRANT ALL ON TABLE public.homework TO sadmin;
GRANT SELECT ON TABLE public.homework TO guest;


--
-- Name: SEQUENCE homework_homework_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.homework_homework_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.homework_homework_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.homework_homework_id_seq TO sadmin;


--
-- Name: TABLE journal; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.journal TO admin;
GRANT ALL ON TABLE public.journal TO sadmin;
GRANT SELECT ON TABLE public.journal TO student;
GRANT SELECT ON TABLE public.journal TO guest;


--
-- Name: SEQUENCE journal_journal_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.journal_journal_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.journal_journal_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.journal_journal_id_seq TO sadmin;


--
-- Name: TABLE lessons; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.lessons TO student;
GRANT SELECT ON TABLE public.lessons TO parent;
GRANT SELECT ON TABLE public.lessons TO starosta;
GRANT SELECT ON TABLE public.lessons TO teacher;
GRANT SELECT ON TABLE public.lessons TO moderator;
GRANT SELECT ON TABLE public.lessons TO admin;
GRANT ALL ON TABLE public.lessons TO sadmin;
GRANT SELECT ON TABLE public.lessons TO guest;


--
-- Name: SEQUENCE lessons_lesson_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.lessons_lesson_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.lessons_lesson_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.lessons_lesson_id_seq TO sadmin;


--
-- Name: TABLE material; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.material TO moderator;
GRANT SELECT ON TABLE public.material TO admin;
GRANT ALL ON TABLE public.material TO sadmin;
GRANT SELECT ON TABLE public.material TO student;
GRANT SELECT ON TABLE public.material TO guest;


--
-- Name: SEQUENCE material_material_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.material_material_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.material_material_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.material_material_id_seq TO sadmin;


--
-- Name: TABLE parents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.parents TO moderator;
GRANT SELECT ON TABLE public.parents TO admin;
GRANT ALL ON TABLE public.parents TO sadmin;
GRANT SELECT ON TABLE public.parents TO student;
GRANT SELECT ON TABLE public.parents TO guest;


--
-- Name: SEQUENCE parents_parent_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.parents_parent_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.parents_parent_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.parents_parent_id_seq TO sadmin;


--
-- Name: TABLE roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.roles TO admin;
GRANT ALL ON TABLE public.roles TO sadmin;
GRANT SELECT ON TABLE public.roles TO student;
GRANT SELECT ON TABLE public.roles TO guest;


--
-- Name: SEQUENCE roles_role_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.roles_role_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.roles_role_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.roles_role_id_seq TO sadmin;


--
-- Name: TABLE studentdata; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.studentdata TO parent;
GRANT SELECT ON TABLE public.studentdata TO starosta;
GRANT SELECT ON TABLE public.studentdata TO teacher;
GRANT SELECT ON TABLE public.studentdata TO moderator;
GRANT SELECT ON TABLE public.studentdata TO admin;
GRANT ALL ON TABLE public.studentdata TO sadmin;
GRANT SELECT ON TABLE public.studentdata TO student;
GRANT SELECT ON TABLE public.studentdata TO guest;


--
-- Name: SEQUENCE studentdata_data_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.studentdata_data_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.studentdata_data_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.studentdata_data_id_seq TO sadmin;


--
-- Name: TABLE studentparent; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.studentparent TO parent;
GRANT SELECT ON TABLE public.studentparent TO admin;
GRANT ALL ON TABLE public.studentparent TO sadmin;
GRANT SELECT ON TABLE public.studentparent TO student;
GRANT SELECT ON TABLE public.studentparent TO guest;


--
-- Name: TABLE students; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.students TO parent;
GRANT SELECT ON TABLE public.students TO starosta;
GRANT SELECT ON TABLE public.students TO teacher;
GRANT SELECT ON TABLE public.students TO moderator;
GRANT SELECT ON TABLE public.students TO admin;
GRANT ALL ON TABLE public.students TO sadmin;
GRANT SELECT ON TABLE public.students TO student;
GRANT SELECT ON TABLE public.students TO guest;


--
-- Name: SEQUENCE students_student_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.students_student_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.students_student_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.students_student_id_seq TO sadmin;


--
-- Name: TABLE subjects; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.subjects TO student;
GRANT SELECT ON TABLE public.subjects TO teacher;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subjects TO admin;
GRANT ALL ON TABLE public.subjects TO sadmin;
GRANT SELECT ON TABLE public.subjects TO guest;


--
-- Name: SEQUENCE subjects_subject_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.subjects_subject_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.subjects_subject_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.subjects_subject_id_seq TO sadmin;


--
-- Name: TABLE teacher; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.teacher TO moderator;
GRANT SELECT ON TABLE public.teacher TO admin;
GRANT ALL ON TABLE public.teacher TO sadmin;
GRANT SELECT ON TABLE public.teacher TO student;
GRANT SELECT ON TABLE public.teacher TO guest;


--
-- Name: SEQUENCE teacher_teacher_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.teacher_teacher_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.teacher_teacher_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.teacher_teacher_id_seq TO sadmin;


--
-- Name: TABLE timetable; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.timetable TO admin;
GRANT ALL ON TABLE public.timetable TO sadmin;
GRANT SELECT ON TABLE public.timetable TO student;
GRANT SELECT ON TABLE public.timetable TO guest;


--
-- Name: SEQUENCE timetable_timetable_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.timetable_timetable_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.timetable_timetable_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.timetable_timetable_id_seq TO sadmin;


--
-- Name: TABLE userrole; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.userrole TO admin;
GRANT ALL ON TABLE public.userrole TO sadmin;
GRANT SELECT ON TABLE public.userrole TO student;
GRANT SELECT ON TABLE public.userrole TO guest;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.users TO admin;
GRANT ALL ON TABLE public.users TO sadmin;
GRANT SELECT ON TABLE public.users TO student;
GRANT SELECT ON TABLE public.users TO guest;


--
-- Name: SEQUENCE users_user_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.users_user_id_seq TO teacher;
GRANT SELECT,USAGE ON SEQUENCE public.users_user_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.users_user_id_seq TO sadmin;


--
-- Name: TABLE vw_class_attendance_last_month; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_class_attendance_last_month TO admin;
GRANT ALL ON TABLE public.vw_class_attendance_last_month TO sadmin;
GRANT SELECT ON TABLE public.vw_class_attendance_last_month TO student;
GRANT SELECT ON TABLE public.vw_class_attendance_last_month TO guest;
GRANT SELECT ON TABLE public.vw_class_attendance_last_month TO teacher;


--
-- Name: TABLE vw_class_ranking; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_class_ranking TO admin;
GRANT ALL ON TABLE public.vw_class_ranking TO sadmin;
GRANT SELECT ON TABLE public.vw_class_ranking TO student;
GRANT SELECT ON TABLE public.vw_class_ranking TO guest;
GRANT SELECT ON TABLE public.vw_class_ranking TO teacher;


--
-- Name: TABLE vw_homework_by_student_or_class; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_homework_by_student_or_class TO student;
GRANT SELECT ON TABLE public.vw_homework_by_student_or_class TO admin;
GRANT SELECT ON TABLE public.vw_homework_by_student_or_class TO sadmin;
GRANT SELECT ON TABLE public.vw_homework_by_student_or_class TO guest;
GRANT SELECT ON TABLE public.vw_homework_by_student_or_class TO teacher;
GRANT SELECT ON TABLE public.vw_homework_by_student_or_class TO parent;


--
-- Name: TABLE vw_homework_tomorrow; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_homework_tomorrow TO admin;
GRANT ALL ON TABLE public.vw_homework_tomorrow TO sadmin;
GRANT SELECT ON TABLE public.vw_homework_tomorrow TO student;
GRANT SELECT ON TABLE public.vw_homework_tomorrow TO guest;
GRANT SELECT ON TABLE public.vw_homework_tomorrow TO teacher;
GRANT SELECT ON TABLE public.vw_homework_tomorrow TO parent;


--
-- Name: TABLE vw_student_perfomance_matrix; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_student_perfomance_matrix TO teacher;
GRANT SELECT ON TABLE public.vw_student_perfomance_matrix TO student;
GRANT SELECT ON TABLE public.vw_student_perfomance_matrix TO parent;
GRANT SELECT ON TABLE public.vw_student_perfomance_matrix TO admin;
GRANT SELECT ON TABLE public.vw_student_perfomance_matrix TO sadmin;
GRANT SELECT ON TABLE public.vw_student_perfomance_matrix TO guest;


--
-- Name: TABLE vw_student_ranking; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_student_ranking TO student;
GRANT SELECT ON TABLE public.vw_student_ranking TO admin;
GRANT ALL ON TABLE public.vw_student_ranking TO sadmin;
GRANT SELECT ON TABLE public.vw_student_ranking TO guest;


--
-- Name: TABLE vw_students_avg_above_7; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_students_avg_above_7 TO admin;
GRANT ALL ON TABLE public.vw_students_avg_above_7 TO sadmin;
GRANT SELECT ON TABLE public.vw_students_avg_above_7 TO student;
GRANT SELECT ON TABLE public.vw_students_avg_above_7 TO guest;


--
-- Name: TABLE vw_students_by_class; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_students_by_class TO admin;
GRANT ALL ON TABLE public.vw_students_by_class TO sadmin;
GRANT SELECT ON TABLE public.vw_students_by_class TO student;
GRANT SELECT ON TABLE public.vw_students_by_class TO guest;
GRANT SELECT ON TABLE public.vw_students_by_class TO teacher;


--
-- Name: TABLE vw_teacher_analytics; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_teacher_analytics TO teacher;
GRANT SELECT ON TABLE public.vw_teacher_analytics TO admin;
GRANT SELECT ON TABLE public.vw_teacher_analytics TO sadmin;
GRANT SELECT ON TABLE public.vw_teacher_analytics TO guest;


--
-- Name: TABLE vw_teacher_class_students; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_teacher_class_students TO teacher;
GRANT SELECT ON TABLE public.vw_teacher_class_students TO admin;
GRANT SELECT ON TABLE public.vw_teacher_class_students TO sadmin;
GRANT SELECT ON TABLE public.vw_teacher_class_students TO guest;


--
-- Name: TABLE vw_teachers_with_classes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_teachers_with_classes TO admin;
GRANT ALL ON TABLE public.vw_teachers_with_classes TO sadmin;
GRANT SELECT ON TABLE public.vw_teachers_with_classes TO student;
GRANT SELECT ON TABLE public.vw_teachers_with_classes TO guest;
GRANT SELECT ON TABLE public.vw_teachers_with_classes TO teacher;


--
-- Name: TABLE vw_view_timetable_week; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vw_view_timetable_week TO student;
GRANT SELECT ON TABLE public.vw_view_timetable_week TO admin;
GRANT ALL ON TABLE public.vw_view_timetable_week TO sadmin;
GRANT SELECT ON TABLE public.vw_view_timetable_week TO guest;
GRANT SELECT ON TABLE public.vw_view_timetable_week TO teacher;
GRANT SELECT ON TABLE public.vw_view_timetable_week TO parent;


--
-- Name: TABLE vws_audits; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_audits TO sadmin;


--
-- Name: TABLE vws_class_schedule; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_class_schedule TO teacher;
GRANT SELECT ON TABLE public.vws_class_schedule TO student;
GRANT SELECT ON TABLE public.vws_class_schedule TO parent;
GRANT SELECT ON TABLE public.vws_class_schedule TO admin;
GRANT SELECT ON TABLE public.vws_class_schedule TO sadmin;
GRANT SELECT ON TABLE public.vws_class_schedule TO guest;


--
-- Name: TABLE vws_classes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_classes TO teacher;
GRANT SELECT ON TABLE public.vws_classes TO admin;
GRANT SELECT ON TABLE public.vws_classes TO sadmin;
GRANT SELECT ON TABLE public.vws_classes TO guest;


--
-- Name: TABLE vws_days; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_days TO teacher;
GRANT SELECT ON TABLE public.vws_days TO admin;
GRANT SELECT ON TABLE public.vws_days TO sadmin;
GRANT SELECT ON TABLE public.vws_days TO guest;


--
-- Name: TABLE vws_full_journal; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_full_journal TO teacher;
GRANT SELECT ON TABLE public.vws_full_journal TO student;
GRANT SELECT ON TABLE public.vws_full_journal TO parent;
GRANT SELECT ON TABLE public.vws_full_journal TO admin;
GRANT SELECT ON TABLE public.vws_full_journal TO sadmin;
GRANT SELECT ON TABLE public.vws_full_journal TO guest;


--
-- Name: TABLE vws_homeworks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_homeworks TO teacher;
GRANT SELECT ON TABLE public.vws_homeworks TO admin;
GRANT SELECT ON TABLE public.vws_homeworks TO sadmin;
GRANT SELECT ON TABLE public.vws_homeworks TO guest;


--
-- Name: TABLE vws_journals; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_journals TO teacher;
GRANT SELECT ON TABLE public.vws_journals TO admin;
GRANT SELECT ON TABLE public.vws_journals TO sadmin;
GRANT SELECT ON TABLE public.vws_journals TO guest;


--
-- Name: TABLE vws_lessons; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_lessons TO teacher;
GRANT SELECT ON TABLE public.vws_lessons TO admin;


--
-- Name: TABLE vws_materials; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_materials TO teacher;
GRANT SELECT ON TABLE public.vws_materials TO admin;
GRANT SELECT ON TABLE public.vws_materials TO sadmin;
GRANT SELECT ON TABLE public.vws_materials TO guest;


--
-- Name: TABLE vws_parents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_parents TO teacher;
GRANT SELECT ON TABLE public.vws_parents TO admin;
GRANT SELECT ON TABLE public.vws_parents TO sadmin;
GRANT SELECT ON TABLE public.vws_parents TO guest;


--
-- Name: TABLE vws_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_roles TO teacher;
GRANT SELECT ON TABLE public.vws_roles TO admin;
GRANT SELECT ON TABLE public.vws_roles TO sadmin;
GRANT SELECT ON TABLE public.vws_roles TO guest;


--
-- Name: TABLE vws_student_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_student_data TO teacher;
GRANT SELECT ON TABLE public.vws_student_data TO admin;
GRANT SELECT ON TABLE public.vws_student_data TO sadmin;
GRANT SELECT ON TABLE public.vws_student_data TO guest;


--
-- Name: TABLE vws_student_parents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_student_parents TO teacher;
GRANT SELECT ON TABLE public.vws_student_parents TO admin;
GRANT SELECT ON TABLE public.vws_student_parents TO sadmin;
GRANT SELECT ON TABLE public.vws_student_parents TO guest;


--
-- Name: TABLE vws_student_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_student_profile TO teacher;
GRANT SELECT ON TABLE public.vws_student_profile TO student;
GRANT SELECT ON TABLE public.vws_student_profile TO parent;
GRANT SELECT ON TABLE public.vws_student_profile TO admin;
GRANT SELECT ON TABLE public.vws_student_profile TO sadmin;
GRANT SELECT ON TABLE public.vws_student_profile TO guest;


--
-- Name: TABLE vws_students; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_students TO teacher;
GRANT SELECT ON TABLE public.vws_students TO admin;
GRANT SELECT ON TABLE public.vws_students TO sadmin;
GRANT SELECT ON TABLE public.vws_students TO guest;


--
-- Name: TABLE vws_subjects; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_subjects TO teacher;
GRANT SELECT ON TABLE public.vws_subjects TO admin;
GRANT SELECT ON TABLE public.vws_subjects TO sadmin;
GRANT SELECT ON TABLE public.vws_subjects TO guest;


--
-- Name: TABLE vws_teacher_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_teacher_profile TO teacher;
GRANT SELECT ON TABLE public.vws_teacher_profile TO admin;
GRANT SELECT ON TABLE public.vws_teacher_profile TO sadmin;
GRANT SELECT ON TABLE public.vws_teacher_profile TO guest;


--
-- Name: TABLE vws_teachers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_teachers TO teacher;
GRANT SELECT ON TABLE public.vws_teachers TO admin;
GRANT SELECT ON TABLE public.vws_teachers TO sadmin;
GRANT SELECT ON TABLE public.vws_teachers TO guest;


--
-- Name: TABLE vws_timetables; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_timetables TO teacher;
GRANT SELECT ON TABLE public.vws_timetables TO admin;
GRANT SELECT ON TABLE public.vws_timetables TO sadmin;
GRANT SELECT ON TABLE public.vws_timetables TO guest;


--
-- Name: TABLE vws_user_auth_info; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_user_auth_info TO sadmin;


--
-- Name: TABLE vws_user_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_user_roles TO teacher;
GRANT SELECT ON TABLE public.vws_user_roles TO admin;
GRANT SELECT ON TABLE public.vws_user_roles TO sadmin;
GRANT SELECT ON TABLE public.vws_user_roles TO guest;


--
-- Name: TABLE vws_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vws_users TO teacher;
GRANT SELECT ON TABLE public.vws_users TO admin;
GRANT SELECT ON TABLE public.vws_users TO sadmin;
GRANT SELECT ON TABLE public.vws_users TO guest;


--
-- PostgreSQL database dump complete
--

\unrestrict I6CIjYrKRpVuxhnlKWAodXhoAHUoHCWtBdVXSPOIVFH4aY8NGbNIrbfWr5W6tK7

