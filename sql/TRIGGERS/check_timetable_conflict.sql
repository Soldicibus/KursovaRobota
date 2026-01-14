CREATE OR REPLACE FUNCTION trg_check_timetable_conflict()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
	BEGIN
	    IF EXISTS (
	        SELECT 1
	        FROM Lessons
	        WHERE lesson_date = NEW.lesson_date
	          AND (
	                lesson_teacher = NEW.lesson_teacher
	             OR lesson_class = NEW.lesson_class
	          )
	    ) THEN
	        RAISE EXCEPTION 'Schedule conflict: teacher or class already occupied';
	    END IF;
	
	    RETURN NEW;
	END;
$$;

CREATE TRIGGER check_timetable_conflict
	BEFORE INSERT ON Lessons
	FOR EACH ROW
	EXECUTE FUNCTION trg_check_timetable_conflict();
