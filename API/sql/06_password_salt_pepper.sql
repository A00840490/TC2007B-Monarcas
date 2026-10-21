-- 06_password_salt_pepper.sql
-- Only for a database created with an older 01_create_database.sql, where
-- Users.PasswordHash is CHAR(64) (the plain SHA-256 the apps send). Widens the
-- column so it fits the salted PBKDF2 hashes of API/passwords.py, without
-- losing data. Then convert the existing hashes from the API server:
--   python3 -m tasks.hash_passwords
--
-- Run it as an administrator (not caritas_api) with "Execute SQL Script" (Alt+X).
-- It can be run again: it does nothing if the column is already wide enough.

SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.Users', N'PasswordHash') < 255
    ALTER TABLE dbo.Users ALTER COLUMN PasswordHash VARCHAR(255) NOT NULL;

SELECT c.name AS ColumnName, t.name AS DataType, c.max_length AS MaxLength
FROM sys.columns c
INNER JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.Users') AND c.name = N'PasswordHash';
