CREATE OR REPLACE PROCEDURE proc_create_day(
    IN p_subject integer,
	IN p_timetable integer,
    IN p_day_time time,
    IN p_day_weekday varchar(20),
    OUT new_day_id integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

    IF NOT p_day_weekday IN ('Понеділок', 'Вівторок', 'Середа', 'Четвер', 'П’ятниця') THEN
        RAISE EXCEPTION 'Invalid weekday: %', p_day_weekday
        USING ERRCODE = '23514';
    END IF;

    INSERT INTO Days(day_subject, day_timetable, day_time, day_weekday)
    VALUES (p_subject, p_timetable, p_day_time, p_day_weekday)
    RETURNING day_id INTO new_day_id;

    CALL proc_create_audit_log('Days', 'INSERT', new_day_id::text, 'Created day');
END;
$$;