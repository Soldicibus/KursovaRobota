-- Fix permissions for get_student_monthly_grades

-- Grant execute to student role
GRANT EXECUTE ON FUNCTION get_student_monthly_grades(p_student_id INT, p_month TIMESTAMP WITHOUT TIME ZONE) TO student;

-- Grant execute to parent role
GRANT EXECUTE ON FUNCTION get_student_monthly_grades(p_student_id INT, p_month TIMESTAMP WITHOUT TIME ZONE) TO parent;

-- Grant execute to defaultuser (just in case inheritance is an issue or direct access is needed)
GRANT EXECUTE ON FUNCTION get_student_monthly_grades(p_student_id INT, p_month TIMESTAMP WITHOUT TIME ZONE) TO defaultuser;

-- Grant execute to teacher role (just in case)
GRANT EXECUTE ON FUNCTION get_student_monthly_grades(p_student_id INT, p_month TIMESTAMP WITHOUT TIME ZONE) TO teacher;
