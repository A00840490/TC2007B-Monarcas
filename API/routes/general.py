from flask import Blueprint

bp_general = Blueprint('general', __name__)


@bp_general.route("/hello")
def hello():
    """
      Returns 'Shakira rocks!' as a keepalive
      ---
      responses:
        200:
          description: A successful response is "Shakira rocks!"
    """
    return "Shakira rocks!\n"
