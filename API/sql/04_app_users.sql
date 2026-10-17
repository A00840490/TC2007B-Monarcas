-- 04_app_users.sql
-- Least-privilege SQL Server accounts for the apps, so nothing connects as sa.
--
--   caritas_api    The Flask API (server.py / gunicorn). DB_USER in API/.env.
--                  Reads every table and creates donors, calls and collections.
--   caritas_tasks  The daily task (python -m tasks.daily_recurring_donations).
--                  TASKS_DB_USER in API/.env. Reads pledges, creates calls and
--                  collections and moves a pledge's next installment.
--
-- Neither account can delete rows, change the schema, read other databases or
-- touch server settings. Permissions are granted per table (and per column for
-- the only UPDATE), through the roles app_api and app_tasks.
--
-- HOW TO RUN (as sa or another sysadmin, inside the database the API uses,
-- DB_NAME in API/.env):
--   1. Replace REPLACE_WITH_API_PASSWORD and REPLACE_WITH_TASKS_PASSWORD below
--      with two different long random passwords, for example:
--        python3 -c "import secrets; print(secrets.token_urlsafe(24))"
--      Do NOT save the file with the real passwords and NEVER commit them: put
--      them only in API/.env on the server. If a placeholder is left, the
--      script stops with an error and creates nothing usable.
--   2. Run the whole file:
--        DBeaver: "Execute SQL Script" (Alt+X), not Ctrl+Enter.
--        sqlcmd:  sqlcmd -S <host> -d <database> -U sa -f 65001 -i API/sql/04_app_users.sql
--   3. The last query lists what each role can do; check it.
--
-- It can be run again at any time: it creates only what is missing and
-- re-applies the grants. Run it again after 01_create_database.sql, because
-- dropping the tables also drops their grants. It never changes an existing
-- password (see "Rotating a password" in API/sql/README.md).

SET NOCOUNT ON;

------------------------------------------------------------------------------
-- 1. Server logins (SQL authentication).
--    CHECK_POLICY = ON applies the OS password policy (length, complexity,
--    lockout after failed attempts). CHECK_EXPIRATION = OFF so the API does
--    not stop when the password expires; rotate it by hand instead.
------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'caritas_api')
    CREATE LOGIN caritas_api
        WITH PASSWORD = N'REPLACE_WITH_API_PASSWORD',
             CHECK_POLICY = ON,
             CHECK_EXPIRATION = OFF;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'caritas_tasks')
    CREATE LOGIN caritas_tasks
        WITH PASSWORD = N'REPLACE_WITH_TASKS_PASSWORD',
             CHECK_POLICY = ON,
             CHECK_EXPIRATION = OFF;

-- Stop if a login was created with the placeholder password (the placeholder
-- is split in two so a find-and-replace of it does not change this check).
-- The login is dropped so it can be created again with a real password.
EXEC (N'
    DECLARE @name SYSNAME;
    SELECT TOP 1 @name = name
    FROM sys.sql_logins
    WHERE (name = N''caritas_api''
           AND PWDCOMPARE(N''REPLACE_WITH_'' + N''API_PASSWORD'', password_hash) = 1)
       OR (name = N''caritas_tasks''
           AND PWDCOMPARE(N''REPLACE_WITH_'' + N''TASKS_PASSWORD'', password_hash) = 1);
    IF @name IS NOT NULL
    BEGIN
        DECLARE @drop NVARCHAR(200) = N''DROP LOGIN '' + QUOTENAME(@name);
        EXEC sp_executesql @drop;
        THROW 50001, N''Replace the placeholder passwords before running 04_app_users.sql.'', 1;
    END
');

-- Land in this database (not master) and make sure both logins are enabled.
EXEC (N'
    DECLARE @sql NVARCHAR(MAX) =
          N''ALTER LOGIN caritas_api WITH DEFAULT_DATABASE = '' + QUOTENAME(DB_NAME()) + N'';''
        + N''ALTER LOGIN caritas_tasks WITH DEFAULT_DATABASE = '' + QUOTENAME(DB_NAME()) + N'';''
        + N''ALTER LOGIN caritas_api ENABLE;''
        + N''ALTER LOGIN caritas_tasks ENABLE;'';
    EXEC sp_executesql @sql;
');

------------------------------------------------------------------------------
-- 2. Database users and roles.
------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'caritas_api')
    CREATE USER caritas_api FOR LOGIN caritas_api WITH DEFAULT_SCHEMA = dbo;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'caritas_tasks')
    CREATE USER caritas_tasks FOR LOGIN caritas_tasks WITH DEFAULT_SCHEMA = dbo;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_api' AND type = 'R')
    CREATE ROLE app_api;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_tasks' AND type = 'R')
    CREATE ROLE app_tasks;

ALTER ROLE app_api ADD MEMBER caritas_api;
ALTER ROLE app_tasks ADD MEMBER caritas_tasks;

------------------------------------------------------------------------------
-- 3. Permissions of the API (only what API/database.py runs).
------------------------------------------------------------------------------
GRANT SELECT ON dbo.Role              TO app_api;
GRANT SELECT ON dbo.Users             TO app_api;
GRANT SELECT ON dbo.Donor             TO app_api;
GRANT SELECT ON dbo.PhoneCall         TO app_api;
GRANT SELECT ON dbo.Collection        TO app_api;
GRANT SELECT ON dbo.RecurringDonation TO app_api;
GRANT SELECT ON dbo.Donation          TO app_api;

GRANT INSERT ON dbo.Donor      TO app_api;  -- POST donors
GRANT INSERT ON dbo.PhoneCall  TO app_api;  -- POST calls
GRANT INSERT ON dbo.Collection TO app_api;  -- POST collections

------------------------------------------------------------------------------
-- 4. Permissions of the daily task (only what API/recurring_donations.py runs).
------------------------------------------------------------------------------
GRANT SELECT ON dbo.RecurringDonation TO app_tasks;
GRANT SELECT ON dbo.PhoneCall         TO app_tasks;

GRANT INSERT ON dbo.PhoneCall  TO app_tasks;
GRANT INSERT ON dbo.Collection TO app_tasks;

GRANT UPDATE ON dbo.RecurringDonation (NextInstallmentDate, Status) TO app_tasks;

------------------------------------------------------------------------------
-- 5. Check: every permission the two roles have in this database.
------------------------------------------------------------------------------
SELECT pr.name AS RoleName,
       pe.permission_name AS Permission,
       OBJECT_NAME(pe.major_id) AS TableName,
       COL_NAME(pe.major_id, pe.minor_id) AS ColumnName
FROM sys.database_permissions pe
INNER JOIN sys.database_principals pr ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name IN (N'app_api', N'app_tasks')
  AND pe.class = 1
ORDER BY pr.name, TableName, pe.permission_name, ColumnName;
