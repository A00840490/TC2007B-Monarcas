-- 01_create_database.sql
-- Creates the whole schema from scratch (SQL Server). See docs/database.md.
--
-- WARNING: it DROPS the tables first, both the original Spanish ones (Rol,
-- Usuarios, Donante, Donacion, Recoleccion, Llamada) and the current English
-- ones, so ALL THEIR DATA IS LOST. Back up first if anything must be kept.
--
-- Run it inside the database the API uses (DB_NAME in API/.env), then
-- 02_seed_data.sql if you want test data (and 03_demo_data.sql for a large
-- demo data set, see API/sql/README.md). Then run 04_app_users.sql again:
-- dropping the tables also drops the API accounts' permissions.
--
-- It has no GO separators and no variables shared between statements, so it
-- runs the same as a single batch or statement by statement:
--   DBeaver: open the file and use "Execute SQL Script" (Alt+X), not Ctrl+Enter.
--   sqlcmd:  sqlcmd -S <host> -d <database> -U <user> -f 65001 -i API/sql/01_create_database.sql
--            (-f 65001 reads the file as UTF-8)

SET NOCOUNT ON;

------------------------------------------------------------------------------
-- 1. Drop the old and current tables.
--    Foreign keys go first because some tables reference each other. It is a
--    single EXEC so it still works when the client splits the script on ";".
------------------------------------------------------------------------------
EXEC (N'
    DECLARE @tables TABLE (Name SYSNAME);
    INSERT INTO @tables VALUES
        (N''Rol''), (N''Usuarios''), (N''Donante''), (N''Donacion''), (N''Recoleccion''), (N''Llamada''),
        (N''Role''), (N''Users''), (N''Donor''), (N''Donation''), (N''Collection''), (N''PhoneCall''),
        (N''RecurringDonation''), (N''DonorNote'');

    DECLARE @sql NVARCHAR(MAX) = N'''';

    SELECT @sql += N''ALTER TABLE '' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N''.''
                 + QUOTENAME(OBJECT_NAME(fk.parent_object_id))
                 + N'' DROP CONSTRAINT '' + QUOTENAME(fk.name) + N'';'' + CHAR(10)
    FROM sys.foreign_keys fk
    WHERE OBJECT_NAME(fk.parent_object_id) IN (SELECT Name FROM @tables)
       OR OBJECT_NAME(fk.referenced_object_id) IN (SELECT Name FROM @tables);

    SELECT @sql += N''DROP TABLE dbo.'' + QUOTENAME(Name) + N'';'' + CHAR(10)
    FROM @tables
    WHERE OBJECT_ID(N''dbo.'' + Name, ''U'') IS NOT NULL;

    EXEC sp_executesql @sql;
');

------------------------------------------------------------------------------
-- 2. Users and roles.
------------------------------------------------------------------------------
CREATE TABLE dbo.Role (
    ID   INT IDENTITY(1, 1) CONSTRAINT PK_Role PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    CONSTRAINT UQ_Role_Name UNIQUE (Name),
    CONSTRAINT CK_Role_Name CHECK (Name IN ('Admin', 'Telefonista', 'Recolector'))
);

CREATE TABLE dbo.Users (
    ID           INT IDENTITY(1, 1) CONSTRAINT PK_Users PRIMARY KEY,
    Name         NVARCHAR(100) NOT NULL,
    Email        NVARCHAR(254) NOT NULL,
    -- Salted PBKDF2 of the app's hex SHA-256 plus the API pepper (API/passwords.py).
    -- The seed scripts insert the plain SHA-256; python3 -m tasks.hash_passwords converts it.
    PasswordHash VARCHAR(255) NOT NULL,
    RoleID       INT NOT NULL CONSTRAINT FK_Users_Role REFERENCES dbo.Role(ID),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);

------------------------------------------------------------------------------
-- 3. Donors.
------------------------------------------------------------------------------
CREATE TABLE dbo.Donor (
    ID          INT IDENTITY(1, 1) CONSTRAINT PK_Donor PRIMARY KEY,
    Name        NVARCHAR(150) NOT NULL,
    Phone       VARCHAR(20) NULL,
    Address     NVARCHAR(300) NULL,
    RiskStatus  VARCHAR(10) NOT NULL CONSTRAINT DF_Donor_RiskStatus DEFAULT 'LOW',
    Nickname    NVARCHAR(60) NULL,
    Email       NVARCHAR(254) NULL,
    OfficePhone VARCHAR(20) NULL,
    CONSTRAINT CK_Donor_RiskStatus CHECK (RiskStatus IN ('LOW', 'MEDIUM', 'HIGH'))
);

-- Free-text log a telefonista keeps about a donor (POST /api/telefonistas/donors/<id>/notes).
CREATE TABLE dbo.DonorNote (
    ID        INT IDENTITY(1, 1) CONSTRAINT PK_DonorNote PRIMARY KEY,
    DonorID   INT NOT NULL CONSTRAINT FK_DonorNote_Donor REFERENCES dbo.Donor(ID),
    UserID    INT NOT NULL CONSTRAINT FK_DonorNote_Users REFERENCES dbo.Users(ID),
    Note      NVARCHAR(1000) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DonorNote_CreatedAt DEFAULT SYSDATETIME()
);

------------------------------------------------------------------------------
-- 4. Scheduled work: calls and collections.
--    PhoneCall/Collection <-> RecurringDonation reference each other, so the
--    RecurringDonationID foreign keys are added after that table exists.
------------------------------------------------------------------------------
CREATE TABLE dbo.PhoneCall (
    ID                  INT IDENTITY(1, 1) CONSTRAINT PK_PhoneCall PRIMARY KEY,
    UserID              INT NOT NULL CONSTRAINT FK_PhoneCall_Users REFERENCES dbo.Users(ID),
    DonorID             INT NOT NULL CONSTRAINT FK_PhoneCall_Donor REFERENCES dbo.Donor(ID),
    Type                VARCHAR(30) NOT NULL CONSTRAINT DF_PhoneCall_Type DEFAULT 'REGULAR',
    Status              VARCHAR(20) NOT NULL CONSTRAINT DF_PhoneCall_Status DEFAULT 'PENDING',
    Notes               NVARCHAR(1000) NULL,
    ScheduledDate       DATETIME2(0) NOT NULL,
    RecurringDonationID INT NULL,
    CalledAt            DATETIME2(0) NULL,     -- when the telefonista saved the result
    ResultNotes         NVARCHAR(1000) NULL,   -- what the telefonista wrote; Notes keeps the goal
    CONSTRAINT CK_PhoneCall_Type CHECK (Type IN ('REGULAR', 'CONFIRMATION', 'TRANSFER_COLLECTION')),
    CONSTRAINT CK_PhoneCall_Status
        CHECK (Status IN ('PENDING', 'NO_ANSWER', 'DECLINED', 'ACCEPTED', 'RESCHEDULED'))
);

CREATE TABLE dbo.Collection (
    ID                  INT IDENTITY(1, 1) CONSTRAINT PK_Collection PRIMARY KEY,
    UserID              INT NOT NULL CONSTRAINT FK_Collection_Users REFERENCES dbo.Users(ID),
    DonorID             INT NOT NULL CONSTRAINT FK_Collection_Donor REFERENCES dbo.Donor(ID),
    Status              VARCHAR(20) NOT NULL CONSTRAINT DF_Collection_Status DEFAULT 'PENDING',
    Notes               NVARCHAR(1000) NULL,
    ScheduledDate       DATETIME2(0) NOT NULL,
    ExpectedAmount      DECIMAL(12, 2) NULL,
    RouteOrder          INT NULL,
    CallID              INT NULL CONSTRAINT FK_Collection_PhoneCall REFERENCES dbo.PhoneCall(ID),
    RecurringDonationID INT NULL,
    CONSTRAINT CK_Collection_Status CHECK (Status IN ('PENDING', 'SUCCESSFUL', 'FAILED')),
    CONSTRAINT CK_Collection_ExpectedAmount CHECK (ExpectedAmount IS NULL OR ExpectedAmount >= 0)
);

------------------------------------------------------------------------------
-- 5. Recurring donation pledges.
------------------------------------------------------------------------------
CREATE TABLE dbo.RecurringDonation (
    ID                  INT IDENTITY(1, 1) CONSTRAINT PK_RecurringDonation PRIMARY KEY,
    DonorID             INT NOT NULL CONSTRAINT FK_RecurringDonation_Donor REFERENCES dbo.Donor(ID),
    Amount              DECIMAL(12, 2) NOT NULL,
    PaymentMethod       VARCHAR(20) NOT NULL,
    TargetCampaign      NVARCHAR(100) NULL,
    Frequency           VARCHAR(20) NOT NULL CONSTRAINT DF_RecurringDonation_Frequency DEFAULT 'MONTHLY',
    StartDate           DATE NOT NULL,
    NextInstallmentDate DATE NOT NULL,
    EndDate             DATE NULL,
    Status              VARCHAR(20) NOT NULL CONSTRAINT DF_RecurringDonation_Status DEFAULT 'ACTIVE',
    TelefonistaID       INT NOT NULL CONSTRAINT FK_RecurringDonation_Telefonista REFERENCES dbo.Users(ID),
    RecolectorID        INT NOT NULL CONSTRAINT FK_RecurringDonation_Recolector REFERENCES dbo.Users(ID),
    OriginCallID        INT NULL CONSTRAINT FK_RecurringDonation_PhoneCall REFERENCES dbo.PhoneCall(ID),
    OriginCollectionID  INT NULL CONSTRAINT FK_RecurringDonation_Collection REFERENCES dbo.Collection(ID),
    Notes               NVARCHAR(1000) NULL,
    CONSTRAINT CK_RecurringDonation_Amount CHECK (Amount > 0),
    CONSTRAINT CK_RecurringDonation_PaymentMethod CHECK (PaymentMethod IN ('CASH', 'TRANSFER')),
    CONSTRAINT CK_RecurringDonation_Frequency CHECK (Frequency IN ('MONTHLY')),
    CONSTRAINT CK_RecurringDonation_Status CHECK (Status IN ('ACTIVE', 'PAUSED', 'CANCELLED', 'FINISHED')),
    CONSTRAINT CK_RecurringDonation_Dates CHECK (
        NextInstallmentDate >= StartDate AND (EndDate IS NULL OR EndDate >= StartDate))
);

ALTER TABLE dbo.PhoneCall ADD CONSTRAINT FK_PhoneCall_RecurringDonation
    FOREIGN KEY (RecurringDonationID) REFERENCES dbo.RecurringDonation(ID);

ALTER TABLE dbo.Collection ADD CONSTRAINT FK_Collection_RecurringDonation
    FOREIGN KEY (RecurringDonationID) REFERENCES dbo.RecurringDonation(ID);

------------------------------------------------------------------------------
-- 6. Donations: history, past only.
------------------------------------------------------------------------------
CREATE TABLE dbo.Donation (
    ID                  INT IDENTITY(1, 1) CONSTRAINT PK_Donation PRIMARY KEY,
    DonorID             INT NOT NULL CONSTRAINT FK_Donation_Donor REFERENCES dbo.Donor(ID),
    DonationDate        DATETIME2(0) NOT NULL CONSTRAINT DF_Donation_DonationDate DEFAULT SYSDATETIME(),
    TotalAmount         DECIMAL(12, 2) NOT NULL,
    PaymentMethod       VARCHAR(20) NOT NULL,
    TargetCampaign      NVARCHAR(100) NULL,
    Notes               NVARCHAR(1000) NULL,
    CollectionID        INT NULL CONSTRAINT FK_Donation_Collection REFERENCES dbo.Collection(ID),
    CallID              INT NULL CONSTRAINT FK_Donation_PhoneCall REFERENCES dbo.PhoneCall(ID),
    RecurringDonationID INT NULL CONSTRAINT FK_Donation_RecurringDonation REFERENCES dbo.RecurringDonation(ID),
    CONSTRAINT CK_Donation_TotalAmount CHECK (TotalAmount > 0),
    CONSTRAINT CK_Donation_PaymentMethod CHECK (PaymentMethod IN ('CASH', 'TRANSFER')),
    -- Donation only records the past. A few minutes of margin for clock differences.
    CONSTRAINT CK_Donation_DateInPast CHECK (DonationDate <= DATEADD(MINUTE, 5, SYSDATETIME()))
);

------------------------------------------------------------------------------
-- 7. Indexes for what the apps and the daily task look up.
------------------------------------------------------------------------------
CREATE INDEX IX_Users_RoleID ON dbo.Users (RoleID);
CREATE INDEX IX_DonorNote_DonorID_CreatedAt ON dbo.DonorNote (DonorID, CreatedAt);
CREATE INDEX IX_PhoneCall_UserID_ScheduledDate ON dbo.PhoneCall (UserID, ScheduledDate);
CREATE INDEX IX_PhoneCall_DonorID ON dbo.PhoneCall (DonorID);
CREATE INDEX IX_PhoneCall_RecurringDonationID ON dbo.PhoneCall (RecurringDonationID);
CREATE INDEX IX_Collection_UserID_ScheduledDate ON dbo.Collection (UserID, ScheduledDate);
CREATE INDEX IX_Collection_DonorID ON dbo.Collection (DonorID);
CREATE INDEX IX_Collection_RecurringDonationID ON dbo.Collection (RecurringDonationID);
CREATE INDEX IX_Donation_DonorID_DonationDate ON dbo.Donation (DonorID, DonationDate);
CREATE INDEX IX_Donation_CollectionID ON dbo.Donation (CollectionID);
CREATE INDEX IX_RecurringDonation_Status_NextInstallmentDate
    ON dbo.RecurringDonation (Status, NextInstallmentDate);
