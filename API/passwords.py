import hmac

from werkzeug.security import check_password_hash, generate_password_hash

import config

_METHOD = 'pbkdf2:sha256:600000'
_SALT_LENGTH = 16


def _peppered(client_hash):
    return hmac.new(config.PASSWORD_PEPPER.encode(), client_hash.lower().encode(),
                    'sha256').hexdigest()


def hash_password(client_hash):
    return generate_password_hash(_peppered(client_hash), method=_METHOD, salt_length=_SALT_LENGTH)


_DUMMY_HASH = hash_password('0' * 64)


def is_salted(stored_hash):
    return isinstance(stored_hash, str) and stored_hash.startswith('pbkdf2:')


def verify_password(stored_hash, client_hash):
    if not is_salted(stored_hash):
        check_password_hash(_DUMMY_HASH, _peppered(client_hash))
        return False
    return check_password_hash(stored_hash.strip(), _peppered(client_hash))
