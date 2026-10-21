from flask import Blueprint
from flasgger import swag_from

from routes import doc

bp_general = Blueprint('general', __name__)


@bp_general.route("/hello")
@swag_from(doc('hello.yml'))
def hello():
    return "Shakira rocks!\n"
