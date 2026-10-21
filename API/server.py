import config
import database as db
from api_routes import bp_api_routes
from apidocs import bp_apidocs
from limiter import limiter

import sys
from flask import Flask, jsonify, make_response, request
from flasgger import Swagger
from werkzeug.exceptions import HTTPException

from errors import server_error

try:
    db.init_db_pool({
        'DB_HOST': config.DB_HOST,
        'DB_PORT': config.DB_PORT,
        'DB_NAME': config.DB_NAME,
        'DB_USER': config.DB_USER,
        'DB_PASSWORD': config.DB_PASSWORD,
    })

    db.check_connection()

except Exception as e:
    print(f"Cannot connect to mssql server!: {e}")
    sys.exit(1)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = config.MAX_REQUEST_BYTES

limiter.init_app(app)

app.register_blueprint(bp_api_routes, url_prefix='/api')
app.register_blueprint(bp_apidocs)


@app.errorhandler(429)
def too_many_requests(e):
    return make_response(jsonify({'error': 'Too many attempts, try again later'}), 429)


@app.errorhandler(HTTPException)
def http_error(e):
    return make_response(jsonify({'error': e.name}), e.code)


@app.errorhandler(Exception)
def unhandled_error(e):
    return server_error(e)


@app.after_request
def security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['Referrer-Policy'] = 'no-referrer'
    response.headers.setdefault(
        'Content-Security-Policy',
        "default-src 'none'; frame-ancestors 'none'; form-action 'none'; base-uri 'none'")
    response.headers.setdefault('Cache-Control', 'no-store, no-cache, must-revalidate')
    if request.is_secure:
        response.headers['Strict-Transport-Security'] = 'max-age=31536000'
    return response

swagger = Swagger(app, config={'swagger_ui': False}, merge=True, template={
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
