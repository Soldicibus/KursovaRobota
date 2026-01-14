CREATE OR REPLACE FUNCTION log_app_auth_event(p_event_type TEXT, p_username TEXT, p_email TEXT)
RETURNS VOID 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Imitates standard Postgres connection logs
    RAISE LOG 'connection authenticated: identity="%" method=scram-sha-256 (E:/PSQL/data/pg_hba.conf:117)', p_username;

    RAISE LOG 'connection authorized: user=% database=% application_name=%',
        p_username,
        current_database(),
        current_setting('application_name');
END;
$$;
