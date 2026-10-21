import re

import auth
import database as db
import passwords

from flask import Blueprint, jsonify, make_response, request
from flasgger import swag_from

from limiter import limiter
from errors import server_error
from routes import doc

bp_login = Blueprint('login', __name__)

MAX_EMAIL = 254
PASSWORD_HASH = re.compile(r'[0-9a-fA-F]{64}')
ROLES = (auth.ROLE_ADMIN, auth.ROLE_TELEFONISTA, auth.ROLE_RECOLECTOR)


def _valid_role(role):
    return isinstance(role, str) and role.strip().lower() in (r.lower() for r in ROLES)


@bp_login.route("/login/attempt", methods=['POST'])
@limiter.limit("5 per minute")
@swag_from(doc('login_attempt.yml'))
def login_attempt():

    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return make_response(jsonify({'error': 'The body must be a JSON object'}), 400)

    email = data.get('email')
    password = data.get('password')
    role = data.get('role')

    if not email or not password:
        return make_response(
            jsonify({'error': 'Missing required parameters: email or password'}),
            400
        )

    if not isinstance(email, str) or len(email) > MAX_EMAIL:
        return make_response(
            jsonify({'error': f'email must be a string of at most {MAX_EMAIL} characters'}), 400)

    if not isinstance(password, str) or not PASSWORD_HASH.fullmatch(password):
        return make_response(jsonify({'error': 'password must be a hex SHA-256 hash'}), 400)

    if role is not None and not _valid_role(role):
        return make_response(jsonify({'error': 'role must be Admin, Telefonista or Recolector'}), 400)

    try:
        found_user = db.read_user_by_email(email)
        stored_hash = found_user['PasswordHash'] if found_user else None

        if not passwords.verify_password(stored_hash, password):
            return make_response(jsonify({'error': 'Invalid credentials'}), 401)

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
        return server_error(e)


@bp_login.route("/login/verify", methods=['POST'])
@swag_from(doc('login_verify.yml'))
def login_verify():

    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return make_response(jsonify({'error': 'The body must be a JSON object'}), 400)

    token = data.get('token') or auth.token_from_request()
    role = data.get('role')

    if not isinstance(token, str) or not isinstance(role, str) or not token or not role:
        return make_response(
            jsonify({'error': 'Missing required parameters: token or role'}),
            400
        )

    if not _valid_role(role):
        return make_response(jsonify({'error': 'role must be Admin, Telefonista or Recolector'}), 400)

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
        return server_error(e)
