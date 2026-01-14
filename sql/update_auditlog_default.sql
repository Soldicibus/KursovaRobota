-- Migration to update the default value of username column in AuditLog
-- This allows the audit log to pick up the app.current_username setting from bouncer.js

ALTER TABLE AuditLog 
    ALTER COLUMN username SET DEFAULT current_setting('app.current_username', true);

-- Optional: Update existing NULL usernames if known, or leave as is.
-- (No safe way to know past usernames unless they were SESSION_USER)
