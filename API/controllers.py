from datetime import date, datetime
from decimal import Decimal, InvalidOperation

import auth
import database as db

# A donor is "active" with an ACTIVE recurring pledge or a donation in the last
# N months. The donor list lets the admin choose N; the dashboard uses the default.
ACTIVE_DONOR_MONTHS = 6
ALLOWED_WINDOW_MONTHS = (3, 6, 12)

# Activity items returned for a donor's detail, newest first.
DONOR_ACTIVITY_LIMIT = 10


def get_dashboard_kpis():
    try:
        data = db.get_kpis(ACTIVE_DONOR_MONTHS)

        return {
            'availableMoney': int(data.get('availableMoney', 0)),
            'pledgedMoney': int(data.get('pledgedMoney', 0)),
            'activeDonors': int(data.get('activeDonors', 0)),
            'atRiskDonors': int(data.get('atRiskDonors', 0)),
        }
    except Exception as e:
        print(f"Error in get_dashboard_kpis: {e}")
        return {
            'availableMoney': 0,
            'pledgedMoney': 0,
            'activeDonors': 0,
            'atRiskDonors': 0,
        }


def get_monthly_donations():
    try:
        data = db.get_monthly_donations()

        result = []
        for item in data:
            result.append({
                'id': int(item.get('id', 0)),
                'month': str(item.get('month', '')).strip(),
                'amount': int(item.get('amount', 0))
            })

        return result
    except Exception as e:
        print(f"Error in get_monthly_donations: {e}")
        return []


def _iso(value):
    """Date or datetime as an ISO string (None stays None)."""
    if value is None:
        return None
    return value.isoformat()


def _money(value):
    return float(value) if value is not None else None


def _as_date(value):
    return value.date() if isinstance(value, datetime) else value


def get_donor_list(months):
    """
    Summary row of every donor plus the screen's indicators for a window of
    `months` months. `isActive` follows ACTIVE_DONOR_MONTHS' rule with that window.
    """
    today = date.today()
    donors = []
    for row in db.read_donor_summaries(months):
        has_active_pledge = row['PledgeStatus'] == 'ACTIVE'
        last_date = _as_date(row['LastDonationDate'])
        donors.append({
            'id': row['ID'],
            'name': row['Name'],
            'phone': row['Phone'] or '',
            'riskStatus': row['RiskStatus'],
            'isActive': has_active_pledge or row['WindowCount'] > 0,
            'everDonated': last_date is not None,
            'hasActivePledge': has_active_pledge,
            'pledgeAmount': _money(row['PledgeAmount']) if has_active_pledge else None,
            'lastDonationDate': _iso(last_date),
            'lastDonationAmount': _money(row['LastDonationAmount']),
            'daysSinceLastDonation': (today - last_date).days if last_date else None,
            'windowTotal': _money(row['WindowTotal']),
            # Pledge's method if there is one, otherwise the last donation's.
            'paymentMethod': row['PledgePaymentMethod'] or row['LastPaymentMethod'],
            'recolectorId': row['PledgeRecolectorID'] or row['LastCollectionUserID'],
        })

    active = [d for d in donors if d['isActive']]
    with_pledge = [d for d in active if d['hasActivePledge']]
    return {
        'months': months,
        'summary': {
            'activeDonors': len(active),
            'totalDonors': len(donors),
            'donorsWithPledge': len(with_pledge),
            'monthlyCommitted': sum(d['pledgeAmount'] for d in with_pledge),
            'raisedByActive': sum(d['windowTotal'] for d in active),
            'donorsToRecover': sum(1 for d in donors if not d['isActive'] and d['everDonated']),
        },
        'donors': donors,
        'recolectores': [{'id': r['ID'], 'name': r['Name']} for r in db.read_recolectores()],
    }


def _month_totals(donations, today):
    """Donated amount per month for the last 12 months, oldest first."""
    months = []
    for back in range(11, -1, -1):
        year, month = today.year, today.month - back
        while month < 1:
            month += 12
            year -= 1
        months.append({'year': year, 'month': month, 'amount': 0.0})

    index = {(m['year'], m['month']): m for m in months}
    for donation in donations:
        day = _as_date(donation['DonationDate'])
        bucket = index.get((day.year, day.month))
        if bucket:
            bucket['amount'] += float(donation['TotalAmount'])
    return months


def _months_ago(today, months):
    """The same day `months` months ago (last day of the month if it does not exist)."""
    year, month = today.year, today.month - months
    while month < 1:
        month += 12
        year -= 1
    for day in (today.day, 30, 29, 28):
        try:
            return date(year, month, day)
        except ValueError:
            continue


def get_donor_detail(donor_id, months):
    """Everything the donor's screen shows; None if the donor does not exist."""
    donor = db.read_donor(donor_id)
    if not donor:
        return None

    today = date.today()
    window_start = _months_ago(today, months)
    donations = db.read_donor_donations(donor_id)
    pledge = db.read_donor_pledge(donor_id)
    calls = db.read_donor_calls(donor_id)
    collections = db.read_donor_collections(donor_id)

    in_window = [d for d in donations if _as_date(d['DonationDate']) >= window_start]
    has_active_pledge = pledge is not None and pledge['Status'] == 'ACTIVE'

    # Next PENDING call or collection from today on
    pending = [
        {'kind': 'CALL', 'type': c['Type'], 'date': c['ScheduledDate'], 'userName': c['UserName']}
        for c in calls if c['Status'] == 'PENDING' and _as_date(c['ScheduledDate']) >= today
    ] + [
        {'kind': 'COLLECTION', 'type': None, 'date': c['ScheduledDate'], 'userName': c['UserName']}
        for c in collections if c['Status'] == 'PENDING' and _as_date(c['ScheduledDate']) >= today
    ]
    upcoming = min(pending, key=lambda p: p['date']) if pending else None
    if upcoming:
        upcoming = {**upcoming, 'date': _iso(upcoming['date'])}

    activity = [
        {
            'kind': 'DONATION', 'id': d['ID'], 'date': d['DonationDate'],
            'amount': _money(d['TotalAmount']), 'paymentMethod': d['PaymentMethod'],
            'campaign': d['TargetCampaign'], 'isInstallment': d['RecurringDonationID'] is not None,
            'status': None, 'type': None, 'userName': None, 'notes': d['Notes'],
        }
        for d in donations
    ] + [
        {
            'kind': 'CALL', 'id': c['ID'], 'date': c['ScheduledDate'],
            'amount': None, 'paymentMethod': None, 'campaign': None, 'isInstallment': False,
            'status': c['Status'], 'type': c['Type'], 'userName': c['UserName'], 'notes': c['Notes'],
        }
        for c in calls
    ] + [
        {
            'kind': 'COLLECTION', 'id': c['ID'], 'date': c['ScheduledDate'],
            'amount': _money(c['ExpectedAmount']), 'paymentMethod': None, 'campaign': None,
            'isInstallment': False, 'status': c['Status'], 'type': None,
            'userName': c['UserName'], 'notes': c['Notes'],
        }
        for c in collections
    ]
    activity.sort(key=lambda a: a['date'] if isinstance(a['date'], datetime)
                  else datetime.combine(a['date'], datetime.min.time()), reverse=True)
    activity = [{**a, 'date': _iso(a['date'])} for a in activity[:DONOR_ACTIVITY_LIMIT]]

    return {
        'id': donor['ID'],
        'name': donor['Name'],
        'phone': donor['Phone'] or '',
        'address': donor['Address'] or '',
        'riskStatus': donor['RiskStatus'],
        'isActive': has_active_pledge or len(in_window) > 0,
        'months': months,
        'stats': {
            'lifetimeTotal': sum(float(d['TotalAmount']) for d in donations),
            'windowTotal': sum(float(d['TotalAmount']) for d in in_window),
            'donationCount': len(donations),
            'firstDonationDate': _iso(_as_date(donations[-1]['DonationDate'])) if donations else None,
        },
        'monthlyTotals': _month_totals(donations, today),
        'pledge': None if pledge is None else {
            'id': pledge['ID'],
            'amount': _money(pledge['Amount']),
            'paymentMethod': pledge['PaymentMethod'],
            'campaign': pledge['TargetCampaign'],
            'frequency': pledge['Frequency'],
            'startDate': _iso(pledge['StartDate']),
            'nextInstallmentDate': _iso(pledge['NextInstallmentDate']),
            'endDate': _iso(pledge['EndDate']),
            'status': pledge['Status'],
            'telefonistaName': pledge['TelefonistaName'],
            'recolectorName': pledge['RecolectorName'],
        },
        'upcoming': upcoming,
        'activity': activity,
    }


# ---------------------------------------------------------------------------
# Creating donors, calls and collections from the admin panel
# ---------------------------------------------------------------------------

RISK_STATUSES = ('LOW', 'MEDIUM', 'HIGH')


class ValidationError(Exception):
    """Invalid request data; the route answers 400 with this message."""


def _text(data, key, max_length, required=False):
    value = data.get(key)
    if value is None:
        value = ''
    if not isinstance(value, str):
        raise ValidationError(f'{key} must be a string')
    value = value.strip()
    if required and not value:
        raise ValidationError(f'Missing required field: {key}')
    if len(value) > max_length:
        raise ValidationError(f'{key} must have at most {max_length} characters')
    return value or None


def _int(data, key):
    value = data.get(key)
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValidationError(f'{key} must be an integer')
    return value


def _scheduled_date(data):
    """`scheduledDate` as 'YYYY-MM-DDTHH:MM[:SS]'; today or later."""
    value = data.get('scheduledDate')
    try:
        scheduled = datetime.fromisoformat(value)
    except (TypeError, ValueError):
        raise ValidationError('scheduledDate must have the format YYYY-MM-DDTHH:MM:SS')
    scheduled = scheduled.replace(tzinfo=None, microsecond=0)
    if scheduled.date() < date.today():
        raise ValidationError('scheduledDate cannot be in the past')
    return scheduled


def _existing_donor(donor_id):
    donor = db.read_donor(donor_id)
    if not donor:
        raise ValidationError('Donor not found')
    return donor


def _user_with_role(user_id, role):
    """Rule 8: calls go to a telefonista and collections to a recolector."""
    user = db.read_user_by_id(user_id)
    if not user or (user['Role'] or '').strip().lower() != role.lower():
        raise ValidationError(f'User {user_id} is not a {role}')
    return user


def get_staff():
    """Telefonistas and recolectores to assign calls and collections to."""
    as_list = lambda rows: [{'id': r['ID'], 'name': r['Name']} for r in rows]
    return {
        'telefonistas': as_list(db.read_users_by_role(auth.ROLE_TELEFONISTA)),
        'recolectores': as_list(db.read_users_by_role(auth.ROLE_RECOLECTOR)),
    }


def create_donor(data):
    name = _text(data, 'name', 150, required=True)
    phone = _text(data, 'phone', 20)
    address = _text(data, 'address', 300)
    risk_status = (data.get('riskStatus') or 'LOW')
    if risk_status not in RISK_STATUSES:
        raise ValidationError('riskStatus must be LOW, MEDIUM or HIGH')

    donor_id = db.create_donor(name, phone, address, risk_status)
    return {'id': donor_id, 'name': name, 'phone': phone or '', 'address': address or '',
            'riskStatus': risk_status}


def schedule_call(data):
    donor_id = _int(data, 'donorId')
    telefonista_id = _int(data, 'telefonistaId')
    scheduled = _scheduled_date(data)
    notes = _text(data, 'notes', 1000)
    _existing_donor(donor_id)
    _user_with_role(telefonista_id, auth.ROLE_TELEFONISTA)

    call_id = db.create_phone_call(telefonista_id, donor_id, scheduled, notes)
    return {'id': call_id, 'donorId': donor_id, 'telefonistaId': telefonista_id,
            'type': 'REGULAR', 'status': 'PENDING', 'scheduledDate': _iso(scheduled),
            'notes': notes}


def schedule_collection(data):
    donor_id = _int(data, 'donorId')
    recolector_id = _int(data, 'recolectorId')
    scheduled = _scheduled_date(data)
    notes = _text(data, 'notes', 1000)

    expected_amount = data.get('expectedAmount')
    if expected_amount is not None:
        try:
            expected_amount = Decimal(str(expected_amount))
            if isinstance(data.get('expectedAmount'), bool) or not expected_amount.is_finite():
                raise InvalidOperation
            expected_amount = expected_amount.quantize(Decimal('0.01'))
        except InvalidOperation:
            raise ValidationError('expectedAmount must be a number')
        if expected_amount < 0:
            raise ValidationError('expectedAmount cannot be negative')

    _existing_donor(donor_id)
    _user_with_role(recolector_id, auth.ROLE_RECOLECTOR)

    collection_id = db.create_collection(recolector_id, donor_id, scheduled, expected_amount, notes)
    return {'id': collection_id, 'donorId': donor_id, 'recolectorId': recolector_id,
            'status': 'PENDING', 'scheduledDate': _iso(scheduled),
            'expectedAmount': _money(expected_amount), 'notes': notes}
