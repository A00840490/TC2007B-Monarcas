import os
import sys

from dotenv import load_dotenv

# Load variables from API/.env (if present) without overriding the ones
# already set in the server's environment.
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))


def _required(name):
    value = os.getenv(name)
    if not value:
        print(f"Missing required environment variable: {name}")
        sys.exit(1)
    return value


def _bool(name, default=False):
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in ('1', 'true', 'yes', 'si', 'sí')


DB_HOST = _required('DB_HOST')
DB_PORT = int(os.getenv('DB_PORT', '1433'))
DB_NAME = _required('DB_NAME')
DB_USER = _required('DB_USER')
DB_PASSWORD = _required('DB_PASSWORD')

# Account of the daily task (tasks/daily_recurring_donations.py). It needs
# permissions the API account does not have (see API/sql/04_app_users.sql).
# Falls back to DB_USER / DB_PASSWORD when not set.
TASKS_DB_USER = os.getenv('TASKS_DB_USER') or DB_USER
TASKS_DB_PASSWORD = os.getenv('TASKS_DB_PASSWORD') or DB_PASSWORD

API_HOST = os.getenv('API_HOST', '0.0.0.0')
API_PORT = int(os.getenv('API_PORT', '10206'))
API_DEBUG = _bool('API_DEBUG', False)

# HTTPS. When both paths are set the API serves HTTPS with that certificate;
# otherwise it falls back to plain HTTP.
# Relative paths are resolved from the API/ folder.
def _api_path(name):
    value = os.getenv(name, '').strip()
    if value and not os.path.isabs(value):
        value = os.path.join(os.path.dirname(os.path.abspath(__file__)), value)
    return value


SSL_CERT_FILE = _api_path('SSL_CERT_FILE')
SSL_KEY_FILE = _api_path('SSL_KEY_FILE')
for _path in (SSL_CERT_FILE, SSL_KEY_FILE):
    if _path and not os.path.isfile(_path):
        print(f"SSL file not found: {_path}")
        sys.exit(1)

# Signing key for the JSON Web Tokens returned by /login/attempt.
JWT_SECRET = _required('JWT_SECRET')
JWT_EXP_HOURS = int(os.getenv('JWT_EXP_HOURS', '8'))
