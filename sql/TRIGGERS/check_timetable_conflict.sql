CREATE OR REPLACE FUNCTION public.trg_check_timetable_conflict()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM lessons l
        WHERE
            l.lesson_date = NEW.lesson_date
            AND (
                l.lesson_teacher = NEW.lesson_teacher
                OR l.lesson_class = NEW.lesson_class
            )
            -- avoid self-conflict on UPDATE
            AND l.lesson_id <> COALESCE(NEW.lesson_id, -1)
    ) THEN
        RAISE EXCEPTION
            'Schedule conflict: teacher or class already occupied at this exact time';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER check_timetable_conflict
	BEFORE INSERT ON Lessons
	FOR EACH ROW
	EXECUTE FUNCTION trg_check_timetable_conflict();
