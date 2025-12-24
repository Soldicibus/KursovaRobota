CREATE OR REPLACE PROCEDURE proc_delete_day(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM days WHERE day_id = p_id) THEN
        RAISE EXCEPTION 'Day % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM days WHERE day_id = p_id;
END;
$$;
CREATE OR REPLACE PROCEDURE proc_delete_lesson(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM lessons WHERE lesson_id = p_id) THEN
        RAISE EXCEPTION 'Lesson % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM lessons WHERE lesson_id = p_id;
END;
$$;
CREATE OR REPLACE PROCEDURE proc_delete_homework(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM homework WHERE homework_id = p_id) THEN
        RAISE EXCEPTION 'Homework % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM homework WHERE homework_id = p_id;
END;
$$;
CREATE OR REPLACE PROCEDURE proc_delete_studentdata(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM studentdata WHERE data_id = p_id) THEN
        RAISE EXCEPTION 'StudentData % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM studentdata WHERE data_id = p_id;
END;
$$;
CREATE OR REPLACE PROCEDURE proc_delete_user(
    IN p_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_id) THEN
        RAISE EXCEPTION 'User % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    DELETE FROM users WHERE user_id = p_id;
END;
$$;