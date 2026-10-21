import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import config as api_config

bind = f"{api_config.API_HOST}:{api_config.API_PORT}"
workers = 3
timeout = 60

if api_config.SSL_CERT_FILE and api_config.SSL_KEY_FILE:
    certfile = api_config.SSL_CERT_FILE
    keyfile = api_config.SSL_KEY_FILE
