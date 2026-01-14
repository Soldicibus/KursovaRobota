CREATE OR REPLACE PROCEDURE proc_create_audit_log(
	IN p_table_name VARCHAR, 
	IN p_operation VARCHAR, 
	IN p_record_id TEXT,
	IN p_details TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF p_table_name IS NULL OR p_operation IS NULL THEN
        RAISE EXCEPTION 'Table name and operation type are required for auditing.'
        USING ERRCODE = '22004';
    END IF;

    IF length(p_table_name) > 50 THEN
        RAISE EXCEPTION 'Table name exceeds 50 characters.'
        USING ERRCODE = '22001';
    END IF;

    IF length(p_operation) > 20 THEN
        RAISE EXCEPTION 'Operation type exceeds 20 characters.'
        USING ERRCODE = '22001';
    END IF;
	
	INSERT INTO AuditLog (table_name, operation, record_id, details)
    VALUES (p_table_name, p_operation, p_record_id, p_details);
END;
$$;