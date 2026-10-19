from flask import Blueprint

from routes.general import bp_general
from routes.login import bp_login
from routes.recolectores import bp_recolectores
from routes.telefonistas import bp_telefonistas
from routes.admin_panel import bp_admin_panel
from routes.user import bp_user

# Groups the blueprints of each area; server.py registers it under /api.
#   /api/hello, /api/login/...          -> routes/general.py, routes/login.py
#   /api/user                           -> routes/user.py
#   /api/recolectores/route             -> routes/recolectores.py
#   /api/telefonistas/calls             -> routes/telefonistas.py
#   /api/adminPanel/...                 -> routes/admin_panel.py (dashboard, donors, personal)
bp_api_routes = Blueprint('api', __name__)

bp_api_routes.register_blueprint(bp_general)
bp_api_routes.register_blueprint(bp_login)
bp_api_routes.register_blueprint(bp_recolectores)
bp_api_routes.register_blueprint(bp_telefonistas)
bp_api_routes.register_blueprint(bp_user)
bp_api_routes.register_blueprint(bp_admin_panel)
