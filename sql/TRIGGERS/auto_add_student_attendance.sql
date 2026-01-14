CREATE OR REPLACE FUNCTION proc_auto_add_attendance()
RETURNS TRIGGER AS $$
DECLARE
    v_journal_id INT;
BEGIN
    SELECT class_journal_id INTO v_journal_id
    FROM Class
    WHERE class_name = NEW.lesson_class;

    IF v_journal_id IS NOT NULL THEN
        INSERT INTO StudentData (journal_id, student_id, lesson, status)
        SELECT 
            v_journal_id,
            s.student_id,
            NEW.lesson_id,
            'П'::journal_status_enum -- Default status 'П'
        FROM Students s
        WHERE s.student_class = NEW.lesson_class;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if it already exists to avoid errors on recreation
DROP TRIGGER IF EXISTS trg_auto_add_attendance ON Lessons;

CREATE TRIGGER trg_auto_add_attendance
AFTER INSERT ON Lessons
FOR EACH ROW
EXECUTE FUNCTION proc_auto_add_attendance();
