-- =================================================================================================
-- FIX PERMISSIONS FOR BACKEND (BOUNCER & LOGGING)
-- =================================================================================================

-- 1. Allow 'defaultuser' to switch roles (Required for bouncer.js to use SET ROLE)
--    If this is missing, bouncer.js fails with "permission denied to set role"
GRANT student TO defaultuser;
GRANT parent TO defaultuser;
GRANT teacher TO defaultuser;
GRANT admin TO defaultuser;
GRANT sadmin TO defaultuser;
GRANT guest TO defaultuser;
