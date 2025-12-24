CREATE OR REPLACE PROCEDURE proc_update_studentdata(
    IN p_id integer,
    IN p_journal_id integer DEFAULT NULL,
    IN p_student_id integer DEFAULT NULL,
    IN p_lesson integer DEFAULT NULL,
    IN p_mark smallint DEFAULT NULL,
    IN p_status journal_status_enum DEFAULT NULL,
    IN p_note text DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM studentdata WHERE data_id = p_id
    ) THEN
        RAISE EXCEPTION 'Studentdata % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;

    p_note := NULLIF(trim(p_note), '');

    IF p_journal_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM journal WHERE journal_id = p_journal_id
    ) THEN
        RAISE EXCEPTION 'Journal % does not exist', p_journal_id
        USING ERRCODE = '22003';
    END IF;

    IF p_student_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM students WHERE student_id = p_student_id
    ) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id
        USING ERRCODE = '22003';
    END IF;

    IF p_lesson IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM lessons WHERE lesson_id = p_lesson
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
END;
$$;
