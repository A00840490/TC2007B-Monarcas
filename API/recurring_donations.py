import calendar
from datetime import date, datetime, time, timedelta

import database as db

CASH = 'CASH'
TRANSFER = 'TRANSFER'

CALL_TYPE_CONFIRMATION = 'CONFIRMATION'
CALL_TYPE_TRANSFER_COLLECTION = 'TRANSFER_COLLECTION'

ACTION_COLLECTION = 'COLLECTION'
ACTION_TRANSFER = 'TRANSFER'
ACTION_SKIP = 'SKIP'

ACTIONS = (ACTION_COLLECTION, ACTION_TRANSFER, ACTION_SKIP)


def next_installment(start_date, installment):
    year, month = (installment.year + 1, 1) if installment.month == 12 \
        else (installment.year, installment.month + 1)
    last_day = calendar.monthrange(year, month)[1]
    return date(year, month, min(start_date.day, last_day))


def default_action(payment_method):
    return ACTION_TRANSFER if payment_method == TRANSFER else ACTION_COLLECTION


def _to_date(value):
    return value.date() if isinstance(value, datetime) else value


def resolve_installment(pledge_id, installment, action, call_id=None, today=None):
    if action not in ACTIONS:
        raise ValueError(f'Invalid action: {action}')

    today = today or date.today()

    with db.get_db_connection() as cnx:
        cursor = cnx.cursor(as_dict=True)
        try:
            cursor.execute("""
                SELECT ID, DonorID, Amount, TargetCampaign, StartDate,
                       NextInstallmentDate, EndDate, Status, TelefonistaID, RecolectorID
                FROM RecurringDonation WITH (UPDLOCK, ROWLOCK)
                WHERE ID = %s
            """, (pledge_id,))
            pledge = cursor.fetchone()

            if (not pledge or pledge['Status'] != 'ACTIVE'
                    or _to_date(pledge['NextInstallmentDate']) != installment):
                cnx.rollback()
                return False

            due_date = datetime.combine(max(installment, today), time())
            campaign = pledge['TargetCampaign'] or 'sin campaña'

            if action == ACTION_COLLECTION:
                cursor.execute("""
                    INSERT INTO Collection
                        (UserID, DonorID, Status, Notes, ScheduledDate,
                         ExpectedAmount, CallID, RecurringDonationID)
                    VALUES (%s, %s, 'PENDING', %s, %s, %s, %s, %s)
                """, (
                    pledge['RecolectorID'], pledge['DonorID'],
                    f'Cuota mensual ({campaign})', due_date,
                    pledge['Amount'], call_id, pledge['ID'],
                ))
            elif action == ACTION_TRANSFER:
                cursor.execute("""
                    INSERT INTO PhoneCall
                        (UserID, DonorID, Status, Notes, ScheduledDate,
                         Type, RecurringDonationID)
                    VALUES (%s, %s, 'PENDING', %s, %s, %s, %s)
                """, (
                    pledge['TelefonistaID'], pledge['DonorID'],
                    f"Concretar transferencia de la cuota mensual de ${pledge['Amount']} ({campaign})",
                    due_date, CALL_TYPE_TRANSFER_COLLECTION, pledge['ID'],
                ))

            following = next_installment(_to_date(pledge['StartDate']), installment)
            end_date = _to_date(pledge['EndDate'])
            status = 'FINISHED' if end_date and following > end_date else 'ACTIVE'

            cursor.execute("""
                UPDATE RecurringDonation
                SET NextInstallmentDate = %s, Status = %s
                WHERE ID = %s
            """, (following, status, pledge['ID']))

            cnx.commit()
            return True
        except Exception:
            cnx.rollback()
            raise
        finally:
            cursor.close()


def pledges_with_overdue_installment(today):
    query = """
        SELECT rd.ID, rd.NextInstallmentDate AS Installment, rd.PaymentMethod,
               (SELECT TOP 1 pc.ID FROM PhoneCall pc
                WHERE pc.RecurringDonationID = rd.ID
                  AND pc.Type = %s
                  AND CAST(pc.ScheduledDate AS DATE) = DATEADD(day, -1, rd.NextInstallmentDate)
                ORDER BY pc.ID DESC) AS ConfirmationCallID
        FROM RecurringDonation rd
        WHERE rd.Status = 'ACTIVE' AND rd.NextInstallmentDate <= %s
    """
    with db.get_db_connection() as cnx:
        cursor = cnx.cursor(as_dict=True)
        cursor.execute(query, (CALL_TYPE_CONFIRMATION, today))
        output = cursor.fetchall()
        cursor.close()
        return output


def create_confirmation_calls(today):
    query = """
        INSERT INTO PhoneCall
            (UserID, DonorID, Status, Notes, ScheduledDate,
             Type, RecurringDonationID)
        SELECT rd.TelefonistaID, rd.DonorID, 'PENDING',
               CASE rd.PaymentMethod
                   WHEN 'CASH' THEN 'Confirmar que mañana puede recibir al recolector'
                   ELSE 'Preguntar si mañana prefiere que pasen a recoger o concretar la transferencia'
               END,
               %s, %s, rd.ID
        FROM RecurringDonation rd
        WHERE rd.Status = 'ACTIVE'
          AND rd.NextInstallmentDate = %s
          AND NOT EXISTS (
              SELECT 1 FROM PhoneCall pc
              WHERE pc.RecurringDonationID = rd.ID
                AND pc.Type = %s
                AND CAST(pc.ScheduledDate AS DATE) = %s
          )
    """
    tomorrow = today + timedelta(days=1)
    with db.get_db_connection() as cnx:
        cursor = cnx.cursor()
        try:
            cursor.execute(query, (
                datetime.combine(today, time()), CALL_TYPE_CONFIRMATION,
                tomorrow, CALL_TYPE_CONFIRMATION, today,
            ))
            created = cursor.rowcount
            cnx.commit()
            return created
        except Exception:
            cnx.rollback()
            raise
        finally:
            cursor.close()
