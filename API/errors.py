from flask import current_app, jsonify, make_response


def server_error(error):
    current_app.logger.error('Server or database error: %s', error, exc_info=error)
    return make_response(jsonify({'error': 'Server or database error'}), 500)
