CREATE OR REPLACE VIEW vw_homework_tomorrow AS
SELECT
    homework_id,
    homework_name,
    homework_desc,
    homework_class
FROM Homework
WHERE homework_duedate = CURRENT_DATE + INTERVAL '1 day';
