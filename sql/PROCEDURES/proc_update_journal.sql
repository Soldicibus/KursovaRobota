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
    SET journal_teacher = p_journal_teacher,
        journal_name = NULLIF(TRIM(p_journal_name), '')
    WHERE journal_id = p_journal_id;

    CALL proc_create_audit_log('Journal', 'UPDATE', p_journal_id::TEXT, 'Updated journal ' || p_journal_id);
END;
$$;
