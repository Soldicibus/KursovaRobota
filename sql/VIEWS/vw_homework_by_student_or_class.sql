DROP VIEW public.vw_homework_by_student_or_class;

CREATE OR REPLACE VIEW public.vw_homework_by_student_or_class
 AS
 SELECT s.student_id,
 	sj.subject_name,
 	h.homework_name,
    h.homework_desc,
    h.homework_id,
    h.homework_duedate
   FROM students s
     JOIN homework h ON h.homework_class::text = s.student_class::text
	 JOIN lessons l ON h.homework_lesson = l.lesson_id
	 JOIN subjects sj ON l.lesson_subject = sj.subject_id;