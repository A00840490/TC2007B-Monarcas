from flask import Blueprint, make_response

bp_apidocs = Blueprint('apidocs', __name__)

SWAGGER_UI = 'https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.33.1'
SWAGGER_UI_CSS_SRI = 'sha384-Ov4/wv3j2bmct8cDc5X4ngJZohVPzEmc6uDPH8WeljUxO5vtoykvMEfbu9Vh6RaW'
SWAGGER_UI_JS_SRI = 'sha384-ZPehFMQommnnuaZ4rpxgkgTT2DKFVp4hZC/7pLit+9Lek9T1YGSo23eHFbvNkXkw'

CSP = ("default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; "
       "style-src https://cdn.jsdelivr.net; img-src 'self' data:; connect-src 'self'; "
       "frame-ancestors 'none'; base-uri 'none'; form-action 'self'")

PAGE = f"""<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>API TC2007B - Swagger</title>
<link rel="stylesheet" href="{SWAGGER_UI}/swagger-ui.css" integrity="{SWAGGER_UI_CSS_SRI}" crossorigin="anonymous">
</head>
<body>
<div id="swagger-ui"></div>
<script src="{SWAGGER_UI}/swagger-ui-bundle.js" integrity="{SWAGGER_UI_JS_SRI}" crossorigin="anonymous"></script>
<script src="/apidocs/init.js"></script>
</body>
</html>
"""

INIT_JS = "SwaggerUIBundle({ url: '/apispec_1.json', dom_id: '#swagger-ui', deepLinking: true });\n"


@bp_apidocs.route('/apidocs/')
def apidocs():
    response = make_response(PAGE)
    response.headers['Content-Security-Policy'] = CSP
    return response


@bp_apidocs.route('/apidocs/init.js')
def apidocs_init():
    response = make_response(INIT_JS)
    response.mimetype = 'application/javascript'
    return response
