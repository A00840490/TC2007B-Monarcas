-- 05_donor_notes_and_call_results.sql
-- Brings a database created with an older 01_create_database.sql up to date
-- with what the Telefonista endpoints use (API/telefonistas_db.py):
--   Donor:     Nickname, Email, OfficePhone
--   PhoneCall: CalledAt, ResultNotes
--   DonorNote: new table (the telefonista's log about a donor)
--
-- These changes were first made by hand on the server database; this script
-- reproduces them so any other database ends up the same. It keeps all data
-- and only adds what is missing, so it can be run more than once. A database
-- created with the current 01_create_database.sql already has everything.
--
-- Run it inside the database the API uses (DB_NAME in API/.env), as sa or the
-- owner, then run 04_app_users.sql again for the new permissions.
--   DBeaver: "Execute SQL Script" (Alt+X), not Ctrl+Enter.
--   sqlcmd:  sqlcmd -S <host> -d <database> -U <user> -f 65001 -i API/sql/05_donor_notes_and_call_results.sql

SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.Donor', N'Nickname') IS NULL
    ALTER TABLE dbo.Donor ADD Nickname NVARCHAR(60) NULL;

IF COL_LENGTH(N'dbo.Donor', N'Email') IS NULL
    ALTER TABLE dbo.Donor ADD Email NVARCHAR(254) NULL;

IF COL_LENGTH(N'dbo.Donor', N'OfficePhone') IS NULL
    ALTER TABLE dbo.Donor ADD OfficePhone VARCHAR(20) NULL;

IF COL_LENGTH(N'dbo.PhoneCall', N'CalledAt') IS NULL
    ALTER TABLE dbo.PhoneCall ADD CalledAt DATETIME2(0) NULL;

IF COL_LENGTH(N'dbo.PhoneCall', N'ResultNotes') IS NULL
    ALTER TABLE dbo.PhoneCall ADD ResultNotes NVARCHAR(1000) NULL;

IF OBJECT_ID(N'dbo.DonorNote', N'U') IS NULL
    CREATE TABLE dbo.DonorNote (
        ID        INT IDENTITY(1, 1) CONSTRAINT PK_DonorNote PRIMARY KEY,
        DonorID   INT NOT NULL CONSTRAINT FK_DonorNote_Donor REFERENCES dbo.Donor(ID),
        UserID    INT NOT NULL CONSTRAINT FK_DonorNote_Users REFERENCES dbo.Users(ID),
        Note      NVARCHAR(1000) NOT NULL,
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DonorNote_CreatedAt DEFAULT SYSDATETIME()
    );

-- In EXEC so the batch compiles even when DonorNote did not exist yet.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_DonorNote_DonorID_CreatedAt' AND object_id = OBJECT_ID(N'dbo.DonorNote'))
    EXEC (N'CREATE INDEX IX_DonorNote_DonorID_CreatedAt ON dbo.DonorNote (DonorID, CreatedAt);');
