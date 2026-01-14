
-- =================================================================================================
-- FIX PROCEDURE SECURITY SCRIPT
-- =================================================================================================
-- This script updates stored procedures to use SECURITY DEFINER.
-- This allows users (like Teachers/Admins) to execute these procedures and modify data
-- in tables they don't have direct INSERT/UPDATE/DELETE access to.
-- The procedures will run with the privileges of the procedure owner (usually postgres/superuser).

-- 1. HOMEWORK PROCEDURES
ALTER PROCEDURE proc_create_homework(varchar, integer, integer, date, text, varchar) SECURITY DEFINER;
ALTER PROCEDURE proc_update_homework(integer, varchar, integer, integer, date, text, varchar) SECURITY DEFINER;
ALTER PROCEDURE proc_delete_homework(integer) SECURITY DEFINER;

-- 2. STUDENT DATA (GRADES) PROCEDURES
ALTER PROCEDURE proc_create_studentdata(integer, integer, integer, smallint, journal_status_enum, text) SECURITY DEFINER;
ALTER PROCEDURE proc_update_studentdata(integer, integer, integer, integer, smallint, journal_status_enum, text) SECURITY DEFINER;
-- ALTER PROCEDURE proc_delete_studentdata(...) SECURITY DEFINER; -- If exists

-- 3. LESSON PROCEDURES
ALTER PROCEDURE proc_create_lesson(varchar, varchar, integer, integer, integer, date) SECURITY DEFINER;
-- ALTER PROCEDURE proc_update_lesson(...) SECURITY DEFINER; -- If exists
-- ALTER PROCEDURE proc_delete_lesson(...) SECURITY DEFINER; -- If exists

-- 4. MATERIAL PROCEDURES
ALTER PROCEDURE proc_create_material(varchar, text, text) SECURITY DEFINER;
ALTER PROCEDURE proc_update_material(integer, varchar, text, text) SECURITY DEFINER;
ALTER PROCEDURE proc_delete_material(integer) SECURITY DEFINER;

-- 5. USER MANAGEMENT PROCEDURES
-- These are critical as they modify the Users table
ALTER PROCEDURE proc_create_user(varchar, varchar, varchar, integer) SECURITY DEFINER;
ALTER PROCEDURE proc_update_user(integer, varchar, varchar, text) SECURITY DEFINER;
ALTER PROCEDURE proc_reset_user_password(integer, text) SECURITY DEFINER;
ALTER PROCEDURE proc_assign_role_to_user(integer, varchar) SECURITY DEFINER;
ALTER PROCEDURE proc_remove_role_from_user(integer, varchar) SECURITY DEFINER;

-- 6. ENTITY MANAGEMENT PROCEDURES (Admin use)
ALTER PROCEDURE proc_create_student(varchar, varchar, varchar, varchar, integer, varchar) SECURITY DEFINER;
ALTER PROCEDURE proc_update_student(integer, varchar, varchar, varchar, varchar, integer, varchar) SECURITY DEFINER;
ALTER PROCEDURE proc_delete_student(integer) SECURITY DEFINER;

ALTER PROCEDURE proc_create_parent(varchar, varchar, varchar, varchar, integer) SECURITY DEFINER;
ALTER PROCEDURE proc_update_parent(integer, varchar, varchar, varchar, varchar, integer) SECURITY DEFINER;
ALTER PROCEDURE proc_delete_parent(integer) SECURITY DEFINER;

ALTER PROCEDURE proc_create_teacher(varchar, varchar, varchar, varchar, integer) SECURITY DEFINER;
ALTER PROCEDURE proc_update_teacher(integer, varchar, varchar, varchar, varchar, integer) SECURITY DEFINER;
ALTER PROCEDURE proc_delete_teacher(integer) SECURITY DEFINER;

ALTER PROCEDURE proc_assign_student_parent(integer, integer) SECURITY DEFINER;
ALTER PROCEDURE proc_unassign_student_parent(integer, integer) SECURITY DEFINER;

-- 7. SCHEDULE PROCEDURES
ALTER PROCEDURE proc_create_day(integer, integer, time, varchar, integer) SECURITY DEFINER;
ALTER PROCEDURE proc_update_day(integer, integer, integer, time, varchar) SECURITY DEFINER;

-- 8. AUTH PROCEDURES
ALTER PROCEDURE proc_register_user(varchar, varchar, text, integer) SECURITY DEFINER;

-- NOTE:
-- Ensure that the owner of these procedures is a superuser (e.g., 'postgres').
-- You can verify ownership with:
-- SELECT proname, rolname FROM pg_proc JOIN pg_roles ON pg_proc.proowner = pg_roles.oid WHERE proname LIKE 'proc_%';
