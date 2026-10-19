from database import get_db_connection


def read_calls(user_id):
    query = """
    SELECT
        pc.ID AS id,
        pc.ScheduledDate AS scheduledDate,
        pc.Status AS status,
        pc.Notes AS goal,
        d.ID AS donorId,
        d.Name AS donorName,
        d.Nickname AS donorNickname,
        d.Phone AS donorPhone,
        d.RiskStatus AS donorRisk,
        rd.TargetCampaign AS donorCampaign,
        rd.Amount AS donorPledge
    FROM PhoneCall pc
    JOIN Donor d ON pc.DonorID = d.ID
    LEFT JOIN RecurringDonation rd ON rd.DonorID = d.ID AND rd.Status = 'ACTIVE'
    WHERE pc.UserID = %s
      AND CAST(pc.ScheduledDate AS DATE) = CAST(GETDATE() AS DATE)
    ORDER BY pc.ScheduledDate
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (user_id,))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_calls: {e}")


def read_donor(donor_id):
    query = """
    SELECT
        d.ID AS id,
        d.Name AS name,
        d.Nickname AS nickname,
        d.Phone AS phone,
        d.OfficePhone AS officePhone,
        d.Email AS email,
        d.Address AS address,
        d.RiskStatus AS risk,
        rd.TargetCampaign AS campaign,
        rd.Amount AS pledge
    FROM Donor d
    LEFT JOIN RecurringDonation rd ON rd.DonorID = d.ID AND rd.Status = 'ACTIVE'
    WHERE d.ID = %s
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (donor_id,))
            output = cursor.fetchone()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_donor: {e}")


def is_assigned(donor_id, user_id):
    query = "SELECT COUNT(*) AS total FROM PhoneCall WHERE DonorID = %s AND UserID = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (donor_id, user_id))
            output = cursor.fetchone()
            cursor.close()
            return output['total'] > 0
    except Exception as e:
        raise TypeError(f"is_assigned: {e}")


def read_history(donor_id):
    query = """
    SELECT
        pc.ID AS id,
        pc.Status AS status,
        pc.ScheduledDate AS date,
        ISNULL(pc.ResultNotes, pc.Notes) AS notes,
        c.ExpectedAmount AS amount
    FROM PhoneCall pc
    LEFT JOIN Collection c ON c.CallID = pc.ID
    WHERE pc.DonorID = %s AND pc.Status <> 'PENDING'
    ORDER BY pc.ScheduledDate DESC
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (donor_id,))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_history: {e}")


def read_notes(donor_id):
    query = """
    SELECT ID AS id, Note AS note, CreatedAt AS date
    FROM DonorNote
    WHERE DonorID = %s
    ORDER BY CreatedAt DESC
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (donor_id,))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_notes: {e}")


def read_call(call_id):
    query = "SELECT ID AS id, UserID AS userId, DonorID AS donorId, Status AS status, Notes AS goal FROM PhoneCall WHERE ID = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (call_id,))
            output = cursor.fetchone()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_call: {e}")


def save_result(call_id, status, notes, called_at):
    query = "UPDATE PhoneCall SET Status = %s, ResultNotes = %s, CalledAt = %s WHERE ID = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (status, notes, called_at, call_id))
            cnx.commit()
            cursor.close()
    except Exception as e:
        raise TypeError(f"save_result: {e}")


def read_recolector(donor_id):
    # Primero el recolector de la promesa del donante
    query = "SELECT RecolectorID AS id FROM RecurringDonation WHERE DonorID = %s"
    # Si no tiene promesa, el primer recolector
    query2 = """
    SELECT TOP 1 u.ID AS id
    FROM Users u
    JOIN Role r ON u.RoleID = r.ID
    WHERE r.Name = 'Recolector'
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (donor_id,))
            output = cursor.fetchone()
            if output is None:
                cursor.execute(query2)
                output = cursor.fetchone()
            cursor.close()
            return output['id']
    except Exception as e:
        raise TypeError(f"read_recolector: {e}")


def create_collection(recolector_id, donor_id, call_id, date, amount, notes):
    query = """
    INSERT INTO Collection (UserID, DonorID, Status, Notes, ScheduledDate, ExpectedAmount, CallID)
    VALUES (%s, %s, 'PENDING', %s, %s, %s, %s)
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (recolector_id, donor_id, notes, date, amount, call_id))
            cnx.commit()
            cursor.close()
    except Exception as e:
        raise TypeError(f"create_collection: {e}")


def create_call(user_id, donor_id, date, goal):
    query = """
    INSERT INTO PhoneCall (UserID, DonorID, Type, Status, Notes, ScheduledDate)
    VALUES (%s, %s, 'REGULAR', 'PENDING', %s, %s)
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (user_id, donor_id, goal, date))
            cnx.commit()
            cursor.close()
    except Exception as e:
        raise TypeError(f"create_call: {e}")


def create_note(donor_id, user_id, note):
    query = """
    INSERT INTO DonorNote (DonorID, UserID, Note)
    OUTPUT INSERTED.ID AS id, INSERTED.Note AS note, INSERTED.CreatedAt AS date
    VALUES (%s, %s, %s)
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (donor_id, user_id, note))
            output = cursor.fetchone()
            cnx.commit()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"create_note: {e}")
