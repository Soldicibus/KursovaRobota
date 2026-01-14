CREATE OR REPLACE VIEW vws_teacher_profile AS
SELECT 
    t.teacher_id,
    t.teacher_name,
    t.teacher_surname,
	t.teacher_patronym,
    t.teacher_phone,
    u.email,
    COUNT(c.class_name) as classes_managed
FROM Teacher t
LEFT JOIN Users u ON t.teacher_user_id = u.user_id
LEFT JOIN Class c ON t.teacher_id = c.class_mainTeacher
GROUP BY t.teacher_id, u.email;