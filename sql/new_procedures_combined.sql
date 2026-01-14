CREATE OR REPLACE PROCEDURE proc_create_role(
    IN p_role_name VARCHAR(10),
    IN p_role_desc TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO Roles (role_name, role_desc)
    VALUES (p_role_name, p_role_desc);

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Roles', 'INSERT', p_role_name, SESSION_USER, 'Created role ' || p_role_name);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_role(
    IN p_role_id INT,
    IN p_role_name VARCHAR(10),
    IN p_role_desc TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_id = p_role_id) THEN
        RAISE EXCEPTION 'Role with ID % does not exist', p_role_id;
    END IF;

    UPDATE Roles
    SET role_name = COALESCE(p_role_name, role_name),
        role_desc = COALESCE(p_role_desc, role_desc)
    WHERE role_id = p_role_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Roles', 'UPDATE', p_role_id::TEXT, SESSION_USER, 'Updated role ' || p_role_id);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_role(
    IN p_role_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_id = p_role_id) THEN
        RAISE EXCEPTION 'Role with ID % does not exist', p_role_id;
    END IF;

    DELETE FROM Roles WHERE role_id = p_role_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Roles', 'DELETE', p_role_id::TEXT, SESSION_USER, 'Deleted role ' || p_role_id);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_create_subject(
    IN p_subject_name TEXT,
    IN p_cabinet INT,
    IN p_subject_program TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO Subjects (subject_name, cabinet, subject_program)
    VALUES (p_subject_name, p_cabinet, p_subject_program);

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Subjects', 'INSERT', p_subject_name, SESSION_USER, 'Created subject ' || p_subject_name);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_subject(
    IN p_subject_id INT,
    IN p_subject_name TEXT,
    IN p_cabinet INT,
    IN p_subject_program TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Subjects', 'UPDATE', p_subject_id::TEXT, SESSION_USER, 'Updated subject ' || p_subject_id);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_subject(
    IN p_subject_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Subjects WHERE subject_id = p_subject_id) THEN
        RAISE EXCEPTION 'Subject with ID % does not exist', p_subject_id;
    END IF;

    DELETE FROM Subjects WHERE subject_id = p_subject_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Subjects', 'DELETE', p_subject_id::TEXT, SESSION_USER, 'Deleted subject ' || p_subject_id);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_create_journal(
    IN p_journal_teacher INT,
    IN p_journal_name VARCHAR(50)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO Journal (journal_teacher, journal_name)
    VALUES (p_journal_teacher, p_journal_name);

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Journal', 'INSERT', p_journal_name, SESSION_USER, 'Created journal ' || p_journal_name);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_journal(
    IN p_journal_id INT,
    IN p_journal_teacher INT,
    IN p_journal_name VARCHAR(50)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Journal WHERE journal_id = p_journal_id) THEN
        RAISE EXCEPTION 'Journal with ID % does not exist', p_journal_id;
    END IF;

    UPDATE Journal
    SET journal_teacher = COALESCE(p_journal_teacher, journal_teacher),
        journal_name = COALESCE(p_journal_name, journal_name)
    WHERE journal_id = p_journal_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Journal', 'UPDATE', p_journal_id::TEXT, SESSION_USER, 'Updated journal ' || p_journal_id);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_journal(
    IN p_journal_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Journal WHERE journal_id = p_journal_id) THEN
        RAISE EXCEPTION 'Journal with ID % does not exist', p_journal_id;
    END IF;

    DELETE FROM Journal WHERE journal_id = p_journal_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Journal', 'DELETE', p_journal_id::TEXT, SESSION_USER, 'Deleted journal ' || p_journal_id);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_create_class(
    IN p_class_name VARCHAR(10),
    IN p_class_journal_id INT,
    IN p_class_mainTeacher INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO Class (class_name, class_journal_id, class_mainTeacher)
    VALUES (p_class_name, p_class_journal_id, p_class_mainTeacher);

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Class', 'INSERT', p_class_name, SESSION_USER, 'Created class ' || p_class_name);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_class(
    IN p_class_name VARCHAR(10),
    IN p_class_journal_id INT,
    IN p_class_mainTeacher INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Class WHERE class_name = p_class_name) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class_name;
    END IF;

    UPDATE Class
    SET class_journal_id = COALESCE(p_class_journal_id, class_journal_id),
        class_mainTeacher = COALESCE(p_class_mainTeacher, class_mainTeacher)
    WHERE class_name = p_class_name;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Class', 'UPDATE', p_class_name, SESSION_USER, 'Updated class ' || p_class_name);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_class(
    IN p_class_name VARCHAR(10)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Class WHERE class_name = p_class_name) THEN
        RAISE EXCEPTION 'Class % does not exist', p_class_name;
    END IF;

    DELETE FROM Class WHERE class_name = p_class_name;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Class', 'DELETE', p_class_name, SESSION_USER, 'Deleted class ' || p_class_name);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_create_timetable(
    IN p_timetable_name VARCHAR(20),
    IN p_timetable_class VARCHAR(10)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO Timetable (timetable_name, timetable_class)
    VALUES (p_timetable_name, p_timetable_class);

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Timetable', 'INSERT', p_timetable_name, SESSION_USER, 'Created timetable ' || p_timetable_name);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_timetable(
    IN p_timetable_id INT,
    IN p_timetable_name VARCHAR(20),
    IN p_timetable_class VARCHAR(10)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Timetable WHERE timetable_id = p_timetable_id) THEN
        RAISE EXCEPTION 'Timetable with ID % does not exist', p_timetable_id;
    END IF;

    UPDATE Timetable
    SET timetable_name = COALESCE(p_timetable_name, timetable_name),
        timetable_class = COALESCE(p_timetable_class, timetable_class)
    WHERE timetable_id = p_timetable_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Timetable', 'UPDATE', p_timetable_id::TEXT, SESSION_USER, 'Updated timetable ' || p_timetable_id);
END;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_timetable(
    IN p_timetable_id INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Timetable WHERE timetable_id = p_timetable_id) THEN
        RAISE EXCEPTION 'Timetable with ID % does not exist', p_timetable_id;
    END IF;

    DELETE FROM Timetable WHERE timetable_id = p_timetable_id;

    INSERT INTO AuditLog (table_name, operation, record_id, changed_by, details)
    VALUES ('Timetable', 'DELETE', p_timetable_id::TEXT, SESSION_USER, 'Deleted timetable ' || p_timetable_id);
END;
$$;
