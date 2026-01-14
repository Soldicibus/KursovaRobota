CREATE OR REPLACE PROCEDURE proc_update_day
(
    IN p_id integer,
    IN p_subject integer,
	IN p_timetable integer,
    IN p_time time DEFAULT NULL,
    IN p_weekday varchar(20) DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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
        day_timetable    = p_timetable,
		day_subject		= COALESCE(p_subject, day_subject),
        day_time    = COALESCE(p_time, day_time),
        day_weekday = p_weekday
    WHERE day_id = p_id;

    CALL proc_create_audit_log('Days', 'UPDATE', p_id::text, 'Updated day');
END;
$$;