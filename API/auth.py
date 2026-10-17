from datetime import datetime, timedelta, timezone
from functools import wraps

import jwt
from flask import g, jsonify, make_response, request

import config
import database as db

# Role names as stored in the Role table.
ROLE_RECOLECTOR = 'Recolector'
ROLE_TELEFONISTA = 'Telefonista'
ROLE_ADMIN = 'Admin'

_ALGORITHM = 'HS256'


class AuthError(Exception):
    """Authentication error with its HTTP status code."""

    def __init__(self, message, status):
        super().__init__(message)
        self.message = message
        self.status = status


def create_token(user_id, role):
    now = datetime.now(timezone.utc)
    payload = {
        'sub': str(user_id),
        'role': role,
        'iat': now,
        'exp': now + timedelta(hours=config.JWT_EXP_HOURS),
    }
    return jwt.encode(payload, config.JWT_SECRET, algorithm=_ALGORITHM)


def _same_role(a, b):
    return (a or '').strip().lower() == (b or '').strip().lower()


def verify_token(token, allowed_roles=None):
    """
    Checks the token's signature and expiration, that the user still exists in
    the database and that their current role (Role table) is one of the allowed
    ones. With allowed_roles=None any role is accepted.
    Returns the database user or raises AuthError.
    """
    if not token:
        raise AuthError('Missing token', 401)

    try:
        payload = jwt.decode(token, config.JWT_SECRET, algorithms=[_ALGORITHM])
        user_id = int(payload['sub'])
    except jwt.ExpiredSignatureError:
        raise AuthError('Token expired', 401)
    except (jwt.InvalidTokenError, KeyError, ValueError):
        raise AuthError('Invalid token', 401)

    user = db.read_user_by_id(user_id)
    if not user:
        raise AuthError('User no longer exists', 401)

    # Compare against the current role in the database, not only the one in the
    # token, so a role change takes effect without waiting for the token to expire.
    if not _same_role(payload.get('role'), user['Role']):
        raise AuthError('User role changed; log in again', 401)

    if allowed_roles is not None and not any(
            _same_role(user['Role'], role) for role in allowed_roles):
        raise AuthError('User is not allowed to access this resource', 403)

    return user


def token_from_request():
    header = request.headers.get('Authorization', '')
    if header.lower().startswith('bearer '):
        return header[7:].strip()
    return None


def require_role(*roles):
    """
    Protects an endpoint: requires 'Authorization: Bearer <token>' from a user
    with one of the given roles. The user is available in g.user.

        @bp_admin_panel.route('/dashboard')
        @require_role(ROLE_ADMIN)
        def dashboard(): ...
    """
    def decorator(function):
        @wraps(function)
        def wrapper(*args, **kwargs):
            try:
                g.user = verify_token(token_from_request(), roles)
            except AuthError as e:
                return make_response(jsonify({'error': e.message}), e.status)
            except Exception as e:
                return make_response(
                    jsonify({'error': f'Server or database error: {str(e)}'}),
                    500
                )
            return function(*args, **kwargs)
        return wrapper
    return decorator
