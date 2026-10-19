import auth
import database as db

from flask import Blueprint, g, jsonify, make_response, request
from flasgger import swag_from
from datetime import datetime

from routes import doc

bp_recolectores = Blueprint('recolectores', __name__, url_prefix='/recolectores')


@bp_recolectores.route("/route", methods=['GET'])
@swag_from(doc('recolector_route.yml'))
@auth.require_role(auth.ROLE_RECOLECTOR)
def recolector_route():
    # The recolector comes only from the verified token, never from the request.
    user_id = g.user['ID']
    date = request.args.get('date')

    if not date:
        return make_response(
            jsonify({'error': 'Missing required parameter: date'}),
            400
        )

    try:
        datetime.strptime(date, '%Y-%m-%d')
    except ValueError:
        return make_response(
            jsonify({'error': 'date must have the format YYYY-MM-DD'}),
            400
        )

    try:
        rows = db.read_collection_route(user_id, date)

        collections = [
            {
                'id': row['ID'],
                'scheduledDate': row['ScheduledDate'].isoformat(),
                'expectedAmount': float(row['ExpectedAmount']),
                'order': row['RouteOrder'],
                'donorName': row['DonorName'],
                'address': row['Address'],
            }
            for row in rows
        ]

        return make_response(jsonify(collections), 200)

    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )
