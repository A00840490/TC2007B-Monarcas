from contextlib import contextmanager
from dbutils.pooled_db import PooledDB
import pymssql

_pool = None


def init_db_pool(sql_creds, min_connections=2, max_connections=10):
    global _pool
    _pool = PooledDB(
        creator=pymssql,
        mincached=min_connections,
        maxconnections=max_connections,
        blocking=True,
        server=sql_creds['DB_HOST'],
        port=sql_creds.get('DB_PORT', 1433),
        user=sql_creds['DB_USER'],
        password=sql_creds['DB_PASSWORD'],
        database=sql_creds['DB_NAME'],
        tds_version="7.4",
    )


@contextmanager
def get_db_connection():
    if _pool is None:
        raise RuntimeError("The database pool is not initialized. Call init_db_pool first.")

    conn = _pool.connection()
    try:
        yield conn
    finally:
        conn.close()


def read_user_data(table_name, name):
    read = f"SELECT * FROM {table_name} WHERE Name = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(read, (name,))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_user_data: {e}")


def read_all(table_name):
    read = f"SELECT * FROM {table_name}"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(read)
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_all: {e}")


def read_collection_route(user_id, date):
    query = """
        SELECT c.ID, c.ScheduledDate, c.ExpectedAmount, c.RouteOrder,
               d.Name AS DonorName, d.Address
        FROM Collection c
        INNER JOIN Donor d ON d.ID = c.DonorID
        WHERE c.UserID = %s
          AND CAST(c.ScheduledDate AS DATE) = %s
        ORDER BY CASE WHEN c.RouteOrder IS NULL THEN 1 ELSE 0 END,
                 c.RouteOrder,
                 c.ScheduledDate
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (user_id, date))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_collection_route: {e}")


def read_where(table_name, d_where):
    conditions = []
    params = []

    for k, v in d_where.items():
        if v is None:
            conditions.append(f"{k} IS NULL")
        else:
            conditions.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    where_clause = " AND ".join(conditions)
    read = f"SELECT * FROM {table_name}"
    if where_clause:
        read += f" WHERE ({where_clause})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            if params:
                cursor.execute(read, tuple(params))
            else:
                cursor.execute(read)
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_read_where: {e}")


def insert_row_into(table_name, d):
    keys = []
    values_placeholders = []
    data = []

    for k, v in d.items():
        keys.append(k)
        values_placeholders.append("%s")
        data.append(int(v) if isinstance(v, bool) else v)

    keys_str = ", ".join(keys)
    values_str = ", ".join(values_placeholders)
    insert = f"INSERT INTO {table_name} ({keys_str}) VALUES ({values_str})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            result = cursor.execute(insert, tuple(data))
            cnx.commit()
            output = cursor.lastrowid if cursor.lastrowid else result
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_insert_row_into: {e}")


def update_where(table_name, d_field, d_where):
    field_updates = []
    params = []

    for k, v in d_field.items():
        if v is None:
            field_updates.append(f"{k} = NULL")
        else:
            field_updates.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    where_conditions = []
    for k, v in d_where.items():
        if v is None:
            where_conditions.append(f"{k} IS NULL")
        else:
            where_conditions.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    update = f"UPDATE {table_name} SET {', '.join(field_updates)} WHERE ({' AND '.join(where_conditions)})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            result = cursor.execute(update, tuple(params))
            cnx.commit()
            output = cursor.lastrowid if cursor.lastrowid else result
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_update_where: {e}")


def delete_where(table_name, d_where):
    where_conditions = []
    params = []

    for k, v in d_where.items():
        if v is None:
            where_conditions.append(f"{k} IS NULL")
        else:
            where_conditions.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    delete = f"DELETE FROM {table_name} WHERE ({' AND '.join(where_conditions)})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            result = cursor.execute(delete, tuple(params))
            cnx.commit()
            output = cursor.lastrowid if cursor.lastrowid else result
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_delete_where: {e}")


def read_shift_calls():
    query = """
    SELECT
        pc.ID AS id,
        pc.ScheduledDate AS scheduledDate,
        pc.Status AS status,
        pc.Notes AS goal,
        d.ID AS donorId,
        d.Name AS donorName,
        d.Phone AS donorPhone,
        d.RiskStatus AS donorRisk,
        dn.TargetCampaign AS donorCampaign,
        dn.TotalAmount AS donorTotal,
        dn.DonationDate AS donorDate
    FROM PhoneCall pc
    JOIN Donor d ON pc.DonorID = d.ID
    LEFT JOIN Donation dn ON dn.ID = (
        SELECT TOP 1 ID FROM Donation
        WHERE DonorID = d.ID
        ORDER BY DonationDate DESC
    )
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query)
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_shift_calls: {e}")


# Start of a "last N months" window: the same day N months ago, at 00:00.
# Used with N as a query parameter.
_WINDOW_START = "DATEADD(MONTH, -%s, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0)))"


def get_kpis(active_months):
    query = f"""
    SELECT
        COALESCE((SELECT SUM(ExpectedAmount) FROM Collection WHERE Status = 'SUCCESSFUL'), 0) AS availableMoney,
        COALESCE((SELECT SUM(ExpectedAmount) FROM Collection WHERE Status = 'PENDING'), 0) AS pledgedMoney,
        -- Same definition as the donor list: an ACTIVE pledge or a donation in the last N months.
        (SELECT COUNT(*) FROM Donor d
         WHERE EXISTS (SELECT 1 FROM RecurringDonation
                       WHERE DonorID = d.ID AND Status = 'ACTIVE')
            OR EXISTS (SELECT 1 FROM Donation
                       WHERE DonorID = d.ID AND DonationDate >= {_WINDOW_START})) AS activeDonors,
        (SELECT COUNT(*) FROM Donor WHERE RiskStatus = 'HIGH') AS atRiskDonors
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (active_months,))
            results = cursor.fetchall()
            cursor.close()
            if results:
                return results[0]
            return {}
    except Exception as e:
        raise TypeError(f"get_kpis error: {e}")


def get_monthly_donations():
    query = """
    SELECT
        MONTH(ScheduledDate) AS id,
        DATENAME(month, ScheduledDate) AS month,
        COALESCE(SUM(ExpectedAmount), 0) AS amount
    FROM Collection
    WHERE Status = 'SUCCESSFUL'
    GROUP BY MONTH(ScheduledDate), DATENAME(month, ScheduledDate)
    ORDER BY id ASC
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query)
            results = cursor.fetchall()
            cursor.close()
            return results if results else []
    except Exception as e:
        raise TypeError(f"get_monthly_donations error: {e}")


_USER_WITH_ROLE = """
    SELECT u.ID, u.Name, u.Email, r.Name AS Role
    FROM Users u
    INNER JOIN Role r ON r.ID = u.RoleID
"""


def read_user_by_credentials(email, password):
    query = _USER_WITH_ROLE + " WHERE u.Email = %s AND u.PasswordHash = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (email, password))
            output = cursor.fetchone()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_user_by_credentials: {e}")


def read_user_by_id(user_id):
    query = _USER_WITH_ROLE + " WHERE u.ID = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (user_id,))
            output = cursor.fetchone()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_user_by_id: {e}")


def read_user_profile(user_id):
    """Name, email and role of the user; None if it does not exist."""
    query = _USER_WITH_ROLE + " WHERE u.ID = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (user_id,))
            output = cursor.fetchone()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_user_profile: {e}")


# ---------------------------------------------------------------------------
# Donors (PanelAdmin "Donantes" screen)
# ---------------------------------------------------------------------------

def _fetch_all(query, params=()):
    with get_db_connection() as cnx:
        cursor = cnx.cursor(as_dict=True)
        cursor.execute(query, params)
        output = cursor.fetchall()
        cursor.close()
        return output


def _main_pledge_order(alias):
    """ORDER BY that puts the donor's main pledge first: ACTIVE, then PAUSED, then the rest."""
    return f"""
        ORDER BY CASE {alias}.Status WHEN 'ACTIVE' THEN 0 WHEN 'PAUSED' THEN 1 ELSE 2 END,
                 {alias}.NextInstallmentDate DESC, {alias}.ID DESC
    """


def read_donor_summaries(months):
    """
    One row per donor with what the donor list needs: last donation, total
    donated in the last `months` months, main pledge and assigned recolector.
    """
    query = f"""
        SELECT d.ID, d.Name, d.Phone, d.RiskStatus,
               ld.DonationDate AS LastDonationDate,
               ld.TotalAmount AS LastDonationAmount,
               ld.PaymentMethod AS LastPaymentMethod,
               COALESCE(w.WindowTotal, 0) AS WindowTotal,
               COALESCE(w.WindowCount, 0) AS WindowCount,
               p.Amount AS PledgeAmount,
               p.PaymentMethod AS PledgePaymentMethod,
               p.Status AS PledgeStatus,
               p.RecolectorID AS PledgeRecolectorID,
               lc.UserID AS LastCollectionUserID
        FROM Donor d
        OUTER APPLY (
            SELECT TOP 1 DonationDate, TotalAmount, PaymentMethod
            FROM Donation
            WHERE DonorID = d.ID
            ORDER BY DonationDate DESC, ID DESC
        ) ld
        OUTER APPLY (
            SELECT SUM(TotalAmount) AS WindowTotal, COUNT(*) AS WindowCount
            FROM Donation
            WHERE DonorID = d.ID AND DonationDate >= {_WINDOW_START}
        ) w
        OUTER APPLY (
            SELECT TOP 1 rd.Amount, rd.PaymentMethod, rd.Status, rd.RecolectorID
            FROM RecurringDonation rd
            WHERE rd.DonorID = d.ID
            {_main_pledge_order('rd')}
        ) p
        OUTER APPLY (
            SELECT TOP 1 UserID
            FROM Collection
            WHERE DonorID = d.ID
            ORDER BY ScheduledDate DESC, ID DESC
        ) lc
        ORDER BY d.Name
    """
    try:
        return _fetch_all(query, (months,))
    except Exception as e:
        raise TypeError(f"read_donor_summaries: {e}")


def read_recolectores():
    query = """
        SELECT u.ID, u.Name
        FROM Users u
        INNER JOIN Role r ON r.ID = u.RoleID
        WHERE r.Name = 'Recolector'
        ORDER BY u.Name
    """
    try:
        return _fetch_all(query)
    except Exception as e:
        raise TypeError(f"read_recolectores: {e}")


def read_donor(donor_id):
    query = "SELECT ID, Name, Phone, Address, RiskStatus FROM Donor WHERE ID = %s"
    try:
        rows = _fetch_all(query, (donor_id,))
        return rows[0] if rows else None
    except Exception as e:
        raise TypeError(f"read_donor: {e}")


def read_donor_donations(donor_id):
    query = """
        SELECT ID, DonationDate, TotalAmount, PaymentMethod, TargetCampaign,
               Notes, RecurringDonationID
        FROM Donation
        WHERE DonorID = %s
        ORDER BY DonationDate DESC, ID DESC
    """
    try:
        return _fetch_all(query, (donor_id,))
    except Exception as e:
        raise TypeError(f"read_donor_donations: {e}")


def read_donor_pledge(donor_id):
    """The donor's main pledge with the names of its telefonista and recolector."""
    query = f"""
        SELECT TOP 1 rd.ID, rd.Amount, rd.PaymentMethod, rd.TargetCampaign,
               rd.Frequency, rd.StartDate, rd.NextInstallmentDate, rd.EndDate,
               rd.Status, t.Name AS TelefonistaName, r.Name AS RecolectorName
        FROM RecurringDonation rd
        INNER JOIN Users t ON t.ID = rd.TelefonistaID
        INNER JOIN Users r ON r.ID = rd.RecolectorID
        WHERE rd.DonorID = %s
        {_main_pledge_order('rd')}
    """
    try:
        rows = _fetch_all(query, (donor_id,))
        return rows[0] if rows else None
    except Exception as e:
        raise TypeError(f"read_donor_pledge: {e}")


def read_donor_calls(donor_id):
    query = """
        SELECT pc.ID, pc.Type, pc.Status, pc.Notes, pc.ScheduledDate,
               u.Name AS UserName
        FROM PhoneCall pc
        INNER JOIN Users u ON u.ID = pc.UserID
        WHERE pc.DonorID = %s
        ORDER BY pc.ScheduledDate DESC, pc.ID DESC
    """
    try:
        return _fetch_all(query, (donor_id,))
    except Exception as e:
        raise TypeError(f"read_donor_calls: {e}")


def read_donor_collections(donor_id):
    query = """
        SELECT c.ID, c.Status, c.Notes, c.ScheduledDate, c.ExpectedAmount,
               u.Name AS UserName
        FROM Collection c
        INNER JOIN Users u ON u.ID = c.UserID
        WHERE c.DonorID = %s
        ORDER BY c.ScheduledDate DESC, c.ID DESC
    """
    try:
        return _fetch_all(query, (donor_id,))
    except Exception as e:
        raise TypeError(f"read_donor_collections: {e}")


def _insert_returning_id(query, params):
    """Runs an INSERT ... OUTPUT INSERTED.ID and returns the new ID."""
    with get_db_connection() as cnx:
        cursor = cnx.cursor(as_dict=True)
        cursor.execute(query, params)
        row = cursor.fetchone()
        cnx.commit()
        cursor.close()
        return row['ID']


def read_users_by_role(role):
    query = """
        SELECT u.ID, u.Name
        FROM Users u
        INNER JOIN Role r ON r.ID = u.RoleID
        WHERE r.Name = %s
        ORDER BY u.Name
    """
    try:
        return _fetch_all(query, (role,))
    except Exception as e:
        raise TypeError(f"read_users_by_role: {e}")


def create_donor(name, phone, address, risk_status):
    query = """
        INSERT INTO Donor (Name, Phone, Address, RiskStatus)
        OUTPUT INSERTED.ID
        VALUES (%s, %s, %s, %s)
    """
    try:
        return _insert_returning_id(query, (name, phone, address, risk_status))
    except Exception as e:
        raise TypeError(f"create_donor: {e}")


def create_phone_call(telefonista_id, donor_id, scheduled_date, notes):
    """A REGULAR call, PENDING, scheduled by an admin."""
    query = """
        INSERT INTO PhoneCall (UserID, DonorID, Type, Status, Notes, ScheduledDate)
        OUTPUT INSERTED.ID
        VALUES (%s, %s, 'REGULAR', 'PENDING', %s, %s)
    """
    try:
        return _insert_returning_id(query, (telefonista_id, donor_id, notes, scheduled_date))
    except Exception as e:
        raise TypeError(f"create_phone_call: {e}")


def create_collection(recolector_id, donor_id, scheduled_date, expected_amount, notes):
    """A PENDING collection; it goes last in the day's route (no RouteOrder)."""
    query = """
        INSERT INTO Collection (UserID, DonorID, Status, Notes, ScheduledDate, ExpectedAmount)
        OUTPUT INSERTED.ID
        VALUES (%s, %s, 'PENDING', %s, %s, %s)
    """
    try:
        return _insert_returning_id(
            query, (recolector_id, donor_id, notes, scheduled_date, expected_amount))
    except Exception as e:
        raise TypeError(f"create_collection: {e}")
