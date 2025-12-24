CREATE OR REPLACE FUNCTION trg_unique_user_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
	BEGIN
	    IF EXISTS (
	        SELECT 1 FROM Users
	        WHERE email = NEW.email
	           OR username = NEW.username
	    ) THEN
	        RAISE EXCEPTION 'Duplicate email or username';
	    END IF;
	
	    RETURN NEW;
	END;
$$;

CREATE TRIGGER unique_user_check
	BEFORE INSERT ON Users
	FOR EACH ROW
	EXECUTE FUNCTION trg_unique_user_fields();
