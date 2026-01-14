-- =================================================================================================
-- RESET PERMISSIONS
-- =================================================================================================
-- Revoke all permissions to ensure a clean slate and strict security
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL PROCEDURES IN SCHEMA public FROM PUBLIC;

-- Re-create Roles if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'student') THEN CREATE ROLE student; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'parent') THEN CREATE ROLE parent; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'teacher') THEN CREATE ROLE teacher; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin') THEN CREATE ROLE admin; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sadmin') THEN CREATE ROLE sadmin; END IF;
END
$$;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO defaultuser;
GRANT USAGE ON SCHEMA public TO student;
GRANT USAGE ON SCHEMA public TO parent;
GRANT USAGE ON SCHEMA public TO teacher;
GRANT USAGE ON SCHEMA public TO admin;
GRANT USAGE ON SCHEMA public TO sadmin;

-- =================================================================================================
-- defaultuser (Base Access)
-- =================================================================================================
-- Allow defaultuser to switch to these roles (Required for bouncer.js)
GRANT student TO defaultuser;
GRANT parent TO defaultuser;
GRANT teacher TO defaultuser;
GRANT admin TO defaultuser;
GRANT sadmin TO defaultuser;

GRANT EXECUTE ON FUNCTION login_user(TEXT, TEXT) TO defaultuser;
GRANT EXECUTE ON FUNCTION translit_uk_to_lat(TEXT) TO defaultuser;
GRANT EXECUTE ON FUNCTION get_user_role(INT) TO defaultuser;
GRANT EXECUTE ON PROCEDURE proc_register_user(VARCHAR, VARCHAR, TEXT, INT) TO defaultuser;
GRANT EXECUTE ON PROCEDURE proc_reset_user_password(INT, VARCHAR) TO defaultuser;

-- =================================================================================================
-- STUDENT
-- =================================================================================================
GRANT EXECUTE ON FUNCTION get_data_by_user_id(INT) TO student;
GRANT SELECT on vws_all_user_details TO student;

-- Functions
GRANT EXECUTE ON FUNCTION get_student_marks(INT, DATE, DATE) TO student;
GRANT EXECUTE ON FUNCTION get_student_grade_entries(INT, TIMESTAMP WITHOUT TIME ZONE, TIMESTAMP WITHOUT TIME ZONE) TO student;
GRANT EXECUTE ON FUNCTION get_homework_by_date_class(VARCHAR, DATE) TO student;
GRANT EXECUTE ON FUNCTION homework_by_date_subject(DATE, INT) TO student;
GRANT EXECUTE ON FUNCTION student_attendance_report(INT, DATE, DATE) TO student;
GRANT EXECUTE ON FUNCTION student_day_plan(INT, DATE) TO student;
GRANT EXECUTE ON FUNCTION get_student_monthly_grades(INT,TIMESTAMP WITHOUT TIME ZONE) TO student;

-- Views
GRANT SELECT ON vws_student_profile TO student;
GRANT SELECT ON vws_class_schedule TO student;
GRANT SELECT ON vws_full_journal TO student;
GRANT SELECT ON vw_homework_tomorrow TO student;
GRANT SELECT ON vw_homework_by_student_or_class TO student;
GRANT SELECT ON vw_view_timetable_week TO student;
GRANT SELECT ON vw_student_perfomance_matrix TO student;
GRANT SELECT ON vw_students_by_class TO student;
GRANT SELECT ON vws_users TO student;

-- =================================================================================================
-- PARENT
-- =================================================================================================
GRANT EXECUTE ON FUNCTION get_data_by_user_id(INT) TO parent;
GRANT SELECT on vws_all_user_details TO parent;

-- Functions
GRANT EXECUTE ON FUNCTION get_children_by_parent(INT) TO parent;
-- Parent acts on behalf of student for read ops
GRANT EXECUTE ON FUNCTION get_student_marks(INT, DATE, DATE) TO parent;
GRANT EXECUTE ON FUNCTION get_student_grade_entries(INT, TIMESTAMP WITHOUT TIME ZONE, TIMESTAMP WITHOUT TIME ZONE) TO parent;
GRANT EXECUTE ON FUNCTION get_homework_by_date_class(VARCHAR, DATE) TO parent;
GRANT EXECUTE ON FUNCTION homework_by_date_subject(DATE, INT) TO parent;
GRANT EXECUTE ON FUNCTION student_attendance_report(INT, DATE, DATE) TO parent;
GRANT EXECUTE ON FUNCTION student_day_plan(INT, DATE) TO parent;
GRANT EXECUTE ON FUNCTION get_student_monthly_grades(INT, TIMESTAMP WITHOUT TIME ZONE) TO parent;
-- Views
GRANT SELECT ON vws_student_profile TO parent;
GRANT SELECT ON vws_class_schedule TO parent;
GRANT SELECT ON vws_full_journal TO parent;
GRANT SELECT ON vw_homework_tomorrow TO parent;
GRANT SELECT ON vw_homework_by_student_or_class TO parent;
GRANT SELECT ON vw_view_timetable_week TO parent;
GRANT SELECT ON vw_student_perfomance_matrix TO parent;

-- =================================================================================================
-- TEACHER
-- =================================================================================================
GRANT student TO teacher; -- Inherit basic read capabilities if useful, or keep separate

-- Functions
GRANT EXECUTE ON FUNCTION get_teacher_salary(INT, DATE, DATE) TO teacher;
GRANT EXECUTE ON FUNCTION absents_more_than_x(VARCHAR, INT) TO teacher;

-- Procedures (Operational)
GRANT EXECUTE ON PROCEDURE proc_create_homework(VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_update_homework(INT, VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_delete_homework(INT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_create_lesson(VARCHAR, VARCHAR, INT, INT, INT, TIMESTAMP WITHOUT TIME ZONE) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_update_lesson(INT, VARCHAR, VARCHAR, INT, INT, INT, TIMESTAMP WITHOUT TIME ZONE) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_delete_lesson(INT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_create_studentdata(INT, INT, INT, SMALLINT, journal_status_enum, TEXT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_update_studentdata(INT, INT, INT, INT, SMALLINT, journal_status_enum, TEXT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_delete_studentdata(INT) TO teacher;
GRANT EXECUTE ON PROCEDURE proc_create_audit_log(VARCHAR, VARCHAR, TEXT, TEXT) TO teacher;

-- Views
GRANT SELECT ON vws_teacher_profile TO teacher;
GRANT SELECT ON vw_teacher_class_students TO teacher;
GRANT SELECT ON vw_teachers_with_classes TO teacher;
GRANT SELECT ON vw_teacher_analytics TO teacher;
GRANT SELECT ON vw_class_attendance_last_month TO teacher;
GRANT SELECT ON vw_class_ranking TO teacher;
GRANT SELECT ON vw_student_perfomance_matrix TO teacher;

-- Read access to base entities needed for dropdowns/logic (via Views)
GRANT SELECT ON vws_subjects TO teacher;
GRANT SELECT ON vws_materials TO teacher;
GRANT SELECT ON vws_classes TO teacher;
GRANT SELECT ON vws_timetables TO teacher;
GRANT SELECT ON vws_lessons TO teacher;
GRANT SELECT ON vws_homeworks TO teacher;
GRANT SELECT ON vws_student_data TO teacher;
GRANT SELECT ON vws_students TO teacher;

-- =================================================================================================
-- ADMIN
-- =================================================================================================
GRANT EXECUTE ON FUNCTION get_data_by_user_id(INT) TO admin;
GRANT SELECT on vws_all_user_details TO admin;

-- NO DIRECT TABLE ACCESS. Access via Procedures and Views only.

-- Functions: Grant all
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin;

-- Procedures: CRUD for Academic Structure
GRANT EXECUTE ON PROCEDURE proc_create_class(VARCHAR, INT, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_class(VARCHAR, INT, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_class(VARCHAR) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_subject(TEXT, INT, TEXT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_subject(INT, TEXT, INT, TEXT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_subject(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_material(VARCHAR, TEXT, TEXT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_material(INT, VARCHAR, TEXT, TEXT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_material(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_journal(INT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_journal(INT, INT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_journal(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_timetable(VARCHAR, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_timetable(INT, VARCHAR, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_timetable(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_day(INT, INT, TIME, VARCHAR, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_day(INT, INT, INT, TIME, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_day(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_lesson(VARCHAR, VARCHAR, INT, INT, INT, TIMESTAMP WITHOUT TIME ZONE) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_lesson(INT, VARCHAR, VARCHAR, INT, INT, INT, TIMESTAMP WITHOUT TIME ZONE) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_lesson(INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_create_homework(VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_homework(INT, VARCHAR, INT, INT, DATE, TEXT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_homework(INT) TO admin;

-- Procedures: CRUD for Users (specific types)
GRANT EXECUTE ON PROCEDURE proc_create_student(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_student(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_student(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_parent(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_parent(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_parent(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_create_teacher(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_update_teacher(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_delete_teacher(INT) TO admin;

GRANT EXECUTE ON PROCEDURE proc_assign_student_parent(INT, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_unassign_student_parent(INT, INT) TO admin;
GRANT EXECUTE ON PROCEDURE proc_reset_user_password(INT, VARCHAR) TO admin;
GRANT EXECUTE ON PROCEDURE proc_create_audit_log(VARCHAR, VARCHAR, TEXT, TEXT) TO admin;
GRANT SELECT ON vws_users TO admin;
GRANT SELECT ON vws_roles TO admin;
GRANT SELECT ON vws_user_roles TO admin;
GRANT SELECT ON vws_subjects TO admin;
GRANT SELECT ON vws_classes TO admin;
GRANT SELECT ON vws_journals TO admin;
GRANT SELECT ON vws_timetables TO admin;
GRANT SELECT ON vws_days TO admin;
GRANT SELECT ON vws_lessons TO admin;
GRANT SELECT ON vws_homeworks TO admin;
GRANT SELECT ON vws_materials TO admin;
GRANT SELECT ON vws_students TO admin;
GRANT SELECT ON vws_parents TO admin;
GRANT SELECT ON vws_teachers TO admin;
GRANT SELECT ON vws_student_parents TO admin;
GRANT SELECT ON vws_student_data TO admin;

-- =================================================================================================
-- SADMIN
-- =================================================================================================
GRANT admin TO sadmin;
GRANT EXECUTE ON FUNCTION get_data_by_user_id(INT) TO sadmin;
GRANT SELECT on vws_all_user_details TO sadmin;

GRANT EXECUTE ON PROCEDURE proc_assign_role_to_user(INT, INT) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_remove_role_from_user(INT, INT) TO sadmin;

GRANT EXECUTE ON PROCEDURE proc_create_user(VARCHAR, VARCHAR, VARCHAR, INT) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_update_user(INT, VARCHAR, VARCHAR, VARCHAR) TO sadmin;
GRANT EXECUTE ON PROCEDURE proc_delete_user(INT) TO sadmin;
GRANT SELECT ON vws_audits TO sadmin;

-- Grant Select on Auth Security Views
GRANT SELECT ON vws_user_auth_info TO sadmin;
