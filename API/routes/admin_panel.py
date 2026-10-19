import auth
import controllers

from flask import Blueprint, jsonify, make_response, request
from flasgger import swag_from

from routes import doc

# Everything the PanelAdmin app consumes lives under /api/adminPanel/...
bp_admin_panel = Blueprint('adminPanel', __name__, url_prefix='/adminPanel')


@bp_admin_panel.route("/dashboard", methods=['GET'])
@swag_from(doc('dashboard.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def dashboard():
    try:
        kpis = controllers.get_dashboard_kpis()
        return make_response(jsonify(kpis), 200)

    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_admin_panel.route("/monthlyDonations", methods=['GET'])
@swag_from(doc('monthly_donations.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def monthly_donations():
    try:
        donations = controllers.get_monthly_donations()
        return make_response(jsonify(donations), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


def _window_months():
    """`months` query parameter (3, 6 or 12; 6 if missing). None if invalid."""
    months = request.args.get('months', default=controllers.ACTIVE_DONOR_MONTHS, type=int)
    return months if months in controllers.ALLOWED_WINDOW_MONTHS else None


@bp_admin_panel.route("/donors", methods=['GET'])
@swag_from(doc('donors.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def donors():
    months = _window_months()
    if months is None:
        return make_response(jsonify({'error': 'months must be 3, 6 or 12'}), 400)

    try:
        return make_response(jsonify(controllers.get_donor_list(months)), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_admin_panel.route("/agenda", methods=['GET'])
@swag_from(doc('agenda.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def agenda():
    days = request.args.get('days', default=controllers.AGENDA_DAYS, type=int)
    if days is None or not 1 <= days <= controllers.AGENDA_MAX_DAYS:
        return make_response(
            jsonify({'error': f'days must be between 1 and {controllers.AGENDA_MAX_DAYS}'}), 400)

    try:
        return make_response(jsonify(controllers.get_agenda(days)), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_admin_panel.route("/followUps", methods=['GET'])
@swag_from(doc('follow_ups.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def follow_ups():
    try:
        return make_response(jsonify(controllers.get_follow_ups()), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_admin_panel.route("/donorFilters", methods=['GET'])
@swag_from(doc('donor_filters.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def donor_filters():
    try:
        return make_response(jsonify(controllers.get_donor_filters()), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_admin_panel.route("/donors/<int:donor_id>", methods=['GET'])
@swag_from(doc('donor_detail.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def donor_detail(donor_id):
    months = _window_months()
    if months is None:
        return make_response(jsonify({'error': 'months must be 3, 6 or 12'}), 400)

    try:
        detail = controllers.get_donor_detail(donor_id, months)
        if detail is None:
            return make_response(jsonify({'error': 'Donor not found'}), 404)
        return make_response(jsonify(detail), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


def _created(create, body):
    """Runs a create controller: 201 with the new row, 400 if the data is invalid."""
    if not isinstance(body, dict):
        body = {}
    try:
        return make_response(jsonify(create(body)), 201)
    except controllers.ValidationError as e:
        return make_response(jsonify({'error': str(e)}), 400)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_admin_panel.route("/donors", methods=['POST'])
@swag_from(doc('donor_create.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def create_donor():
    return _created(controllers.create_donor, request.get_json(silent=True))


@bp_admin_panel.route("/staff", methods=['GET'])
@swag_from(doc('staff.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def staff():
    try:
        return make_response(jsonify(controllers.get_staff()), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )


@bp_admin_panel.route("/calls", methods=['POST'])
@swag_from(doc('call_create.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def schedule_call():
    return _created(controllers.schedule_call, request.get_json(silent=True))


@bp_admin_panel.route("/collections", methods=['POST'])
@swag_from(doc('collection_create.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def schedule_collection():
    return _created(controllers.schedule_collection, request.get_json(silent=True))


@bp_admin_panel.route("/personal", methods=['GET'])
@swag_from(doc('personal.yml'))
@auth.require_role(auth.ROLE_ADMIN)
def personal():
    months = _window_months()
    if months is None:
        return make_response(jsonify({'error': 'months must be 3, 6 or 12'}), 400)

    try:
        return make_response(jsonify(controllers.get_personal(months)), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Server or database error: {str(e)}'}),
            500
        )
