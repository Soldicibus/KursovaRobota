
-- =================================================================================================
-- DATABASE PERMISSIONS SCRIPT
-- Based on User Role Permissions Matrix
--
-- NOTE:
-- In PostgreSQL:
-- - GRANT EXECUTE ON FUNCTION allows using the function in SELECT statements.
-- - GRANT EXECUTE ON PROCEDURE allows using the CALL statement.
-- =================================================================================================

-- 1. RESET PUBLIC PERMISSIONS
-- Revoke all default permissions from public to ensure a clean slate
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL PROCEDURES IN SCHEMA public FROM PUBLIC;

-- 2. CREATE ROLES
-- Create roles if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'guest') THEN CREATE ROLE guest; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'student') THEN CREATE ROLE student; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'parent') THEN CREATE ROLE parent; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'teacher') THEN CREATE ROLE teacher; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin') THEN CREATE ROLE admin; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sadmin') THEN CREATE ROLE sadmin; END IF;
END
$$;

-- 3. ROLE INHERITANCE
-- Setup the inheritance hierarchy as defined
GRANT guest TO student;
GRANT guest TO parent;
GRANT guest TO teacher;
GRANT guest TO admin;
GRANT admin TO sadmin;

-- 4. SCHEMA AND SEQUENCE PERMISSIONS
-- Grant usage on schema to allow access to objects
GRANT USAGE ON SCHEMA public TO guest;

-- Grant usage on sequences to allow INSERTs (for roles that can create data)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO sadmin;

-- =================================================================================================
-- GUEST ROLE PERMISSIONS (Base Role)
-- =================================================================================================
-- Functions (Read)
GRANT EXECUTE ON FUNCTION get_data_by_user_id(INT) TO guest;
GRANT EXECUTE ON FUNCTION translit_uk_to_lat(TEXT) TO guest;
GRANT EXECUTE ON FUNCTION login_user(TEXT, TEXT) TO guest;

-- Procedures (Write)
GRANT EXECUTE ON PROCEDURE proc_register_user(VARCHAR, VARCHAR, TEXT, INT) TO guest;
GRANT EXECUTE ON PROCEDURE proc_reset_user_password(INT, VARCHAR) TO guest;

-- =================================================================================================
-- STUDENT ROLE PERMISSIONS
-- =================================================================================================
-- Functions (Read)
GRANT EXECUTE ON FUNCTION get_student_marks(INT, DATE, DATE) TO student;
GRANT EXECUTE ON FUNCTION get_student_grade_entries(INT, DATE, DATE) TO student;
GRANT EXECUTE ON FUNCTION get_homework_by_duedate(VARCHAR, DATE) TO student;
GRANT EXECUTE ON FUNCTION get_homework_by_createdate(VARCHAR, DATE) TO student;
GRANT EXECUTE ON FUNCTION student_attendance_report(INT, DATE, DATE) TO student;
GRANT EXECUTE ON FUNCTION get_timetable_id_by_student_id(INT) TO student;

-- Views (Read)
GRANT SELECT ON vw_homework_by_student_or_class TO student;

-- =================================================================================================
-- PARENT ROLE PERMISSIONS
-- =================================================================================================
-- Functions (Read)
GRANT EXECUTE ON FUNCTION get_children_by_parent(INT) TO parent;
GRANT EXECUTE ON FUNCTION get_student_marks(INT, DATE, DATE) TO parent;
GRANT EXECUTE ON FUNCTION get_timetable_id_by_student_id(INT) TO parent;
GRANT EXECUTE ON FUNCTION student_attendance_report(INT, DATE, DATE) TO parent;
GRANT EXECUTE ON FUNCTION get_homework_by_duedate(VARCHAR, DATE) TO parent;
GRANT EXECUTE ON FUNCTION get_homework_by_createdate(VARCHAR, DATE) TO parent;

-- =================================================================================================
-- TEACHER ROLE PERMISSIONS
-- =================================================================================================
-- Functions (Read)
GRANT EXECUTE ON FUNCTION get_teacher_salary(INT, DATE, DATE) TO teacher;
GRANT EXECUTE ON FUNCTION get_homework_by_duedate(VARCHAR, DATE) TO teacher;
GRANT EXECUTE ON FUNCTION get_homework_by_createdate(VARCHAR, DATE) TO teacher;
-- Grant execute on other teacher-related functions (assuming existence based on description)
-- GRANT EXECUTE ON FUNCTION get_teacher_scheduleINT TO teacher; 

-- Views (Read)
GRANT SELECT ON vw_teacher_class_students TO teacher;

-- Procedures (Write)
GRANT EXECUTE ON PROCEDURE proc_create_lesson(VARCHAR, VARCHAR, INT, INT, INT, DATE) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_create_homework(VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_update_homework(INT, VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_delete_homework(INT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_create_studentdata(INT, INT, INT, SMALLINT, journal_status_enum, TEXT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_update_studentdata(INT, INT, INT, INT, SMALLINT, journal_status_enum, TEXT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_delete_studentdata(INT) TO teacher;

-- =================================================================================================
-- ADMIN ROLE PERMISSIONS
-- =================================================================================================
-- Direct Table Access (CRUD) for tables without procedures
GRANT INSERT, UPDATE, DELETE, SELECT ON Subjects TO admin;
GRANT INSERT, UPDATE, DELETE, SELECT ON Class TO admin;
GRANT INSERT, UPDATE, DELETE, SELECT ON Journal TO admin;
GRANT INSERT, UPDATE, DELETE, SELECT ON Timetable TO admin;

-- Functions & Views (Read) - ALL
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO admin; -- Read access to all tables/views

-- Procedures (Write)
-- Users (except create/update/delete)
GRANT EXECUTE ON PROCEDURE proc_reset_user_password(INT, VARCHAR) TO admin;
-- Students
GRANT EXECUTE ON PROCEDURE proc_create_student(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_update_student(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_delete_student(INT) TO sadmin;
-- Parents
GRANT EXECUTE ON PROCEDURE proc_create_parent(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_update_parent(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_delete_parent(INT) TO sadmin;
-- Teachers
GRANT EXECUTE ON PROCEDURE proc_create_teacher(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_update_teacher(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_teacher(INT) TO sadmin;
-- Lessons
GRANT EXECUTE ON PROCEDURE proc_create_lesson(VARCHAR, VARCHAR, INT, INT, INT, DATE) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_lesson(INT, VARCHAR, VARCHAR, INT, INT, INT, DATE) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_lesson(INT) TO admin;
-- Homework
GRANT EXECUTE ON PROCEDURE proc_create_homework(VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_homework(INT, VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO admin;
-- StudentData
GRANT EXECUTE ON PROCEDURE proc_create_studentdata(INT, INT, INT, SMALLINT, journal_status_enum, TEXT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_studentdata(INT, INT, INT, INT, SMALLINT, journal_status_enum, TEXT) TO admin;
-- Materials
GRANT EXECUTE ON PROCEDURE proc_create_material(VARCHAR, TEXT, TEXT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_material(INT, VARCHAR, TEXT, TEXT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_material(INT) TO admin;
-- Days
GRANT EXECUTE ON PROCEDURE proc_create_day(INT, INT, TIME, VARCHAR, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_day(INT, INT, INT, TIME, VARCHAR) TO admin;
-- Role Management
REVOKE EXECUTE ON PROCEDURE proc_assign_role_to_user(INT, INT) FROM admin;
REVOKE EXECUTE ON PROCEDURE proc_remove_role_from_user(INT, INT) FROM admin;
GRANT EXECUTE ON PROCEDURE proc_assign_student_parent(INT, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_unassign_student_parent(INT, INT) TO admin;


-- =================================================================================================
-- sADMIN ROLE PERMISSIONS
-- =================================================================================================
-- Direct Table Access (CRUD) for tables without procedures + Roles
GRANT INSERT, UPDATE, DELETE, SELECT ON Subjects TO sadmin;
GRANT INSERT, UPDATE, DELETE, SELECT ON Class TO sadmin;
GRANT INSERT, UPDATE, DELETE, SELECT ON Journal TO sadmin;
GRANT INSERT, UPDATE, DELETE, SELECT ON Timetable TO sadmin;
GRANT INSERT, UPDATE, DELETE, SELECT ON Roles TO sadmin;

-- Functions & Views (Read) - ALL
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO sadmin;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO sadmin;

-- Procedures (Write) - ALL (Full System Access)
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO sadmin;

-- Explicitly grant User Creation/Deletion (which Admin doesn't have)
GRANT EXECUTE ON PROCEDURE proc_create_user(VARCHAR, VARCHAR, VARCHAR, INT) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_update_user(INT, VARCHAR, VARCHAR, VARCHAR) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_delete_user(INT) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_delete_user(INT) TO sadmin;
