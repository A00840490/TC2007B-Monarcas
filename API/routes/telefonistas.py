import math

import auth
import telefonistas_db as db

from flask import Blueprint, g, jsonify, make_response, request
from flasgger import swag_from
from datetime import datetime, date

from errors import server_error
from routes import doc

bp_telefonistas = Blueprint('telefonistas', __name__, url_prefix='/telefonistas')

MAX_AMOUNT = 9999999999.99

RESULTADOS = {
    'NO_ANSWER': 'No contestó',
    'DECLINED': 'Rechazó',
    'ACCEPTED': 'Aceptó',
    'RESCHEDULED': 'Reagendó',
}


@bp_telefonistas.route("/calls", methods=['GET'])
@swag_from(doc('calls.yml'))
@auth.require_role(auth.ROLE_TELEFONISTA)
def get_calls():
    user_id = g.user['ID']

    try:
        rows = db.read_calls(user_id)
        calls = []
        for row in rows:
            if row['status'] != 'PENDING':
                state = 'Terminada'
            elif row['scheduledDate'] < datetime.now():
                state = 'Vencida'
            else:
                state = 'Próxima'

            calls.append({
                'id': row['id'],
                'time': str(row['scheduledDate']),
                'hour': row['scheduledDate'].strftime('%H:%M'),
                'status': row['status'],
                'state': state,
                'result': RESULTADOS.get(row['status'], ''),
                'goal': row['goal'] or '',
                'donor': {
                    'id': row['donorId'],
                    'name': row['donorName'],
                    'nickname': row['donorNickname'] or '',
                    'phone': row['donorPhone'] or '',
                    'campaign': row['donorCampaign'] or '',
                    'risk': row['donorRisk'] or '',
                    'pledge': float(row['donorPledge']) if row['donorPledge'] else 0,
                }
            })
        return make_response(jsonify(calls), 200)
    except Exception as e:
        return server_error(e)


@bp_telefonistas.route("/donors/<int:donor_id>", methods=['GET'])
@swag_from(doc('telefonista_donor.yml'))
@auth.require_role(auth.ROLE_TELEFONISTA)
def get_donor(donor_id):
    user_id = g.user['ID']

    try:
        donor = db.read_donor(donor_id)
        if donor is None:
            return make_response(jsonify({'error': 'Donor not found'}), 404)

        if not db.is_assigned(donor_id, user_id):
            return make_response(jsonify({'error': 'This donor is not in your assigned calls'}), 403)

        history = []
        for row in db.read_history(donor_id):
            history.append({
                'id': f"call-{row['id']}",
                'status': row['status'],
                'result': RESULTADOS.get(row['status'], ''),
                'date': str(row['date'].date()),
                'hour': row['date'].strftime('%H:%M'),
                'notes': row['notes'] or '',
                'amount': float(row['amount']) if row['amount'] else 0,
            })
        for row in db.read_notes(donor_id):
            history.append({
                'id': f"note-{row['id']}",
                'status': 'NOTE',
                'result': 'Nota',
                'date': str(row['date'].date()),
                'hour': row['date'].strftime('%H:%M'),
                'notes': row['note'],
                'amount': 0,
            })
        history.sort(key=lambda item: item['date'] + item['hour'], reverse=True)

        return make_response(jsonify({
            'id': donor['id'],
            'name': donor['name'],
            'nickname': donor['nickname'] or '',
            'phone': donor['phone'] or '',
            'officePhone': donor['officePhone'] or '',
            'email': donor['email'] or '',
            'address': donor['address'] or '',
            'risk': donor['risk'] or '',
            'campaign': donor['campaign'] or '',
            'pledge': float(donor['pledge']) if donor['pledge'] else 0,
            'history': history,
        }), 200)
    except Exception as e:
        return server_error(e)


@bp_telefonistas.route("/calls/<int:call_id>/result", methods=['POST'])
@swag_from(doc('call_result.yml'))
@auth.require_role(auth.ROLE_TELEFONISTA)
def save_result(call_id):
    user_id = g.user['ID']
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return make_response(jsonify({'error': 'The body must be a JSON object'}), 400)
    result = data.get('result')
    notes = data.get('notes') or ''

    if not isinstance(result, str) or result not in RESULTADOS:
        return make_response(jsonify({'error': 'result must be NO_ANSWER, DECLINED, ACCEPTED or RESCHEDULED'}), 400)
    if not isinstance(notes, str):
        return make_response(jsonify({'error': 'notes must be a string'}), 400)
    if len(notes) > 1000:
        return make_response(jsonify({'error': 'notes must have at most 1000 characters'}), 400)

    try:
        called_at = datetime.fromisoformat(data.get('calledAt'))
    except (TypeError, ValueError):
        called_at = datetime.now()

    new_date = None
    if result == 'ACCEPTED' or result == 'RESCHEDULED':
        if result == 'ACCEPTED':
            texto_fecha = data.get('collectionDate')
        else:
            texto_fecha = data.get('rescheduleDate')
        try:
            new_date = datetime.fromisoformat(texto_fecha)
        except (TypeError, ValueError):
            return make_response(jsonify({'error': 'Date must have the format YYYY-MM-DDTHH:MM:SS'}), 400)
        if new_date.date() < date.today():
            return make_response(jsonify({'error': 'The date cannot be in the past'}), 400)

    amount = data.get('amount') or 0
    if isinstance(amount, bool) or not isinstance(amount, (int, float)) or not math.isfinite(amount):
        return make_response(jsonify({'error': 'amount must be a number'}), 400)
    if result == 'ACCEPTED' and amount <= 0:
        return make_response(jsonify({'error': 'amount must be greater than 0'}), 400)
    if amount > MAX_AMOUNT:
        return make_response(jsonify({'error': 'amount is too large'}), 400)

    try:
        call = db.read_call(call_id)
        if call is None:
            return make_response(jsonify({'error': 'Call not found'}), 404)
        if call['userId'] != user_id:
            return make_response(jsonify({'error': 'This call is not assigned to you'}), 403)
        if call['status'] != 'PENDING':
            return make_response(jsonify({'error': 'This call already has a result'}), 400)

        db.save_result(call_id, result, notes, called_at)

        if result == 'ACCEPTED':
            recolector = db.read_recolector(call['donorId'])
            db.create_collection(recolector, call['donorId'], call_id, new_date, amount, notes)
        if result == 'RESCHEDULED':
            db.create_call(user_id, call['donorId'], new_date, call['goal'])

        return make_response(jsonify({'id': call_id, 'status': result, 'result': RESULTADOS[result]}), 200)
    except Exception as e:
        return server_error(e)


@bp_telefonistas.route("/donors/<int:donor_id>/notes", methods=['POST'])
@swag_from(doc('donor_note_create.yml'))
@auth.require_role(auth.ROLE_TELEFONISTA)
def add_note(donor_id):
    user_id = g.user['ID']
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return make_response(jsonify({'error': 'The body must be a JSON object'}), 400)
    note = data.get('note') or ''
    if not isinstance(note, str):
        return make_response(jsonify({'error': 'note must be a string'}), 400)
    note = note.strip()

    if note == '':
        return make_response(jsonify({'error': 'The note cannot be empty'}), 400)
    if len(note) > 1000:
        return make_response(jsonify({'error': 'note must have at most 1000 characters'}), 400)

    try:
        if db.read_donor(donor_id) is None:
            return make_response(jsonify({'error': 'Donor not found'}), 404)
        if not db.is_assigned(donor_id, user_id):
            return make_response(jsonify({'error': 'This donor is not in your assigned calls'}), 403)

        row = db.create_note(donor_id, user_id, note)
        return make_response(jsonify({
            'id': f"note-{row['id']}",
            'status': 'NOTE',
            'result': 'Nota',
            'date': str(row['date'].date()),
            'hour': row['date'].strftime('%H:%M'),
            'notes': row['note'],
            'amount': 0,
        }), 201)
    except Exception as e:
        return server_error(e)
