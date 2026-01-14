-- Base views for all tables to be used in procedures
CREATE OR REPLACE VIEW vws_users WITH (security_barrier = true) AS 
SELECT 
    u.user_id, 
    u.username, 
    u.email 
FROM Users u
WHERE NOT EXISTS (
    SELECT 1 
    FROM UserRole ur
    JOIN Roles r ON ur.role_id = r.role_id
    WHERE ur.user_id = u.user_id 
    AND r.role_name = 'sadmin'
);
CREATE OR REPLACE VIEW vws_emails AS SELECT u.user_id, u.email FROM Users u;
CREATE OR REPLACE VIEW vws_roles AS SELECT * FROM Roles;
CREATE OR REPLACE VIEW vws_user_roles AS SELECT * FROM UserRole;
CREATE OR REPLACE VIEW vws_teachers AS SELECT * FROM Teacher;
CREATE OR REPLACE VIEW vws_subjects AS SELECT * FROM Subjects;
CREATE OR REPLACE VIEW vws_materials AS SELECT * FROM Material;
CREATE OR REPLACE VIEW vws_journals AS SELECT * FROM Journal;
CREATE OR REPLACE VIEW vws_days AS SELECT * FROM Days;
CREATE OR REPLACE VIEW vws_classes AS SELECT * FROM Class;
CREATE OR REPLACE VIEW vws_timetables AS SELECT * FROM Timetable;
CREATE OR REPLACE VIEW vws_lessons AS SELECT * FROM Lessons;
CREATE OR REPLACE VIEW vws_homeworks AS SELECT * FROM Homework;
CREATE OR REPLACE VIEW vws_students AS SELECT * FROM Students;
CREATE OR REPLACE VIEW vws_parents AS SELECT * FROM Parents;
CREATE OR REPLACE VIEW vws_student_parents AS SELECT * FROM StudentParent;
CREATE OR REPLACE VIEW vws_student_data AS SELECT * FROM StudentData;
CREATE OR REPLACE VIEW vws_audits AS SELECT * FROM AuditLog;
