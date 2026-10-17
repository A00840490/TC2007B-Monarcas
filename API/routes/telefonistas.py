import database as db

from flask import Blueprint, jsonify, make_response
from flasgger import swag_from

from routes import doc

bp_telefonistas = Blueprint('telefonistas', __name__, url_prefix='/telefonistas')


@bp_telefonistas.route("/calls", methods=['GET'])
@swag_from(doc('calls.yml'))
def get_calls():
    rows = db.read_shift_calls()
    calls = []
    for row in rows:
        calls.append({
            'id': row['id'],
            'time': str(row['scheduledDate']),
            'status': row['status'],
            'goal': row['goal'] or '',
            'donor': {
                'id': row['donorId'],
                'name': row['donorName'],
                'phone': row['donorPhone'] or '',
                'pledge': str(row['donorTotal']) if row['donorTotal'] else '',
                'campaign': row['donorCampaign'] or '',
                'risk': row['donorRisk'] or '',
                'lastContact': str(row['donorDate']) if row['donorDate'] else '',
            }
        })
    return make_response(jsonify(calls))
