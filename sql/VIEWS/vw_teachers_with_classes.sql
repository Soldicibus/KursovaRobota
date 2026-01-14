CREATE OR REPLACE VIEW vw_teachers_with_classes AS
SELECT
    t.teacher_id,
    t.teacher_name,
    t.teacher_surname,
    c.class_name
FROM Teacher t
JOIN Class c
    ON c.class_mainTeacher = t.teacher_id;
