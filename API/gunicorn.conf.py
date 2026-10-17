# Gunicorn settings: gunicorn -c gunicorn.conf.py server:app
# Reads the same API/.env as server.py, so HTTPS turns on when
# SSL_CERT_FILE and SSL_KEY_FILE are set.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import config as api_config  # "config" is a reserved Gunicorn setting name

bind = f"{api_config.API_HOST}:{api_config.API_PORT}"

if api_config.SSL_CERT_FILE and api_config.SSL_KEY_FILE:
    certfile = api_config.SSL_CERT_FILE
    keyfile = api_config.SSL_KEY_FILE
