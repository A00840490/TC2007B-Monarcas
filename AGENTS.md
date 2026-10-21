# AGENTS.md — project context for AI coding assistants

Read this before changing anything in this repository. It explains what the system
does, how the pieces fit together, and the rules the team follows. Deeper references:
[`docs/database.md`](docs/database.md) (full data model and business rules),
[`API/sql/README.md`](API/sql/README.md) (SQL scripts and database accounts),
[`docs/https.md`](docs/https.md) (certificates) and
[`Shared/CaritasAuth/README.md`](Shared/CaritasAuth/README.md) (shared iOS login).
If this file and the code disagree, the code wins; update this file in the same commit.

## 1. What this is

Course project (TC2007B, Tec de Monterrey) for **Cáritas**: a system to manage donors
and the staff who collect donations.

- **Donors** (`Donor`) are the clients. They never log in.
- **Staff** (`Users`) log in to an iOS app. Each user has exactly one role:
  - **Admin**: sees KPIs, manages donors, schedules calls and collections for the staff.
  - **Telefonista**: phones donors (`PhoneCall`) and records the result.
  - **Recolector**: visits donors to collect cash (`Collection`) following a daily route.

```
iOS apps (SwiftUI)  ──HTTPS + JWT──▶  Flask API (API/)  ──pymssql──▶  SQL Server
  PanelAdmin (Admin)                   server.py / gunicorn            login: caritas_api
  TelefonistaApp                       tasks/daily_recurring_donations  login: caritas_tasks
  RecolectoresApp                      (cron, once a day)
  Shared/CaritasAuth (login package)
```

Production host: `monarcas.tc2007b.tec.mx` (`10.14.255.44`), port `10206`, HTTPS.

## 2. Repository layout

| Path | What it is |
|---|---|
| `API/server.py` | Flask app. Opens the DB pool, registers every route under `/api`, the spec (flasgger) at `/apispec_1.json` and the Swagger UI at `/apidocs/`. |
| `API/apidocs.py` | Serves `/apidocs/`: Swagger UI 5 from jsDelivr with SRI hashes and a strict CSP. flasgger's own UI (old bundled jQuery and DOMPurify) is turned off. To upgrade it, change the version and both `sha384-` hashes together. |
| `API/config.py` | Reads `API/.env`. Fails at startup if a required variable is missing. |
| `API/auth.py` | JWT creation/verification and the `@require_role(...)` decorator. |
| `API/errors.py` | `server_error(e)`: logs the exception and returns a generic `500 {'error': 'Server or database error'}`. Never put `str(e)` in a response. |
| `API/api_routes.py` | Groups the blueprints in `API/routes/`. |
| `API/routes/*.py` | One blueprint per area: `login`, `user`, `general`, `admin_panel` (`/adminPanel/...`), `telefonistas`, `recolectores`. |
| `API/controllers.py` | Business logic and validation for the admin panel. |
| `API/database.py` | Connection pool and admin/auth queries. `telefonistas_db.py` and `recolectores_db.py` hold each module's queries. |
| `API/recurring_donations.py`, `API/tasks/daily_recurring_donations.py` | Monthly pledge logic and the daily cron task. |
| `API/docs/*.yml` | Swagger spec of each endpoint (`@swag_from(doc('x.yml'))`). |
| `API/swagger_local.py`, `API/docs/swagger.html` | Swagger UI without a database: `python swagger_local.py` serves it at `http://127.0.0.1:5000/apidocs/`; `--export` regenerates the standalone `docs/swagger.html` (rerun it after editing any `docs/*.yml`). |
| `API/passwords.py`, `API/tasks/hash_passwords.py` | Salted + peppered password hashes, and the one-off script that converts plain SHA-256 hashes. |
| `API/sql/01..06_*.sql` | Schema, seed data, demo data, least-privilege accounts, migrations. See `API/sql/README.md`. |
| `PanelAdmin/` | Admin iOS app (MVVM: `Models/`, `ViewModels/`, `Views/`, `Services/`). Uses CaritasAuth and the JWT. |
| `TelefonistaApp/`, `RecolectoresApp/` | Telefonista and Recolector iOS apps (projects `PantallaTelemarketinas` and `Ruta_del_dia`). Both log in with CaritasAuth and call the endpoints in section 7 with the token. |
| `LoginApp/` | Small sample app that uses CaritasAuth. |
| `Shared/CaritasAuth/` | Swift package: login screen, Keychain session, `AuthGate`. Every app should use it. |
| `docs/` | `database.md`, `database.dbml` + diagram, `https.md`. |

## 3. Team rules (mandatory)

1. **Language.** All code and implementation is in **English**: variable, function, file,
   route, table and column names, comments and commit messages.
   - Exception: **`Telefonista`** and **`Recolector`** stay in Spanish everywhere, including
     derived names (`telefonistaId`, `recolectorId`, `TelefonistaID`, `/api/telefonistas/...`,
     `/api/recolectores/...`, `ROLE_RECOLECTOR = 'Recolector'`).
   - **Text shown to the end user is in Spanish** (alerts, labels, buttons, messages on screen,
     notes the daily task writes for staff). API error messages in JSON are in English.
2. **Never commit secrets.** `API/.env`, real passwords, `JWT_SECRET`, private keys and
   certificates (`*.key`, `*.cer`, `*.pem`, `API/certs/`) are in `.gitignore` and must stay out of git.
   Use `API/.env.example` with placeholder values. `04_app_users.sql` keeps the
   `REPLACE_WITH_..._PASSWORD` placeholders in git; real passwords are typed only when running it.
3. **The user comes from the token, never from the request.** Protected endpoints read
   `g.user['ID']`; they never accept `userId`, `usuarioId`, `telefonistaId`, etc. as input to
   decide whose data to return.
4. **Every new endpoint** gets `@auth.require_role(...)` (unless it is login), a Swagger file in
   `API/docs/`, parameterized SQL (`%s`, never f-strings with user input) and, if it touches a
   new table/column or a new kind of statement, a `GRANT` in `API/sql/04_app_users.sql`.
5. **Schema changes** go in `01_create_database.sql` (fresh databases) **and** in an idempotent
   migration script (`IF COL_LENGTH(...) IS NULL ...`, like `05_...sql`) for existing databases;
   then update `docs/database.md` and `docs/database.dbml`.
6. Keep the existing style: small blueprints, `make_response(jsonify(...), status)`,
   `{'error': '...'}` bodies, camelCase JSON keys, PascalCase SQL columns.
   Validate the type of every JSON field before using it (`isinstance`), reject a body that is
   not a JSON object with 400, and return `server_error(e)` from every `except Exception`.
7. **No comments or docstrings in the API or PanelAdmin code.** Document each endpoint in its
   `API/docs/*.yml` and everything else in `docs/` or `API/sql/README.md`. The Python can stay as
   complete as it needs to be; the Swift must stay simple enough for a student to explain (plain
   MVVM, no generic helpers or dependency injection the screen does not need).

## 4. Database (SQL Server)

Full detail, with every column and the monthly pledge flow: [`docs/database.md`](docs/database.md).

| Table | Purpose |
|---|---|
| `Role` | `Admin`, `Telefonista`, `Recolector` (CHECK constraint). |
| `Users` | Staff. `Email` (unique, login), `PasswordHash` (salted PBKDF2 + pepper, see section 5), `RoleID` → `Role`. One role per user. |
| `Donor` | Donors: `Name`, `Phone`, `OfficePhone`, `Email`, `Nickname`, `Address`, `RiskStatus` (`LOW`/`MEDIUM`/`HIGH`). |
| `DonorNote` | Free-text log a telefonista writes about a donor (`DonorID`, `UserID`, `Note`, `CreatedAt`). |
| `PhoneCall` | Scheduled call. `UserID` = telefonista. `Type`: `REGULAR`, `CONFIRMATION`, `TRANSFER_COLLECTION`. `Status`: `PENDING`, `NO_ANSWER`, `DECLINED`, `ACCEPTED`, `RESCHEDULED`. `Notes` = goal set by whoever scheduled it; `ResultNotes` + `CalledAt` = what the telefonista recorded. |
| `Collection` | Scheduled visit. `UserID` = recolector. `Status`: `PENDING`, `SUCCESSFUL`, `FAILED` (`Notes` = reason). `ExpectedAmount`, `RouteOrder`, optional `CallID`. |
| `RecurringDonation` | Monthly pledge (a promise, not money): `Amount`, `PaymentMethod` (`CASH`/`TRANSFER`), `NextInstallmentDate`, `Status` (`ACTIVE`/`PAUSED`/`CANCELLED`/`FINISHED`), assigned `TelefonistaID` and `RecolectorID`. |
| `Donation` | Money actually received. **Past only** (CHECK: `DonationDate` not in the future). `CASH`/`TRANSFER`, optional links to `CollectionID`, `CallID`, `RecurringDonationID`. |

Key business rules:

1. `Donation` is history; what is still to be collected lives in `Collection`, future promises in `RecurringDonation`.
2. `PhoneCall.UserID` must be a Telefonista and `Collection.UserID` a Recolector. The FK cannot enforce it; the API validates it.
3. Telefonista call result: `ACCEPTED` creates a `Collection` (for the donor's recolector); `RESCHEDULED` creates a new `PENDING` `PhoneCall`.
4. Recolector result: `SUCCESSFUL` (needs `receivedAmount`) creates a cash `Donation`; `FAILED` needs the reason in `notes` and can later be rescheduled to a future date.
5. Daily task (cron, 6:00): creates the `CONFIRMATION` call the day before each installment and applies the default action to unresolved installments (cash → send the recolector anyway; transfer → `TRANSFER_COLLECTION` call). Safe to run more than once a day.

SQL scripts, in order (DBeaver: **Execute SQL Script / Alt+X**; or `sqlcmd ... -f 65001 -i file`):
`01_create_database.sql` (drops everything!) → `02_seed_data.sql` → optional `03_demo_data.sql`
(generated by `generate_demo_data.py`, don't edit by hand) → `04_app_users.sql`.
`05_...sql` and `06_...sql` only migrate an old database; after seeding, run `python3 -m tasks.hash_passwords`. Test users have password `Caritas2026`
(e.g. `admin@caritas.org.mx`, `telefonista@caritas.org.mx`, `recolector@caritas.org.mx`).

## 5. How authentication works and why (JWT)

Flow:

1. The app hashes the password with SHA-256 (`Shared/CaritasAuth/.../Hash.swift`) and sends
   `POST /api/login/attempt` with `{email, password: <hash>, role}`.
2. The API looks up `Users` by email and checks the hash with `passwords.verify_password`. If the app sent `role` and the user has another
   one → **403** (so a recolector cannot log in to the admin panel).
3. The API returns `{token, userId, role}`. The token is an **HS256 JWT** signed with
   `JWT_SECRET`, with `sub` = user ID, `role`, `iat`, `exp` (`JWT_EXP_HOURS`, default 8).
4. The app stores the token in the **Keychain** (`SessionStore`) and sends it on every request
   as `Authorization: Bearer <token>`. On launch, `AuthGate` checks a saved session with
   `POST /api/login/verify`.
5. Every protected endpoint uses `@auth.require_role(ROLE_X)`, which: verifies signature and
   expiration (401), checks the user still exists (401), checks the role in the token still
   matches the role **in the database** (401, "log in again"), checks the role is allowed (403),
   and puts the user in `g.user`.

Why a JWT instead of sending `userId`:

- Before, endpoints like `/recolectoresRuta?usuarioId=5` trusted whatever ID the client sent:
  anyone could change the number and read another person's route or calls (IDOR). Now the
  identity comes from a token the server signed and nobody can forge without `JWT_SECRET`.
- It is stateless: no session table; the server only needs the secret to verify it.
- `exp` limits how long a stolen token is useful; re-checking the role against the database
  makes a role change or a deleted user take effect immediately.
- Ownership is still checked per row: a telefonista only sees donors of their own calls, a
  recolector only touches their own collections (403 otherwise).

Rules for code: never decode the token on the client to make security decisions, never log or
commit it, never put it in a URL; rotating `JWT_SECRET` logs everyone out.

The login also rejects a body that is not a JSON object, an email over 254 characters, a
`password` that is not 64 hex characters and a `role` other than the three roles (400). Tokens
must carry `sub`, `role`, `iat` and `exp`, and `JWT_SECRET` must have at least 32 characters or
the API refuses to start.

Password storage: the device sends a SHA-256, and the API stores PBKDF2-SHA256 (600,000 iterations,
random salt per user) of that value mixed with `PASSWORD_PEPPER` from `.env` (never in the database).
So a leaked `Users` table can neither be used to log in nor be cracked without the pepper. After
`02_seed_data.sql`/`03_demo_data.sql` (or `06_password_salt_pepper.sql` on an old database) run
`python3 -m tasks.hash_passwords` with an admin SQL login; `caritas_api` cannot update `Users`.
Changing `PASSWORD_PEPPER` invalidates every password.

## 6. Database accounts with least privilege (why not `sa`)

The API never connects as `sa`. `API/sql/04_app_users.sql` creates two SQL logins, each in a role
with only the permissions its code needs:

| Login (role) | Used by (`.env`) | Can do |
|---|---|---|
| `caritas_api` (`app_api`) | API, `DB_USER` | `SELECT` on the 8 tables; `INSERT` on `Donor`, `PhoneCall`, `Collection`, `DonorNote`, `Donation`; `UPDATE` only of `PhoneCall(Status, ResultNotes, CalledAt)` and `Collection(Status, Notes, ScheduledDate, RouteOrder)`. |
| `caritas_tasks` (`app_tasks`) | daily task, `TASKS_DB_USER` | `SELECT` on `RecurringDonation`, `PhoneCall`; `INSERT` on `PhoneCall`, `Collection`; `UPDATE` only of `RecurringDonation(NextInstallmentDate, Status)`. |

Why:

- If the API or its `.env` is compromised (a bug, an SQL injection, a leaked file), the attacker
  only gets what the API could already do: no `DELETE`, no `DROP`/`ALTER`, no other databases,
  no server settings, no creating logins. With `sa` they would own the whole SQL Server.
- Column-level `UPDATE` grants mean that even a bug cannot, for example, change a user's
  `PasswordHash` or `RoleID` or a donation amount.
- Two accounts so the cron task and the API can be rotated/revoked separately.

Consequence for developers: **if you add a query that touches a new table, a new column in an
`UPDATE`, or a new statement type, it will fail with "permission denied" in production until you
add the `GRANT` to `04_app_users.sql` and re-run it.** The script is idempotent and must be re-run
after `01_create_database.sql` (dropping tables drops their grants). Also: use a personal sysadmin
login in DBeaver, disable `sa`, and never expose port 1433 to the internet.

## 7. API endpoints (all under `/api`)

| Endpoint | Role | Notes |
|---|---|---|
| `GET /hello` | — | Keepalive. |
| `POST /login/attempt` | — | `{email, password (SHA-256 hex), role?}` → `{token, userId, role}`. Max 5 attempts per minute per IP (429, Flask-Limiter in `API/limiter.py`). |
| `POST /login/verify` | — | `{token, role}` → `{valid, userId, role}`. |
| `POST /user` | any | Profile (`name`, `email`, `role`) of the token's user. |
| `GET /adminPanel/dashboard`, `/monthlyDonations` | Admin | KPIs and monthly chart. |
| `GET /adminPanel/donors?months=3\|6\|12`, `/donors/<id>` | Admin | Donor list and detail. |
| `GET /adminPanel/agenda?days=7` | Admin | PENDING calls and collections of every donor for the next days, plus overdue ones. |
| `GET /adminPanel/followUps`, `/donorFilters` | Admin | Donors to reschedule (NO_ANSWER call or FAILED collection, nothing pending) and the Telefonista/Recolector filters with donor counts. |
| `POST /adminPanel/donors`, `/calls`, `/collections` | Admin | Create donor, schedule call (telefonista) or collection (recolector). |
| `GET /adminPanel/staff`, `/personal?months=` | Admin | Staff list and performance. |
| `GET /telefonistas/calls` | Telefonista | The token user's calls for today (state `Próxima`/`Vencida`/`Terminada`). |
| `GET /telefonistas/donors/<id>` | Telefonista | Donor + history; only donors in their calls. |
| `POST /telefonistas/calls/<id>/result` | Telefonista | `{result, notes, calledAt?, amount?, collectionDate?, rescheduleDate?}`. |
| `POST /telefonistas/donors/<id>/notes` | Telefonista | Adds a `DonorNote`. |
| `GET /recolectores/route?date=YYYY-MM-DD` | Recolector | The token user's route for that day. |
| `POST /recolectores/result` | Recolector | `{collectionId, status: SUCCESSFUL\|FAILED, receivedAmount?, notes?}`. |
| `PUT /recolectores/reschedule` | Recolector | `{collectionId, newDate}` for a `FAILED` collection. |
| `GET /recolectores/history?collectionId=` | Recolector | Donations of that collection's donor. |
| `GET /recolectores/summary?date=` | Recolector | Day totals. |

Exact request/response shapes: `API/docs/*.yml`, Swagger UI at `/apidocs`, or offline by opening
`API/docs/swagger.html` in a browser (no server or database needed).

## 8. Running it

```sh
cd API
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # fill in real values; never commit .env
python server.py            # dev; production: gunicorn -c gunicorn.conf.py server:app
python -m tasks.daily_recurring_donations   # the daily task (cron in production)
```

`.env` variables: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `TASKS_DB_USER`,
`TASKS_DB_PASSWORD`, `API_HOST`, `API_PORT` (10206), `API_DEBUG` (false outside local dev),
`SSL_CERT_FILE`, `SSL_KEY_FILE` (both set → HTTPS, see `docs/https.md`), `JWT_SECRET` (32+ characters),
`JWT_EXP_HOURS`, `PASSWORD_PEPPER` (32+ characters), `MAX_REQUEST_BYTES` (default 1 MB). Without `API_HOST` the API listens only on `127.0.0.1`.
The server exits at startup if it cannot reach the database.

Security checks (run from `API/`): `bandit -r . -x ./sql,./venv,./.venv` must report 0 issues
(`sql/generate_demo_data.py` is an offline script and is excluded). `server.py` adds
`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, HSTS on HTTPS, and
a default `Content-Security-Policy` (with `form-action` and `base-uri`) and
`Cache-Control: no-store, no-cache, must-revalidate` on every response, and answers unknown
routes and errors with JSON. OWASP ZAP: import `https://<host>:10206/apispec_1.json` as an OpenAPI
definition, add the `Authorization: Bearer` header with the Replacer, then run an Active Scan.

iOS: open the `.xcodeproj` of each app in Xcode. Apps that use CaritasAuth add it as a local
package (`Shared/CaritasAuth`). Each app's base URL lives in its `Config/APIConfig.swift`:
always `https://monarcas.tc2007b.tec.mx:10206/api/`, never an IP address or plain `http://`, and
no `NSAllowsArbitraryLoads` in any `Info.plist`.

## 9. Known gaps (as of October 2026)

- **RecolectoresApp** still uses Spanish type, file and function names (`Recoleccion`,
  `RutaDiaView`, `ResultadoView`, `CaritasApi.registrarResultado`...), and both apps keep their
  original project names (`PantallaTelemarketinas`, `Ruta_del_dia`). Rename them to English when
  touched.
- The dashboard sums `Collection.ExpectedAmount` instead of `Donation.TotalAmount`, and the
  monthly chart groups by month without separating years.
- Closing a `CONFIRMATION` call should call `recurring_donations.resolve_installment(...)`; no
  endpoint does it yet. There is no admin endpoint to create pledges.
- See the "To do" list at the end of `docs/database.md`.
