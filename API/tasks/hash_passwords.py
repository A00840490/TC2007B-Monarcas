import getpass
import re

import pymssql

import config
import passwords

PLAIN_SHA256 = re.compile(r'[0-9a-fA-F]{64}')


def main():
    user = input('Administrator SQL login: ').strip()
    password = getpass.getpass(f'Password for {user}: ')

    cnx = pymssql.connect(server=config.DB_HOST, port=config.DB_PORT, user=user,
                          password=password, database=config.DB_NAME, tds_version='7.4')
    try:
        cursor = cnx.cursor(as_dict=True)
        cursor.execute("SELECT ID, PasswordHash FROM dbo.Users")
        pending = [row for row in cursor.fetchall()
                   if PLAIN_SHA256.fullmatch((row['PasswordHash'] or '').strip())]

        for row in pending:
            cursor.execute("UPDATE dbo.Users SET PasswordHash = %s WHERE ID = %s",
                           (passwords.hash_password(row['PasswordHash'].strip()), row['ID']))
        cnx.commit()
        print(f"{len(pending)} password hashes converted to salted PBKDF2 with pepper.")
    finally:
        cnx.close()


if __name__ == '__main__':
    main()
