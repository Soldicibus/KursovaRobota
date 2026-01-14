CREATE OR REPLACE VIEW vws_user_auth_info AS
SELECT 
    u.user_id,
    u.username,
    u.password,
    u.email
FROM Users u