import auth
import recolectores_db as db

from decimal import Decimal, InvalidOperation
from flask import Blueprint, g, jsonify, make_response, request
from flasgger import swag_from
from datetime import datetime, date

from routes import doc

bp_recolectores = Blueprint('recolectores', __name__, url_prefix='/recolectores')

MAX_AMOUNT = Decimal('9999999999.99')   # DECIMAL(12, 2)
MAX_NOTES = 1000                        # Collection.Notes is NVARCHAR(1000)


def _error(message, status):
    return make_response(jsonify({'error': message}), status)


def _money(value):
    return float(value) if value is not None else None


def _parse_date(text):
    """YYYY-MM-DD -> date, or None if it is missing or has another format."""
    try:
        return datetime.strptime(text, '%Y-%m-%d').date()
    except (TypeError, ValueError):
        return None


def _own_collection(collection_id):
    """
    The collection, only if it exists and belongs to the recolector of the
    token. Returns (collection, error response). The id comes from the client,
    so it is never trusted: the owner is always checked against the token.
    """
    collection = db.read_collection(collection_id)
    if not collection:
        return None, _error('Collection not found', 404)
    if collection['UserID'] != g.user['ID']:
        return None, _error('This collection is not assigned to you', 403)
    return collection, None


@bp_recolectores.route("/route", methods=['GET'])
@swag_from(doc('recolector_route.yml'))
@auth.require_role(auth.ROLE_RECOLECTOR)
def recolector_route():
    # The recolector comes only from the verified token, never from the request.
    user_id = g.user['ID']
    date_text = request.args.get('date')

    if not date_text:
        return _error('Missing required parameter: date', 400)
    if _parse_date(date_text) is None:
        return _error('date must have the format YYYY-MM-DD', 400)

    try:
        rows = db.read_route(user_id, date_text)

        collections = [
            {
                'id': row['ID'],
                'scheduledDate': row['ScheduledDate'].isoformat(),
                'expectedAmount': _money(row['ExpectedAmount']) or 0.0,
                'order': row['RouteOrder'],
                'status': row['Status'],
                'receivedAmount': _money(row['ReceivedAmount']),
                'notes': row['Notes'],
                'donorName': row['DonorName'] or "", 
                'address': row['Address'] or "",
            }
            for row in rows
        ]

        return make_response(jsonify(collections), 200)

    except Exception as e:
        print(str(e))
        return _error('Server or database error', 500)


@bp_recolectores.route("/result", methods=['POST'])
@swag_from(doc('recolector_result.yml'))
@auth.require_role(auth.ROLE_RECOLECTOR)
def recolector_result():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return _error('The body must be a JSON object', 400)

    collection_id = data.get('collectionId')
    status = data.get('status')
    amount = data.get('receivedAmount')
    notes = data.get('notes')

    if collection_id is None or status is None:
        return _error('Missing required fields: collectionId or status', 400)
    if isinstance(collection_id, bool) or not isinstance(collection_id, int):
        return _error('collectionId must be an integer', 400)
    if status not in ('SUCCESSFUL', 'FAILED'):
        return _error("status must be 'SUCCESSFUL' or 'FAILED'", 400)

    if status == 'SUCCESSFUL':
        if amount is None:
            return _error('Missing receivedAmount for a SUCCESSFUL collection', 400)
        try:
            if isinstance(amount, bool) or not isinstance(amount, (int, float)):
                raise InvalidOperation
            amount = Decimal(str(amount))
            if not amount.is_finite():
                raise InvalidOperation
        except InvalidOperation:
            return _error('receivedAmount must be a number', 400)
        if amount <= 0:
            return _error('receivedAmount must be greater than 0', 400)
        if amount > MAX_AMOUNT:
            return _error('receivedAmount is too large', 400)
        amount = amount.quantize(Decimal('0.01'))
        notes = None
    else:
        if not isinstance(notes, str) or not notes.strip():
            return _error('Missing notes (the reason) for a FAILED collection', 400)
        notes = notes.strip()
        if len(notes) > MAX_NOTES:
            return _error(f'notes must have at most {MAX_NOTES} characters', 400)
        amount = None

    try:
        collection, error = _own_collection(collection_id)
        if error:
            return error
        if collection['Status'] != 'PENDING':
            return _error('This collection already has a result', 409)

        if not db.register_result(collection_id, g.user['ID'], status, amount, notes):
            return _error('This collection already has a result', 409)

        return make_response(
            jsonify({
                'id': collection_id,
                'status': status,
                'receivedAmount': _money(amount),
                'notes': notes,
            }),
            200
        )

    except Exception as e:
        print(str(e))
        return _error('Server or database error', 500)


@bp_recolectores.route("/reschedule", methods=['PUT'])
@swag_from(doc('recolector_reschedule.yml'))
@auth.require_role(auth.ROLE_RECOLECTOR)
def recolector_reschedule():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return _error('The body must be a JSON object', 400)

    collection_id = data.get('collectionId')
    new_date_text = data.get('newDate')

    if collection_id is None or new_date_text is None:
        return _error('Missing required fields: collectionId or newDate', 400)
    if isinstance(collection_id, bool) or not isinstance(collection_id, int):
        return _error('collectionId must be an integer', 400)

    new_date = _parse_date(new_date_text)
    if new_date is None:
        return _error('newDate must have the format YYYY-MM-DD', 400)
    if new_date <= date.today():
        return _error('newDate must be after today', 400)

    try:
        collection, error = _own_collection(collection_id)
        if error:
            return error
        if collection['Status'] != 'FAILED':
            return _error('Only a FAILED collection can be rescheduled', 409)

        # Same time of day as the original visit, on the new date.
        new_datetime = datetime.combine(new_date, collection['ScheduledDate'].time())

        if not db.reschedule_collection(collection_id, g.user['ID'], new_datetime):
            return _error('Only a FAILED collection can be rescheduled', 409)

        return make_response(
            jsonify({
                'id': collection_id,
                'status': 'PENDING',
                'scheduledDate': new_datetime.isoformat(),
            }),
            200
        )

    except Exception as e:
        print(str(e))
        return _error('Server or database error', 500)


@bp_recolectores.route("/history", methods=['GET'])
@swag_from(doc('recolector_history.yml'))
@auth.require_role(auth.ROLE_RECOLECTOR)
def recolector_history():
    collection_id = request.args.get('collectionId', type=int)
    if collection_id is None:
        return _error('Missing or invalid parameter: collectionId', 400)

    try:
        # Only the donor of one of the recolector's own collections.
        collection, error = _own_collection(collection_id)
        if error:
            return error

        donations = [
            {
                'id': row['ID'],
                'donationDate': row['DonationDate'].isoformat(),
                'totalAmount': _money(row['TotalAmount']),
                'paymentMethod': row['PaymentMethod'],
            }
            for row in db.read_donations(collection['DonorID'])
        ]

        return make_response(jsonify(donations), 200)

    except Exception as e:
        print(str(e))
        return _error('Server or database error', 500)


@bp_recolectores.route("/summary", methods=['GET'])
@swag_from(doc('recolector_summary.yml'))
@auth.require_role(auth.ROLE_RECOLECTOR)
def recolector_summary():
    # The recolector comes only from the verified token, never from the request.
    user_id = g.user['ID']
    date_text = request.args.get('date')

    if not date_text:
        return _error('Missing required parameter: date', 400)
    if _parse_date(date_text) is None:
        return _error('date must have the format YYYY-MM-DD', 400)

    try:
        row = db.read_summary(user_id, date_text)

        return make_response(
            jsonify({
                'date': date_text,
                'totalVisits': row['totalVisits'],
                'successful': row['successful'],
                'failed': row['failed'],
                'pending': row['pending'],
                'expectedAmount': _money(row['expectedAmount']) or 0.0,
                'receivedAmount': _money(row['receivedAmount']) or 0.0,
            }),
            200
        )

    except Exception as e:
        print(str(e))
        return _error('Server or database error', 500)
