CREATE OR REPLACE VIEW vws_full_journal AS
SELECT 
    sd.data_id,
    j.journal_name,
    cl.class_name,
    sub.subject_name,
    l.lesson_date,
    l.lesson_name,
    s.student_id,
    s.student_name || ' ' || s.student_surname || ' ' || s.student_patronym  AS student_full_name,
    sd.mark,
    sd.status,
    sd.note,
    t.teacher_name || ' ' || t.teacher_surname AS teacher
FROM StudentData sd
JOIN Journal j ON sd.journal_id = j.journal_id
JOIN Lessons l ON sd.lesson = l.lesson_id
JOIN Subjects sub ON l.lesson_subject = sub.subject_id
JOIN Students s ON sd.student_id = s.student_id
JOIN Class cl ON s.student_class = cl.class_name
JOIN Teacher t ON l.lesson_teacher = t.teacher_id;