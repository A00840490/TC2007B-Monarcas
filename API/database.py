from contextlib import contextmanager
from dbutils.pooled_db import PooledDB
import pymssql

_pool = None


def init_db_pool(sql_creds, min_connections=2, max_connections=10):
    global _pool
    _pool = PooledDB(
        creator=pymssql,
        mincached=min_connections,
        maxconnections=max_connections,
        blocking=True,
        server=sql_creds['DB_HOST'],
        user=sql_creds['DB_USER'],
        password=sql_creds['DB_PASSWORD'],
        database=sql_creds['DB_NAME'],
        tds_version="7.4",
    )


@contextmanager
def get_db_connection():
    if _pool is None:
        raise RuntimeError("El pool de base de datos no esta inicializado. Llama a init_db_pool primero.")

    conn = _pool.connection()
    try:
        yield conn
    finally:
        conn.close()


def read_user_data(table_name, name):
    read = f"SELECT * FROM {table_name} WHERE Nombre = %s"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(read, (name,))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_user_data: {e}")


def read_all(table_name):
    read = f"SELECT * FROM {table_name}"
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(read)
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_all: {e}")


def read_ruta_recolecciones(usuario_id, fecha):
    query = """
        SELECT r.ID, r.FechaEstimada, r.MontoEsperado, r.Orden,
               d.Nombre, d.Direccion
        FROM Recoleccion r
        INNER JOIN Donante d ON d.ID = r.DonanteID
        WHERE r.UsuarioID = %s
          AND CAST(r.FechaEstimada AS DATE) = %s
        ORDER BY CASE WHEN r.Orden IS NULL THEN 1 ELSE 0 END,
                 r.Orden,
                 r.FechaEstimada
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query, (usuario_id, fecha))
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_ruta_recolecciones: {e}")


def read_where(table_name, d_where):
    conditions = []
    params = []

    for k, v in d_where.items():
        if v is None:
            conditions.append(f"{k} IS NULL")
        else:
            conditions.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    where_clause = " AND ".join(conditions)
    read = f"SELECT * FROM {table_name}"
    if where_clause:
        read += f" WHERE ({where_clause})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            if params:
                cursor.execute(read, tuple(params))
            else:
                cursor.execute(read)
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_read_where: {e}")


def insert_row_into(table_name, d):
    keys = []
    values_placeholders = []
    data = []

    for k, v in d.items():
        keys.append(k)
        values_placeholders.append("%s")
        data.append(int(v) if isinstance(v, bool) else v)

    keys_str = ", ".join(keys)
    values_str = ", ".join(values_placeholders)
    insert = f"INSERT INTO {table_name} ({keys_str}) VALUES ({values_str})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            result = cursor.execute(insert, tuple(data))
            cnx.commit()
            output = cursor.lastrowid if cursor.lastrowid else result
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_insert_row_into: {e}")


def update_where(table_name, d_field, d_where):
    field_updates = []
    params = []

    for k, v in d_field.items():
        if v is None:
            field_updates.append(f"{k} = NULL")
        else:
            field_updates.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    where_conditions = []
    for k, v in d_where.items():
        if v is None:
            where_conditions.append(f"{k} IS NULL")
        else:
            where_conditions.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    update = f"UPDATE {table_name} SET {', '.join(field_updates)} WHERE ({' AND '.join(where_conditions)})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            result = cursor.execute(update, tuple(params))
            cnx.commit()
            output = cursor.lastrowid if cursor.lastrowid else result
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_update_where: {e}")


def delete_where(table_name, d_where):
    where_conditions = []
    params = []

    for k, v in d_where.items():
        if v is None:
            where_conditions.append(f"{k} IS NULL")
        else:
            where_conditions.append(f"{k} = %s")
            params.append(int(v) if isinstance(v, bool) else v)

    delete = f"DELETE FROM {table_name} WHERE ({' AND '.join(where_conditions)})"

    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            result = cursor.execute(delete, tuple(params))
            cnx.commit()
            output = cursor.lastrowid if cursor.lastrowid else result
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"sql_delete_where: {e}")


def read_llamadas_turno():
    query = """
    SELECT
        L.ID AS id,
        L.FechaEstimada AS fechaEstimada,
        L.EstadoLlamada AS estado,
        L.Notas AS objetivo,
        D.ID AS donanteId,
        D.Nombre AS donanteNombre,
        D.Telefono AS donanteTelefono,
        D.EstatusRiesgo AS donanteRiesgo,
        Dn.CampañaDestino AS donanteCaso,
        Dn.MontoTotal AS donanteTotal,
        Dn.Fecha AS donanteFecha
    FROM Llamada L
    JOIN Donante D ON L.DonanteID = D.ID
    LEFT JOIN Donacion Dn ON Dn.ID = (
        SELECT TOP 1 ID FROM Donacion
        WHERE DonanteID = D.ID
        ORDER BY Fecha DESC
    )
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query)
            output = cursor.fetchall()
            cursor.close()
            return output
    except Exception as e:
        raise TypeError(f"read_llamadas_turno: {e}")


def get_kpis():
    query = """
    SELECT 
        COALESCE((SELECT SUM(MontoEsperado) FROM Recoleccion WHERE Estatus = 'COBRADA'), 0) AS dineroDisponible,
        COALESCE((SELECT SUM(MontoEsperado) FROM Recoleccion WHERE Estatus = 'PENDIENTE'), 0) AS dineroPrometido,
        (SELECT COUNT(*) FROM Donante) AS donantesActivos,
        (SELECT COUNT(*) FROM Donante WHERE EstatusRiesgo = 'Alto') AS donantesEnRiesgo
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query)
            results = cursor.fetchall()
            cursor.close()
            if results:
                return results[0]
            return {}
    except Exception as e:
        raise TypeError(f"get_kpis error: {e}")


def get_donaciones_meses():
    query = """
    SELECT 
        MONTH(FechaEstimada) AS id,
        DATENAME(month, FechaEstimada) AS mes,
        COALESCE(SUM(MontoEsperado), 0) AS monto
    FROM Recoleccion
    WHERE Estatus = 'COBRADA'
    GROUP BY MONTH(FechaEstimada), DATENAME(month, FechaEstimada)
    ORDER BY id ASC
    """
    try:
        with get_db_connection() as cnx:
            cursor = cnx.cursor(as_dict=True)
            cursor.execute(query)
            results = cursor.fetchall()
            print(results)
            cursor.close()
            return results if results else []
    except Exception as e:
        raise TypeError(f"get_donaciones_meses error: {e}")