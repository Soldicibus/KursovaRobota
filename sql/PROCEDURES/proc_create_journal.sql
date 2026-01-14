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

    CALL proc_create_audit_log('Journal', 'INSERT', p_journal_name, 'Created journal ' || p_journal_name);
END;
$$;
