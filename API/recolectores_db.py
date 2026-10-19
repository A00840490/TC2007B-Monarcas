from database import get_db_connection


def read_route(user_id, date):
    query = """
        SELECT c.ID, c.ScheduledDate, c.ExpectedAmount, c.RouteOrder,
               c.Status, c.Notes,
               CASE WHEN c.Status = 'SUCCESSFUL'
                    THEN COALESCE(dn.Amount, c.ExpectedAmount)
                    ELSE NULL END AS ReceivedAmount,
               d.Name AS DonorName, d.Address
        FROM Collection c
        INNER JOIN Donor d ON d.ID = c.DonorID
        OUTER APPLY (
            SELECT SUM(TotalAmount) AS Amount
            FROM Donation
            WHERE CollectionID = c.ID
        ) dn
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
        raise TypeError(f"read_route: {e}")


def read_collection(collection_id):
    query = """
        SELECT ID, UserID, DonorID, Status, ScheduledDate
        FROM Collection
        WHERE ID = %s
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (collection_id,))
            output = cursor.fetchone()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_collection: {e}")


def register_result(collection_id, user_id, status, amount, notes):
    """
    Closes a PENDING collection of that recolector as SUCCESSFUL or FAILED.
    A SUCCESSFUL one also creates its Donation (cash, linked by CollectionID);
    both changes are saved together or not at all.
    Returns False when nothing changed (not hers, or no longer PENDING).
    """
    update = """
        UPDATE Collection
        SET Status = %s, Notes = COALESCE(%s, Notes)
        WHERE ID = %s AND UserID = %s AND Status = 'PENDING'
    """
    insert = """
        INSERT INTO Donation (DonorID, TotalAmount, PaymentMethod, CollectionID)
        SELECT DonorID, %s, 'CASH', ID FROM Collection WHERE ID = %s
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            try:
                cursor.execute(update, (status, notes, collection_id, user_id))
                if cursor.rowcount == 0:
                    cnx.rollback()
                    return False
                if status == 'SUCCESSFUL':
                    cursor.execute(insert, (amount, collection_id))
                cnx.commit()
                return True
            except Exception:
                cnx.rollback()
                raise
            finally:
                cursor.close()
    except Exception as e:
        raise TypeError(f"register_result: {e}")


def reschedule_collection(collection_id, user_id, new_date):
    """
    Puts a FAILED collection of that recolector back to PENDING on new_date
    (a datetime). Its old route order no longer applies, so it is cleared.
    Returns False when nothing changed (not hers, or no longer FAILED).
    """
    query = """
        UPDATE Collection
        SET Status = 'PENDING', ScheduledDate = %s, RouteOrder = NULL
        WHERE ID = %s AND UserID = %s AND Status = 'FAILED'
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (new_date, collection_id, user_id))
            changed = cursor.rowcount > 0
            if changed:
                cnx.commit()
            else:
                cnx.rollback()
            cursor.close()
            return changed
    except Exception as e:
        raise TypeError(f"reschedule_collection: {e}")


def read_donations(donor_id):
    query = """
        SELECT TOP 10 ID, DonationDate, TotalAmount, PaymentMethod
        FROM Donation
        WHERE DonorID = %s
        ORDER BY DonationDate DESC, ID DESC
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (donor_id,))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_donations: {e}")


def read_summary(user_id, date):
    """
    Counts of the recolector's collections of one day by status. The amount
    received is the sum of each SUCCESSFUL collection's donations; if it has no
    donation yet, its ExpectedAmount is used (same rule as the dashboard).
    """
    query = """
        SELECT
            COUNT(c.ID) AS totalVisits,
            COALESCE(SUM(CASE WHEN c.Status = 'SUCCESSFUL' THEN 1 ELSE 0 END), 0) AS successful,
            COALESCE(SUM(CASE WHEN c.Status = 'FAILED' THEN 1 ELSE 0 END), 0) AS failed,
            COALESCE(SUM(CASE WHEN c.Status = 'PENDING' THEN 1 ELSE 0 END), 0) AS pending,
            COALESCE(SUM(c.ExpectedAmount), 0) AS expectedAmount,
            COALESCE(SUM(CASE WHEN c.Status = 'SUCCESSFUL'
                              THEN COALESCE(dn.Amount, c.ExpectedAmount, 0)
                              ELSE 0 END), 0) AS receivedAmount
        FROM Collection c
        OUTER APPLY (
            SELECT SUM(TotalAmount) AS Amount
            FROM Donation
            WHERE CollectionID = c.ID
        ) dn
        WHERE c.UserID = %s
          AND CAST(c.ScheduledDate AS DATE) = %s
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (user_id, date))
            output = cursor.fetchone()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_summary: {e}")
