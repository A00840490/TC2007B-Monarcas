from flask import Blueprint, jsonify, make_response, request
import database as db

bp_api_routes = Blueprint('api', __name__)


@bp_api_routes.route("/hello")
def hello():
    """
      Returns 'Shakira rocks!' as a keepalive
      ---
      responses:
        200:
          description: A successful response is "Shakira rocks!"
    """
    return "Shakira rocks!\n"


@bp_api_routes.route("/loginAttempt", methods=['POST'])
@swag_from('docs/login_attempt.yml')
def loginAttemptFunction():

    data = request.get_json(silent=True) or {}

    email = data.get('caritasEMail')
    password = data.get('password')

    if not email or not password:
        return make_response(
            jsonify(
                {
                    'error': 'Faltan parámetros obligatorios: caritasEMail o password',
                }),
            400
        )

    try:

        results = db.read_where('users', {
            'Correo': email,
            'Contraseña': password,
        })

        print(f'email: {email}, password: {password}')
        print(results)

        if not results:
            return make_response(
                jsonify(
                    {
                        'error': 'Credenciales inválidas',
                    }),
                401
            )

        foundUser = results[0]

        return make_response(
            jsonify({
                'idUser': foundUser.id,
            }),
            200
        )

    except Exception as e:
        return make_response(
            jsonify({'error': f'Error en el servidor o base de datos: {str(e)}'}),
            500
        )


@bp_api_routes.route("/crud/create", methods=['POST'])
def crud_create():
    """
    Crear un nuevo usuario
    ---
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            username:
              type: string
              example: "juan123"
            password:
              type: string
              example: "pass1234"
    responses:
      200:
        description: Retorna el ID del usuario insertado
    """
    d = request.json
    idUser = db.sql_insert_row_into('users', d)
    return make_response(jsonify(idUser))


@bp_api_routes.route("/crud/read", methods=['GET'])
def crud_read():
    """
    Consultar información de un usuario
    ---
    parameters:
      - name: username
        in: query
        type: string
        required: true
        description: Username para filtrar en la base de datos
    responses:
      200:
        description: Registro del usuario
    """
    username = request.args.get('username', None)
    d_user = db.sql_read_where('users', {'username': username})
    return make_response(jsonify(d_user))


@bp_api_routes.route("/crud/update", methods=['PUT'])
def crud_update():
    """
    Actualizar contraseña de un usuario
    ---
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            username:
              type: string
              example: "juan123"
            password:
              type: string
              example: "nueva_contrasena123"
    responses:
      200:
        description: Confirmación del cambio
    """
    d = request.json
    d_field = {'password': d['password']}
    d_where = {'username': d['username']}
    db.sql_update_where('users', d_field, d_where)
    return make_response(jsonify('ok'))


@bp_api_routes.route("/crud/delete", methods=['DELETE'])
def crud_delete():
    """
    Eliminar un usuario por username
    ---
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            username:
              type: string
              example: "juan123"
    responses:
      200:
        description: Confirmación de eliminación
    """
    d = request.json
    d_where = {'username': d['username']}
    db.sql_delete_where('users', d_where)
    return make_response(jsonify('ok'))
