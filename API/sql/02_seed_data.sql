-- 02_seed_data.sql
-- Test data for development. Run after 01_create_database.sql.
-- Dates are relative to the day it runs, so the apps always have something
-- scheduled for today.
--
-- Every test user has the password Caritas2026 (PasswordHash is its hex
-- SHA-256, which is what the apps send). Do not use these users in production.
--
-- Like 01_create_database.sql it has no GO and no variables, so it runs in
-- DBeaver with "Execute SQL Script" (Alt+X) or with sqlcmd -f 65001.
-- Rows are looked up by unique values (email, phone) instead of variables.

SET NOCOUNT ON;

-- Roles
INSERT INTO dbo.Role (Name) VALUES ('Admin'), ('Telefonista'), ('Recolector');

-- Users (password: Caritas2026)
INSERT INTO dbo.Users (Name, Email, PasswordHash, RoleID)
SELECT u.Name, u.Email, 'aa640a14722e867cf8b4258b2a1a145abeb9c0d8eb940ca54a1a6465a0737612', r.ID
FROM (VALUES
    (N'Ana López', N'admin@caritas.org.mx', 'Admin'),
    (N'Laura Treviño', N'telefonista@caritas.org.mx', 'Telefonista'),
    (N'Jorge Martínez', N'recolector@caritas.org.mx', 'Recolector')
) AS u (Name, Email, RoleName)
JOIN dbo.Role r ON r.Name = u.RoleName;

-- Donors
INSERT INTO dbo.Donor (Name, Phone, Address, RiskStatus) VALUES
    (N'Roberto Garza Sada', '8199000001', N'Av. Constitución 100, Centro, Monterrey', 'LOW'),
    (N'María Elena Villarreal', '8199000002', N'Calle Morelos 245, Centro, Monterrey', 'MEDIUM'),
    (N'Francisco "Paco" Salinas', '8199000003', N'Av. Gonzalitos 1500, Mitras, Monterrey', 'LOW'),
    (N'Gabriela Cantú', '8199000004', N'Río Nazas 320, Del Valle, San Pedro Garza García', 'HIGH');

-- A past call to Paco that ended in a collection...
INSERT INTO dbo.PhoneCall (UserID, DonorID, Type, Status, Notes, ScheduledDate)
SELECT
    (SELECT ID FROM dbo.Users WHERE Email = N'telefonista@caritas.org.mx'),
    (SELECT ID FROM dbo.Donor WHERE Phone = '8199000003'),
    'REGULAR', 'ACCEPTED', N'Invitar a la campaña de invierno',
    DATEADD(DAY, -10, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0)));

INSERT INTO dbo.Collection (UserID, DonorID, Status, Notes, ScheduledDate, ExpectedAmount, RouteOrder, CallID)
SELECT
    (SELECT ID FROM dbo.Users WHERE Email = N'recolector@caritas.org.mx'),
    pc.DonorID, 'SUCCESSFUL', NULL,
    DATEADD(DAY, -7, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0))), 1000, 1, pc.ID
FROM dbo.PhoneCall pc
WHERE pc.DonorID = (SELECT ID FROM dbo.Donor WHERE Phone = '8199000003') AND pc.Status = 'ACCEPTED';

-- ...where Paco and his wife made two donations.
INSERT INTO dbo.Donation (DonorID, DonationDate, TotalAmount, PaymentMethod, TargetCampaign, Notes, CollectionID)
SELECT c.DonorID, c.ScheduledDate, d.Amount, 'CASH', N'Campaña de invierno', d.Notes, c.ID
FROM dbo.Collection c
CROSS JOIN (VALUES (1000, CAST(NULL AS NVARCHAR(1000))), (500, N'Donativo de su esposa')) AS d (Amount, Notes)
WHERE c.Status = 'SUCCESSFUL';

-- Past donations without a collection.
INSERT INTO dbo.Donation (DonorID, DonationDate, TotalAmount, PaymentMethod, TargetCampaign)
SELECT (SELECT ID FROM dbo.Donor WHERE Phone = d.Phone),
       DATEADD(MONTH, d.MonthsAgo, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0))),
       d.Amount, d.PaymentMethod, d.Campaign
FROM (VALUES
    ('8199000001', -2, 2500, 'TRANSFER', N'Fondo general'),
    ('8199000001', -1, 2500, 'TRANSFER', N'Fondo general'),
    ('8199000004', -4, 800, 'CASH', N'Banco de alimentos')
) AS d (Phone, MonthsAgo, Amount, PaymentMethod, Campaign);

-- Today's calls for the telefonista.
INSERT INTO dbo.PhoneCall (UserID, DonorID, Type, Status, Notes, ScheduledDate)
SELECT (SELECT ID FROM dbo.Users WHERE Email = N'telefonista@caritas.org.mx'),
       (SELECT ID FROM dbo.Donor WHERE Phone = c.Phone),
       'REGULAR', 'PENDING', c.Notes,
       DATEADD(HOUR, c.Hour, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0)))
FROM (VALUES
    ('8199000002', 10, N'Invitar a donar a la campaña de invierno'),
    ('8199000004', 12, N'Retomar contacto; no dona desde hace 4 meses')
) AS c (Phone, Hour, Notes);

-- Today's route for the recolector.
INSERT INTO dbo.Collection (UserID, DonorID, Status, Notes, ScheduledDate, ExpectedAmount, RouteOrder)
SELECT (SELECT ID FROM dbo.Users WHERE Email = N'recolector@caritas.org.mx'),
       (SELECT ID FROM dbo.Donor WHERE Phone = c.Phone),
       'PENDING', c.Notes,
       DATEADD(HOUR, c.Hour, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0))),
       c.Amount, c.RouteOrder
FROM (VALUES
    ('8199000002', 9, 600, 1, CAST(NULL AS NVARCHAR(1000))),
    ('8199000001', 11, 1500, 2, N'Tocar en la puerta lateral')
) AS c (Phone, Hour, Amount, RouteOrder, Notes);

-- Recurring pledges: Paco pays cash every month starting tomorrow (obtained in
-- the past call and collection above); Roberto transfers starting the day
-- after tomorrow.
INSERT INTO dbo.RecurringDonation
    (DonorID, Amount, PaymentMethod, TargetCampaign, StartDate, NextInstallmentDate,
     TelefonistaID, RecolectorID, OriginCallID, OriginCollectionID)
SELECT (SELECT ID FROM dbo.Donor WHERE Phone = p.Phone),
       p.Amount, p.PaymentMethod, N'Fondo general',
       DATEADD(DAY, p.DaysFromToday, CAST(SYSDATETIME() AS DATE)),
       DATEADD(DAY, p.DaysFromToday, CAST(SYSDATETIME() AS DATE)),
       (SELECT ID FROM dbo.Users WHERE Email = N'telefonista@caritas.org.mx'),
       (SELECT ID FROM dbo.Users WHERE Email = N'recolector@caritas.org.mx'),
       CASE WHEN p.FromPastVisit = 1 THEN (SELECT ID FROM dbo.PhoneCall WHERE Status = 'ACCEPTED') END,
       CASE WHEN p.FromPastVisit = 1 THEN (SELECT ID FROM dbo.Collection WHERE Status = 'SUCCESSFUL') END
FROM (VALUES
    ('8199000003', 500, 'CASH', 1, 1),
    ('8199000001', 2500, 'TRANSFER', 2, 0)
) AS p (Phone, Amount, PaymentMethod, DaysFromToday, FromPastVisit);
