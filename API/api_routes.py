from flask import Blueprint

from routes.general import bp_general
from routes.login import bp_login
from routes.recolectores import bp_recolectores
from routes.telefonistas import bp_telefonistas
from routes.admin_panel import bp_admin_panel
from routes.user import bp_user

bp_api_routes = Blueprint('api', __name__)

bp_api_routes.register_blueprint(bp_general)
bp_api_routes.register_blueprint(bp_login)
bp_api_routes.register_blueprint(bp_recolectores)
bp_api_routes.register_blueprint(bp_telefonistas)
bp_api_routes.register_blueprint(bp_user)
bp_api_routes.register_blueprint(bp_admin_panel)
