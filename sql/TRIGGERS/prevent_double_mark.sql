CREATE OR REPLACE FUNCTION trg_prevent_fast_double_mark()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM StudentData
        WHERE student_id = NEW.student_id
          AND lesson = NEW.lesson
          AND created_at > CURRENT_TIMESTAMP - INTERVAL '1 minute'
    ) THEN
        RAISE EXCEPTION 'Mark already added less than a minute ago';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_fast_double_mark ON StudentData;

CREATE TRIGGER prevent_fast_double_mark
BEFORE INSERT ON StudentData
FOR EACH ROW
EXECUTE FUNCTION trg_prevent_fast_double_mark();
