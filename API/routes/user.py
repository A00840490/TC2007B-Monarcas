import auth
import database as db

from flask import Blueprint, jsonify, make_response, request
from flasgger import swag_from

from routes import doc

bp_user = Blueprint('user', __name__)


@bp_user.route("/user", methods=['POST'])
@swag_from(doc('user.yml'))
def user_profile():

    data = request.get_json(silent=True) or {}

    token = data.get('token') or auth.token_from_request()

    if not isinstance(token, str) or not token:
        return make_response(
            jsonify({'error': 'Missing required parameter: token'}),
            400
        )

    try:
        # The user comes only from the verified token; any other field in the
        # body (e.g. userId) is ignored, so nobody can request someone else's data.
        user = auth.verify_token(token)

        profile = db.read_user_profile(user['ID'])
        if not profile:
            return make_response(jsonify({'error': 'User no longer exists'}), 404)

        return make_response(
            jsonify({
                'name': profile['Name'],
                'email': profile['Email'],
                'role': profile['Role'],
            }),
            200
        )

    except auth.AuthError as e:
        return make_response(jsonify({'error': e.message}), e.status)

    except Exception as e:
        print(str(e))
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )
