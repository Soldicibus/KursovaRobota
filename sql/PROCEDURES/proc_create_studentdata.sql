CREATE OR REPLACE PROCEDURE proc_create_studentdata(
    IN p_journal_id integer,
    IN p_student_id integer,
    IN p_lesson integer,
    IN p_mark smallint,
    IN p_status journal_status_enum,
    INOUT p_note text,
    OUT new_data_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM journal WHERE journal_id = p_journal_id
    ) THEN
        RAISE EXCEPTION 'Journal % does not exist', p_journal_id
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM students WHERE student_id = p_student_id
    ) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id
        USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM lessons WHERE lesson_id = p_lesson
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
END;
$$;
