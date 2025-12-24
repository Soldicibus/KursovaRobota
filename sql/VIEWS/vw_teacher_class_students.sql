CREATE OR REPLACE VIEW public.vw_teacher_class_students
 AS
 SELECT c.class_mainteacher,
    c.class_name,
    s.student_name,
    s.student_surname,
    s.student_id
   FROM class c
     JOIN teacher t ON c.class_mainteacher = t.teacher_id
     LEFT JOIN students s ON s.student_class::text = c.class_name::text
  ORDER BY c.class_name, s.student_surname, s.student_name;