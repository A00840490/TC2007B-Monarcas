cnx = None
mssql_params = {}


def mssql_connect(sql_creds):
    import pymssql
    return pymssql.connect(
        server=sql_creds['DB_HOST'],
        user=sql_creds['DB_USER'],
        password=sql_creds['DB_PASSWORD'],
        database=sql_creds['DB_NAME']
    )


def _execute_with_retry(query, params=None, commit=False, fetch=True):
    import pymssql
    global cnx, mssql_params

    def _run():
        cursor = cnx.cursor(as_dict=True)
        result = cursor.execute(
            query, params) if params else cursor.execute(query)

        output = None
        if fetch:
            output = cursor.fetchall()
        elif commit:
            cnx.commit()
            output = cursor.lastrowid if cursor.lastrowid else result

        cursor.close()
        return output

    try:
        return _run()
    except (pymssql._pymssql.InterfaceError, AttributeError):
        print("reconnecting...")
        cnx = mssql_connect(mssql_params)
        return _run()


def read_user_data(table_name, name):
    read = f"SELECT * FROM {table_name} WHERE Nombre = %s"
    try:
        return _execute_with_retry(read, params=(name,), fetch=True)
    except Exception as e:
        raise TypeError(f"read_user_data: {e}")


def read_all(table_name):
    read = f"SELECT * FROM {table_name}"
    try:
        return _execute_with_retry(read, fetch=True)
    except Exception as e:
        raise TypeError(f"read_all: {e}")


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
        return _execute_with_retry(read, params=tuple(params) if params else None, fetch=True)
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
        return _execute_with_retry(insert, params=tuple(data), commit=True, fetch=False)
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
        return _execute_with_retry(update, params=tuple(params), commit=True, fetch=False)
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
        return _execute_with_retry(delete, params=tuple(params), commit=True, fetch=False)
    except Exception as e:
        raise TypeError(f"sql_delete_where: {e}")
