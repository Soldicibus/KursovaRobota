CREATE OR REPLACE VIEW vws_class_schedule AS
SELECT 
    t.timetable_name,
    t.timetable_class,
    d.day_weekday,
    d.day_time,
    s.subject_name,
    s.cabinet,
    te.teacher_surname AS main_teacher
FROM Timetable t
JOIN Days d ON t.timetable_id = d.day_timetable
JOIN Subjects s ON d.day_subject = s.subject_id
LEFT JOIN Class c ON t.timetable_class = c.class_name
LEFT JOIN Teacher te ON c.class_mainTeacher = te.teacher_id
ORDER BY 
    t.timetable_class,
    CASE d.day_weekday 
        WHEN 'Понеділок' THEN 1 
        WHEN 'Вівторок' THEN 2 
        WHEN 'Середа' THEN 3 
        WHEN 'Четвер' THEN 4 
        WHEN 'П’ятниця' THEN 5 
    END,
    d.day_time;