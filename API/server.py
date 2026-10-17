import config
import database as db
from api_routes import bp_api_routes

import json
import sys
from flask import Flask, jsonify, make_response, request, send_file
from flasgger import Swagger

try:
    db.init_db_pool({
        'DB_HOST': config.DB_HOST,
        'DB_PORT': config.DB_PORT,
        'DB_NAME': config.DB_NAME,
        'DB_USER': config.DB_USER,
        'DB_PASSWORD': config.DB_PASSWORD,
    })

    # Test query so startup fails fast when there is no connection.
    db.read_user_data('Users', 'Admin')

except Exception as e:
    print(f"Cannot connect to mssql server!: {e}")
    sys.exit(1)

app = Flask(__name__)

app.register_blueprint(bp_api_routes, url_prefix='/api')

swagger = Swagger(app, template={
    "info": {
        "title": "API TC2007B",
        "description": "REST API para la materia TC2007B",
        "version": "1.0.0"
    }
})

if __name__ == '__main__':
    ssl_context = None
    if config.SSL_CERT_FILE and config.SSL_KEY_FILE:
        ssl_context = (config.SSL_CERT_FILE, config.SSL_KEY_FILE)
        print("Running SERVER API over HTTPS...")
    else:
        print("Running SERVER API over plain HTTP (SSL_CERT_FILE/SSL_KEY_FILE not set)...")
    app.run(host=config.API_HOST, port=config.API_PORT, debug=config.API_DEBUG,
            ssl_context=ssl_context)
