CREATE OR REPLACE VIEW vws_all_user_details
WITH (security_barrier = true) AS
    -- Students
    SELECT 
        'student' AS role,
        s.student_user_id AS user_id,
        s.student_id AS entity_id,
        s.student_name AS name,
        s.student_surname AS surname,
        s.student_patronym AS patronym,
        u.email,
        s.student_phone AS phone
    FROM students s
    JOIN users u ON u.user_id = s.student_user_id

    UNION ALL

    -- Teachers
    SELECT 
        'teacher' AS role,
        t.teacher_user_id AS user_id,
        t.teacher_id AS entity_id,
        t.teacher_name AS name,
        t.teacher_surname AS surname,
        t.teacher_patronym AS patronym,
        u.email,
        t.teacher_phone AS phone
    FROM teacher t
    JOIN users u ON u.user_id = t.teacher_user_id

    UNION ALL

    -- Parents
    SELECT 
        'parent' AS role,
        p.parent_user_id AS user_id,
        p.parent_id AS entity_id,
        p.parent_name AS name,
        p.parent_surname AS surname,
        p.parent_patronym AS patronym,
        u.email,
        p.parent_phone AS phone
    FROM parents p
    JOIN users u ON u.user_id = p.parent_user_id;