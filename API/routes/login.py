import auth
import database as db

from flask import Blueprint, jsonify, make_response, request
from flasgger import swag_from

from routes import doc

bp_login = Blueprint('login', __name__)


@bp_login.route("/login/attempt", methods=['POST'])
@swag_from(doc('login_attempt.yml'))
def login_attempt():

    data = request.get_json(silent=True) or {}

    email = data.get('email')
    password = data.get('password')
    role = data.get('role')

    if not email or not password:
        return make_response(
            jsonify({'error': 'Missing required parameters: email or password'}),
            400
        )

    if role is not None and not isinstance(role, str):
        return make_response(jsonify({'error': 'role must be a string'}), 400)

    try:
        found_user = db.read_user_by_credentials(email, password)

        if not found_user:
            return make_response(jsonify({'error': 'Invalid credentials'}), 401)

        # If the app says which role its login is for, only that role is accepted.
        if role and found_user['Role'].strip().lower() != role.strip().lower():
            return make_response(jsonify({'error': f'User is not {role}'}), 403)

        return make_response(
            jsonify({
                'token': auth.create_token(found_user['ID'], found_user['Role']),
                'userId': found_user['ID'],
                'role': found_user['Role'],
            }),
            200
        )

    except Exception as e:
        print(str(e))
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_login.route("/login/verify", methods=['POST'])
@swag_from(doc('login_verify.yml'))
def login_verify():

    data = request.get_json(silent=True) or {}

    token = data.get('token') or auth.token_from_request()
    role = data.get('role')

    if not isinstance(token, str) or not isinstance(role, str) or not token or not role:
        return make_response(
            jsonify({'error': 'Missing required parameters: token or role'}),
            400
        )

    try:
        user = auth.verify_token(token, [role])

        return make_response(
            jsonify({
                'valid': True,
                'userId': user['ID'],
                'role': user['Role'],
            }),
            200
        )

    except auth.AuthError as e:
        return make_response(jsonify({'valid': False, 'error': e.message}), e.status)

    except Exception as e:
        print(str(e))
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )
