-- Recreate AuditLog table with new column without losing data (migration script)
-- Note: This is a utility script to apply changes if the table already exists.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'auditlog' 
        AND column_name = 'username'
    ) THEN
        ALTER TABLE AuditLog ADD COLUMN username VARCHAR(50) DEFAULT SESSION_USER;
    END IF;
END $$;
