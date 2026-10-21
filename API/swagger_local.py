import json
import os
import sys

for _name in ('DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'JWT_SECRET', 'PASSWORD_PEPPER'):
    os.environ.setdefault(_name, 'swagger-local-only-not-a-real-value')

from flask import Flask
from flasgger import Swagger

from api_routes import bp_api_routes
from apidocs import SWAGGER_UI, SWAGGER_UI_CSS_SRI, SWAGGER_UI_JS_SRI, bp_apidocs

TEMPLATE = {
    "info": {
        "title": "API TC2007B",
        "description": "REST API para la materia TC2007B (vista local de la documentación, sin base de datos)",
        "version": "1.0.0"
    }
}

HTML = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>API TC2007B - Swagger</title>
<link rel="stylesheet" href="__SWAGGER_UI__/swagger-ui.css" integrity="__CSS_SRI__" crossorigin="anonymous">
</head>
<body>
<div id="swagger-ui"></div>
<script src="__SWAGGER_UI__/swagger-ui-bundle.js" integrity="__JS_SRI__" crossorigin="anonymous"></script>
<script>
SwaggerUIBundle({ spec: __SPEC__, dom_id: '#swagger-ui', deepLinking: true });
</script>
</body>
</html>
"""

app = Flask(__name__)
app.register_blueprint(bp_api_routes, url_prefix='/api')
app.register_blueprint(bp_apidocs)
swagger = Swagger(app, config={'swagger_ui': False}, merge=True, template=TEMPLATE)


def export_html(path):
    with app.test_request_context():
        spec = swagger.get_apispecs('apispec_1')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(HTML.replace('__SWAGGER_UI__', SWAGGER_UI)
                .replace('__CSS_SRI__', SWAGGER_UI_CSS_SRI)
                .replace('__JS_SRI__', SWAGGER_UI_JS_SRI)
                .replace('__SPEC__', json.dumps(spec, ensure_ascii=False, indent=1)))
    print(f"Swagger HTML written to {path}")


if __name__ == '__main__':
    if '--export' in sys.argv:
        export_html(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'docs', 'swagger.html'))
    else:
        port = int(os.getenv('SWAGGER_PORT', '5000'))
        print(f"Swagger UI: http://127.0.0.1:{port}/apidocs/")
        app.run(host='127.0.0.1', port=port)
