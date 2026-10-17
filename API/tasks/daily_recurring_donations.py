"""
Daily task for recurring donation pledges. Run once a day, early (before phone
telefonistas and recolectores start), from the API/ folder:

    python -m tasks.daily_recurring_donations

Example cron entry at 6:00:

    0 6 * * * cd /path/to/repo/API && .venv/bin/python -m tasks.daily_recurring_donations >> /var/log/recurring_donations.log 2>&1

It does two things, in this order:
1. Installments due today (or overdue) that nobody resolved get the default
   action: with cash the recolector is sent even if the donor did not answer;
   with a transfer, the call to complete it is scheduled.
2. Installments due tomorrow get today's confirmation call.

It can run more than once a day without duplicating anything.
Exits with code 1 if anything failed, so cron logs it.
"""
import sys
from datetime import date, datetime

import config
import database as db
import recurring_donations


def _log(message):
    print(f"[{datetime.now().isoformat(timespec='seconds')}] {message}", flush=True)


def resolve_overdue_installments(today):
    resolved = 0
    errors = 0
    for row in recurring_donations.pledges_with_overdue_installment(today):
        installment = row['Installment']
        installment = installment.date() if isinstance(installment, datetime) else installment
        action = recurring_donations.default_action(row['PaymentMethod'])
        try:
            if recurring_donations.resolve_installment(
                    row['ID'], installment, action,
                    call_id=row['ConfirmationCallID'], today=today):
                resolved += 1
                _log(f"Pledge {row['ID']}: unconfirmed installment of {installment}, applied {action}")
        except Exception as e:
            errors += 1
            _log(f"Pledge {row['ID']}: error resolving the installment of {installment}: {e}")
    return resolved, errors


def main(today=None):
    today = today or date.today()

    db.init_db_pool({
        'DB_HOST': config.DB_HOST,
        'DB_PORT': config.DB_PORT,
        'DB_NAME': config.DB_NAME,
        'DB_USER': config.TASKS_DB_USER,
        'DB_PASSWORD': config.TASKS_DB_PASSWORD,
    }, min_connections=1, max_connections=2)

    resolved, errors = resolve_overdue_installments(today)
    _log(f"Overdue installments resolved: {resolved}, failed: {errors}")

    try:
        created = recurring_donations.create_confirmation_calls(today)
        _log(f"Confirmation calls created: {created}")
    except Exception as e:
        errors += 1
        _log(f"Error creating confirmation calls: {e}")

    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
