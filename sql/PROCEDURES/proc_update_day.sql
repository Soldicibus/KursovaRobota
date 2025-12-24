CREATE OR REPLACE PROCEDURE proc_update_day
(
    IN p_id integer,
    IN p_subject integer,
	IN p_timetable integer,
    IN p_time time DEFAULT NULL,
    IN p_weekday varchar(20) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM days WHERE day_id = p_id
    ) THEN
        RAISE EXCEPTION 'Day % does not exist', p_id
        USING ERRCODE = '22003';
    END IF;
	
	IF NOT EXISTS (
        SELECT 1 FROM timetable WHERE timetable_id = p_timetable
    ) THEN
        RAISE EXCEPTION 'Timetable % does not exist', p_timetable
        USING ERRCODE = '22003';
    END IF;

	IF NOT EXISTS (
        SELECT 1 FROM subjects WHERE subject_id = p_subject
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
END;
$$;