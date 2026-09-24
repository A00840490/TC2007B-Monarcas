import database as db
import controllers

from flask import Blueprint, jsonify, make_response, request
from flasgger import Swagger, swag_from
from datetime import datetime

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

        results = db.read_where('Usuarios', {
            'Correo': email,
            'Contraseña': password,
        })


        if not results:
            return make_response(
                jsonify(
                    {
                        'error': 'Credenciales inválidas',
                    }),
                401
            )

        foundUser = results[0]
        print(foundUser)

        return make_response(
            jsonify({
                'userId': foundUser['ID'],
            }),
            200
        )

    except Exception as e:
        print(str(e))
        return make_response(
            jsonify({'error': f'Error en el servidor o base de datos: {str(e)}'}),
            500
        )

@bp_api_routes.route("/recolectoresRuta", methods=['GET'])
@swag_from('docs/recolectores_ruta.yml')
def rutaRecolectoresFunction():
    usuarioId = request.args.get('usuarioId', type=int)
    fecha = request.args.get('fecha')

    if usuarioId is None or not fecha:
        return make_response(
            jsonify({'error': 'Faltan parámetros obligatorios: usuarioId o fecha'}),
            400
        )

    try:
        datetime.strptime(fecha, '%Y-%m-%d')
    except ValueError:
        return make_response(
            jsonify({'error': 'fecha debe tener formato AAAA-MM-DD'}),
            400
        )

    try:
        rows = db.read_ruta_recolecciones(usuarioId, fecha)

        recolecciones = [
            {
                'id': row['ID'],
                'FechaEstimada': row['FechaEstimada'].isoformat(),
                'MontoEsperado': float(row['MontoEsperado']),
                'Orden': row['Orden'],
                'Nombre': row['Nombre'],
                'Direccion': row['Direccion'],
            }
            for row in rows
        ]

        return make_response(jsonify(recolecciones), 200)

    except Exception as e:
        return make_response(
            jsonify({'error': f'Error en el servidor o base de datos: {str(e)}'}),
            500
        )

@bp_api_routes.route("/dashboarddata", methods=['GET'])
@swag_from('docs/dashboard_data.yml')
def dashboardDataFunction():
    try:
        kpis = controller.get_dashboard_kpis()

        return make_response(
            jsonify({
                'dineroDisponible': int(kpis['dineroDisponible']),
                'dineroPrometido': int(kpis['dineroPrometido']),
                'donantesActivos': int(kpis['donantesActivos']),
                'donantesEnRiesgo': int(kpis['donantesEnRiesgo']),
            }),
            200
        )

    except Exception as e:
        return make_response(
            jsonify({'error': f'Error en el servidor o base de datos: {str(e)}'}),
            500
        )

@bp_api_routes.route("/donacionesmeses", methods=['GET'])
@swag_from('docs/donaciones_meses.yml')
def graficaDonacionesFunction():
    try:
        donaciones = controller.get_donaciones_por_mes()
        return make_response(jsonify(donaciones), 200)
    except Exception as e:
        return make_response(
            jsonify({'error': f'Error en el servidor o base de datos: {str(e)}'}),
            500
        )

@bp_api_routes.route("/llamadas", methods=['GET'])
@swag_from('docs/llamadas.yml')
def obtener_llamadas():
    filas = db.read_llamadas_turno()
    llamadas = []
    for fila in filas:
        llamadas.append({
            'id': fila['id'],
            'hora': str(fila['fechaEstimada']),
            'estado': fila['estado'],
            'objetivo': fila['objetivo'] or '',
            'donante': {
                'id': fila['donanteId'],
                'nombre': fila['donanteNombre'],
                'telefono': fila['donanteTelefono'] or '',
                'promesa': str(fila['donanteTotal']) if fila['donanteTotal'] else '',
                'caso': fila['donanteCaso'] or '',
                'riesgo': fila['donanteRiesgo'] or '',
                'ultimoContacto': str(fila['donanteFecha']) if fila['donanteFecha'] else '',
            }
        })
    return make_response(jsonify(llamadas))
