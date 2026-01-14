CREATE OR REPLACE VIEW vws_student_profile AS
SELECT 
    s.student_id,
    s.student_name,
    s.student_surname,
	s.student_patronym,
    s.student_class,
    s.student_phone,
    u.email,
    u.username
FROM Students s
LEFT JOIN Users u ON s.student_user_id = u.user_id;