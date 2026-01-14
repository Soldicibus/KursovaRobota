-- ================================
-- ROLES
-- ================================
CREATE ROLE student NOLOGIN;
CREATE ROLE starosta NOLOGIN;
CREATE ROLE parent NOLOGIN;
CREATE ROLE teacher NOLOGIN;
CREATE ROLE moderator NOLOGIN;
CREATE ROLE admin NOLOGIN;
CREATE ROLE superadmin NOLOGIN;

-- ================================
-- LOCK TABLES
-- ================================
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- ================================
-- READ PERMISSIONS
-- ================================
GRANT SELECT ON Lessons, Homework, Subjects, Class TO student;
GRANT SELECT ON Students, StudentParent, StudentData, Lessons, Homework, Class TO parent;
GRANT SELECT ON Students, Lessons, Homework, StudentData TO starosta;
GRANT SELECT ON Lessons, Homework, Students, StudentData, Subjects, Class TO teacher;
GRANT SELECT ON Students, Parents, Teacher, Lessons, Homework, StudentData, Material TO moderator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO superadmin;

-- ================================
-- PROCEDURE EXECUTION RIGHTS
-- ================================
GRANT EXECUTE ON PROCEDURE
proc_create_user, proc_update_user, proc_delete_user,
proc_reset_user_password, proc_assign_role_to_user,
proc_remove_role_from_user
TO admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_student, proc_update_student, proc_delete_student
TO admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_parent, proc_update_parent, proc_delete_parent,
proc_assign_student_parent, proc_unassign_student_parent
TO admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_teacher, proc_update_teacher
TO admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_lesson, proc_update_lesson, proc_delete_lesson
TO moderator, admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_homework, proc_update_homework, proc_delete_homework
TO teacher, moderator, admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_studentdata, proc_update_studentdata
TO teacher, starosta, moderator, admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_delete_studentdata
TO admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_material, proc_update_material
TO moderator, admin, superadmin;

GRANT EXECUTE ON PROCEDURE
proc_create_day, proc_update_day, proc_delete_day
TO admin, superadmin;

-- ================================
-- USERS
-- ================================
CREATE USER student_user PASSWORD 'sus';
GRANT student TO student_user;

CREATE USER starosta_user PASSWORD 'sussy';
GRANT starosta TO starosta_user;

CREATE USER parent_user PASSWORD 'mr_sussy';
GRANT parent TO parent_user;

CREATE USER teacher_user PASSWORD 'teacher_sussy';
GRANT teacher TO teacher_user;

CREATE USER moderator_user PASSWORD 'no_sussy';
GRANT moderator TO moderator_user;

CREATE USER admin_user PASSWORD 'admin_sussy';
GRANT admin TO admin_user;

CREATE USER superadmin_user PASSWORD 'root_sussy';
GRANT superadmin TO superadmin_user;

-- ================================
-- ROLE INHERITANCE
-- ================================
GRANT teacher TO moderator;
GRANT moderator TO admin;
