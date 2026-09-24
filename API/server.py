import database as db
from api_routes import bp_api_routes

from flask import Flask, jsonify, make_response, request, send_file
import json
import sys
from flasgger import Swagger

API_PORT = 10206
try:
    db.cnx = db.mssql_connect({
        'DB_HOST': '100.80.80.7',
        'DB_NAME': 'alumno06',
        'DB_USER': 'SA',
        'DB_PASSWORD': 'Shakira123.'
    })

    result = db.read_user_data('Usuario', 'Admin')


except Exception as e:
    print(f"Cannot connect to mssql server!: {e}")
    sys.exit()

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
    print("Running SERVER API...")
    app.run(host='0.0.0.0', port=API_PORT, debug=True)
