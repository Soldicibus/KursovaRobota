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

    CALL proc_create_audit_log('Timetable', 'INSERT', p_timetable_name, 'Created timetable ' || p_timetable_name);
END;
$$;
