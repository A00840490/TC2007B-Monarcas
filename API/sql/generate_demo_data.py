import random
from pathlib import Path

SEED = 2007
OUTPUT = Path(__file__).with_name('03_demo_data.sql')

PASSWORD_HASH = 'aa640a14722e867cf8b4258b2a1a145abeb9c0d8eb940ca54a1a6465a0737612'

USER_COUNTS = {'Admin': 4, 'Telefonista': 10, 'Recolector': 14}
DONOR_PROFILES = {
    'pledge_cash': 55,
    'pledge_transfer': 30,
    'occasional': 75,
    'finished_pledge': 8,
    'lapsed': 40,
    'stopped_pledge': 15,
    'prospect': 37,
}

CHART_DAYS = 320
WORK_START, WORK_END = 9 * 60, 18 * 60

FIRST_NAMES_F = [
    'María', 'Guadalupe', 'Juana', 'Margarita', 'Verónica', 'Leticia', 'Rosa', 'Patricia',
    'Adriana', 'Alejandra', 'Gabriela', 'Claudia', 'Mónica', 'Silvia', 'Norma', 'Elizabeth',
    'Martha', 'Lucía', 'Fernanda', 'Daniela', 'Sofía', 'Valeria', 'Ximena', 'Regina',
    'Andrea', 'Carmen', 'Teresa', 'Laura', 'Isabel', 'Paola', 'Diana', 'Karla', 'Brenda',
    'Cecilia', 'Beatriz', 'Mariana', 'Renata', 'Estela', 'Irma', 'Yolanda',
]
FIRST_NAMES_M = [
    'José', 'Juan', 'Luis', 'Carlos', 'Jorge', 'Miguel', 'Francisco', 'Alejandro',
    'Ricardo', 'Roberto', 'Fernando', 'Eduardo', 'Javier', 'Raúl', 'Héctor', 'Arturo',
    'Sergio', 'Manuel', 'Óscar', 'Daniel', 'Diego', 'Mauricio', 'Rodrigo', 'Andrés',
    'Gerardo', 'Alberto', 'Enrique', 'Hugo', 'Rogelio', 'Ramiro', 'Adrián', 'Emilio',
    'Santiago', 'Mateo', 'Sebastián', 'Gustavo', 'Armando', 'Ignacio', 'Pablo', 'Rubén',
]
SURNAMES = [
    'García', 'Hernández', 'Martínez', 'López', 'González', 'Rodríguez', 'Pérez', 'Sánchez',
    'Ramírez', 'Cruz', 'Flores', 'Gómez', 'Morales', 'Reyes', 'Jiménez', 'Torres',
    'Díaz', 'Vázquez', 'Ruiz', 'Mendoza', 'Aguilar', 'Ortiz', 'Castillo', 'Romero',
    'Garza', 'Treviño', 'Villarreal', 'Cantú', 'Salinas', 'Elizondo', 'Leal', 'Guerra',
    'Zambrano', 'Montemayor', 'Sada', 'Tamez', 'Benavides', 'Quiroga', 'Cavazos', 'De la Garza',
    'Rangel', 'Chapa', 'Lozano', 'Saldaña', 'Peña', 'Rocha', 'Medina', 'Castro',
]
STREETS = [
    'Av. Constitución', 'Av. Gonzalitos', 'Av. Lincoln', 'Av. Ruiz Cortines', 'Av. Garza Sada',
    'Av. Vasconcelos', 'Av. Gómez Morín', 'Av. Alfonso Reyes', 'Av. Revolución', 'Av. Universidad',
    'Calle Morelos', 'Calle Hidalgo', 'Calle Padre Mier', 'Calle Zaragoza', 'Calle Juárez',
    'Calle Washington', 'Calle 5 de Mayo', 'Calle Allende', 'Calle Aramberri', 'Calle Matamoros',
    'Río Nazas', 'Río Missouri', 'Río Guadalquivir', 'Calzada del Valle', 'Calle Jiménez',
    'Av. Eugenio Garza Sada', 'Calle Arista', 'Calle Colón', 'Av. Madero', 'Av. Pino Suárez',
]
NEIGHBORHOODS = [
    ('Centro', 'Monterrey'), ('Mitras Centro', 'Monterrey'), ('Obispado', 'Monterrey'),
    ('Contry', 'Monterrey'), ('Cumbres', 'Monterrey'), ('Tecnológico', 'Monterrey'),
    ('Roma', 'Monterrey'), ('Linda Vista', 'Guadalupe'), ('Contry La Silla', 'Guadalupe'),
    ('Del Valle', 'San Pedro Garza García'), ('Valle Oriente', 'San Pedro Garza García'),
    ('Fuentes del Valle', 'San Pedro Garza García'), ('Anáhuac', 'San Nicolás de los Garza'),
    ('Las Puentes', 'San Nicolás de los Garza'), ('Residencial Cumbres', 'Monterrey'),
    ('Valle de Santa Engracia', 'San Pedro Garza García'), ('Bosques del Valle', 'San Pedro Garza García'),
    ('Centro', 'Santa Catarina'), ('Cerradas de Anáhuac', 'General Escobedo'), ('Centro', 'Apodaca'),
]
CAMPAIGNS = [
    'Fondo general', 'Fondo general', 'Campaña de invierno', 'Banco de alimentos',
    'Becas escolares', 'Casa hogar', 'Apoyo médico', 'Despensas navideñas',
]
PLEDGE_AMOUNTS = [150, 200, 250, 300, 300, 500, 500, 500, 750, 1000, 1000, 1500, 2000, 3000]
ONE_OFF_AMOUNTS = [100, 150, 200, 250, 300, 400, 500, 500, 600, 800, 1000, 1000, 1200,
                   1500, 2000, 2500, 3000, 5000]

REGULAR_GOALS = [
    'Invitar a donar a la {c}',
    'Presentar la {c} y proponer un donativo',
    'Agradecer su último donativo e invitar a la {c}',
    'Proponer donativo mensual para la {c}',
]
RECOVER_GOALS = [
    'Retomar contacto, no dona desde hace varios meses',
    'Preguntar si desea reactivar su donativo mensual',
    'Invitar de nuevo a la {c}',
]
PROSPECT_GOALS = [
    'Primer contacto, referido por otro donante',
    'Primer contacto, se registró en la colecta parroquial',
    'Presentar el trabajo de Cáritas e invitar a la {c}',
]
CALL_RESULT_NOTES = {
    'NO_ANSWER': ['No contestó', 'Buzón de voz', 'Teléfono apagado', None],
    'DECLINED': ['Por ahora no puede donar', 'Prefiere no recibir más llamadas este mes',
                 'Ya dona a otra institución', None],
    'RESCHEDULED': ['Pidió que le llamen la próxima semana', 'Estaba ocupado, volver a llamar',
                    None],
}
COLLECTION_NOTES = [None, None, None, 'Tocar en la puerta lateral', 'Dejar recibo con el portero',
                    'Llamar al llegar', 'Casa con portón negro', 'Preguntar por la señora de la casa',
                    'Entregar en la oficina, horario de 9 a 14 h']
FAILED_NOTES = ['No había nadie en casa', 'El donante no tenía el efectivo',
                'Dirección no encontrada', 'Reprogramar para el próximo mes']

rng = random.Random(SEED)


def sql_str(value):
    if value is None:
        return 'NULL'
    return "N'" + str(value).replace("'", "''") + "'"


def sql_num(value):
    return 'NULL' if value is None else str(value)


def slug(text):
    table = str.maketrans('áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')
    return text.translate(table).lower().replace(' ', '')


def person_name(used):
    while True:
        first = rng.choice(FIRST_NAMES_F if rng.random() < 0.5 else FIRST_NAMES_M)
        surname = rng.choice(SURNAMES)
        name = f'{first} {surname} {rng.choice(SURNAMES)}'
        if name not in used:
            used.add(name)
            return name, first, surname


used_names = set()
users = []
used_emails = {'admin@caritas.org.mx', 'telefonista@caritas.org.mx', 'recolector@caritas.org.mx'}
for role, count in USER_COUNTS.items():
    for _ in range(count):
        name, first, last = person_name(used_names)
        email = f'{slug(first)}.{slug(last)}@caritas.org.mx'
        n = 2
        while email in used_emails:
            email = f'{slug(first)}.{slug(last)}{n}@caritas.org.mx'
            n += 1
        used_emails.add(email)
        users.append((name, email, role))

telefonistas = [u[1] for u in users if u[2] == 'Telefonista']
recolectores = [u[1] for u in users if u[2] == 'Recolector']

donors = []
pledges = []
calls = []
collections = []
donations = []
origin_calls = []

used_phones = {f'819900000{i}' for i in range(1, 10)}
busy = {}


def new_phone():
    while True:
        phone = rng.choice(['81', '81', '81', '81', '55', '33']) + str(rng.randint(10_000_000, 99_999_999))
        if phone not in used_phones:
            used_phones.add(phone)
            return phone


def address():
    street = rng.choice(STREETS)
    hood, city = rng.choice(NEIGHBORHOODS)
    return f'{street} {rng.randint(100, 4800)}, {hood}, {city}, N.L.'


def slot(phone, day, start=WORK_START, end=WORK_END):
    taken = busy.setdefault(phone, set())
    while True:
        minute = rng.randrange(start, end, 15)
        if (day, minute) not in taken:
            taken.add((day, minute))
            return day, minute


def add_call(phone, telefonista, day, call_type='REGULAR', status=None, notes=None,
             pledge=False, minute=None):
    if status is None:
        status = 'PENDING'
    if minute is None:
        day, minute = slot(phone, day)
    else:
        busy.setdefault(phone, set()).add((day, minute))
    call = {'phone': phone, 'user': telefonista, 'type': call_type, 'status': status,
            'notes': notes, 'day': day, 'minute': minute, 'pledge': pledge}
    calls.append(call)
    return call


def add_collection(phone, recolector, day, status, amount, notes=None, call=None,
                   pledge=False, route_order=None):
    day, minute = slot(phone, day)
    collection = {'phone': phone, 'user': recolector, 'status': status, 'notes': notes,
                  'day': day, 'minute': minute, 'amount': amount, 'route_order': route_order,
                  'call': call, 'pledge': pledge}
    collections.append(collection)
    return collection


def add_donation(phone, day, minute, amount, method, campaign, notes=None,
                 collection=None, call=None, pledge=False):
    donations.append({'phone': phone, 'day': day, 'minute': minute, 'amount': amount,
                      'method': method, 'campaign': campaign, 'notes': notes,
                      'collection': collection, 'call': call, 'pledge': pledge})


def call_outcome(phone, telefonista, day, campaign, kind=REGULAR_GOALS):
    status = rng.choice(['NO_ANSWER', 'NO_ANSWER', 'DECLINED', 'RESCHEDULED'])
    goal = rng.choice(kind).format(c=campaign.lower() if campaign != 'Fondo general' else 'campaña del mes')
    result = rng.choice(CALL_RESULT_NOTES[status])
    notes = goal if result is None else f'{goal}. {result}'
    return add_call(phone, telefonista, day, status=status, notes=notes)


def one_off_gift(phone, day, campaign, method=None):
    telefonista = rng.choice(telefonistas)
    method = method or ('CASH' if rng.random() < 0.65 else 'TRANSFER')
    amount = rng.choice(ONE_OFF_AMOUNTS)
    goal = rng.choice(REGULAR_GOALS).format(c=campaign.lower() if campaign != 'Fondo general' else 'campaña del mes')
    if method == 'CASH':
        collection_day = min(day + rng.randint(2, 6), -1)
        call_day = min(day, collection_day - 1)
        call = add_call(phone, telefonista, call_day, status='ACCEPTED',
                        notes=f'{goal}. Aceptó donar ${amount} en efectivo')
        failed = rng.random() < 0.08
        collection = add_collection(phone, rng.choice(recolectores), collection_day,
                                    'FAILED' if failed else 'SUCCESSFUL', amount,
                                    notes=rng.choice(FAILED_NOTES) if failed else rng.choice(COLLECTION_NOTES),
                                    call=call)
        if not failed:
            add_donation(phone, collection['day'], collection['minute'], amount, 'CASH', campaign,
                         collection=collection, call=call)
        return not failed
    call = add_call(phone, telefonista, day, status='ACCEPTED',
                    notes=f'{goal}. Hará transferencia de ${amount}')
    add_donation(phone, call['day'], call['minute'] + 30, amount, 'TRANSFER', campaign, call=call)
    return True


def old_gift(phone, day, campaign):
    method = 'CASH' if rng.random() < 0.6 else 'TRANSFER'
    add_donation(phone, day, rng.randrange(WORK_START, WORK_END, 15), rng.choice(ONE_OFF_AMOUNTS),
                 method, campaign)


def recurring_history(phone, method, amount, campaign, start, last, telefonista, recolector,
                      skip_rate=0.08):
    day = start
    while day < last:
        if day > 0:
            break
        if day == 0:
            add_call(phone, telefonista, -1, 'CONFIRMATION', 'ACCEPTED',
                     'Confirmó que mañana puede recibir al recolector' if method == 'CASH'
                     else 'Confirmó que mañana hace la transferencia', pledge=True)
            if method == 'CASH':
                add_collection(phone, recolector, 0, 'PENDING', amount,
                               notes=f'Cuota mensual ({campaign})', pledge=True)
            else:
                add_call(phone, telefonista, 0, 'TRANSFER_COLLECTION', 'PENDING',
                         f'Concretar transferencia de la cuota mensual de ${amount} ({campaign})',
                         pledge=True)
            day += 30
            continue

        confirmed = rng.random() > 0.15
        confirmation = None
        if day - 1 > start - 10:
            confirmation = add_call(
                phone, telefonista, day - 1, 'CONFIRMATION',
                'ACCEPTED' if confirmed else 'NO_ANSWER',
                'Confirmar que mañana puede recibir al recolector' if method == 'CASH'
                else 'Preguntar si mañana prefiere que pasen a recoger o concretar la transferencia',
                pledge=True)
        if rng.random() < skip_rate:
            day += 30
            continue
        if method == 'CASH':
            failed = rng.random() < 0.07
            collection = add_collection(
                phone, recolector, day, 'FAILED' if failed else 'SUCCESSFUL', amount,
                notes=rng.choice(FAILED_NOTES) if failed else f'Cuota mensual ({campaign})',
                call=confirmation if confirmation and confirmation['status'] == 'ACCEPTED' else None,
                pledge=True)
            if not failed:
                add_donation(phone, collection['day'], collection['minute'], amount, 'CASH', campaign,
                             collection=collection, pledge=True)
        else:
            call = add_call(phone, telefonista, day, 'TRANSFER_COLLECTION', 'ACCEPTED',
                            f'Concretar transferencia de la cuota mensual de ${amount} ({campaign})',
                            pledge=True)
            add_donation(phone, day, call['minute'] + 30, amount, 'TRANSFER', campaign,
                         call=call, pledge=True)
        day += 30
    return day


def add_pledge(phone, method, amount, campaign, start, next_installment, status,
               telefonista, recolector, end=None, notes=None):
    origin = add_call(phone, telefonista, start - rng.randint(3, 10), status='ACCEPTED',
                      notes=f'Aceptó donativo mensual de ${amount} para {campaign.lower()}')
    origin_calls.append((phone, origin['day'], origin['minute']))
    pledges.append({'phone': phone, 'amount': amount, 'method': method, 'campaign': campaign,
                    'start': start, 'next': next_installment, 'end': end, 'status': status,
                    'telefonista': telefonista, 'recolector': recolector, 'notes': notes})


def risk_from_last(last_day):
    if last_day is None:
        return rng.choice(['LOW', 'MEDIUM'])
    days = -last_day
    if days <= 60:
        return 'LOW' if rng.random() < 0.9 else 'MEDIUM'
    if days <= 180:
        return 'MEDIUM' if rng.random() < 0.75 else 'HIGH'
    return 'HIGH'


for profile, count in DONOR_PROFILES.items():
    for _ in range(count):
        name = person_name(used_names)[0]
        phone = new_phone()
        campaign = rng.choice(CAMPAIGNS)
        telefonista = rng.choice(telefonistas)
        recolector = rng.choice(recolectores)
        risk = 'LOW'

        if profile in ('pledge_cash', 'pledge_transfer'):
            method = 'CASH' if profile == 'pledge_cash' else 'TRANSFER'
            amount = rng.choice(PLEDGE_AMOUNTS)
            start = -rng.randint(0, 300)
            if rng.random() < 0.25:
                start = -30 * rng.randint(1, 9) + rng.choice([0, 0, 1])
            next_day = recurring_history(phone, method, amount, campaign, start, 1,
                                         telefonista, recolector)
            if next_day == 1:
                add_call(phone, telefonista, 0, 'CONFIRMATION', 'PENDING',
                         'Confirmar que mañana puede recibir al recolector' if method == 'CASH'
                         else 'Preguntar si mañana prefiere que pasen a recoger o concretar la transferencia',
                         pledge=True)
            add_pledge(phone, method, amount, campaign, start, next_day, 'ACTIVE',
                       telefonista, recolector)
            risk = 'LOW' if rng.random() < 0.85 else 'MEDIUM'
            if rng.random() < 0.25:
                one_off_gift(phone, -rng.randint(5, CHART_DAYS), rng.choice(CAMPAIGNS))

        elif profile == 'finished_pledge':
            method = 'CASH' if rng.random() < 0.6 else 'TRANSFER'
            amount = rng.choice(PLEDGE_AMOUNTS)
            start = -rng.randint(200, 310)
            end = start + 30 * rng.randint(3, 5)
            next_day = recurring_history(phone, method, amount, campaign, start, end + 1,
                                         telefonista, recolector, skip_rate=0)
            add_pledge(phone, method, amount, campaign, start, next_day, 'FINISHED',
                       telefonista, recolector, end=end,
                       notes='Donativo mensual por temporada, concluyó')
            last = end
            if rng.random() < 0.5:
                one_off_gift(phone, -rng.randint(10, 60), campaign)
                last = -30
            risk = risk_from_last(last)

        elif profile == 'occasional':
            gifts = sorted(-rng.randint(3, CHART_DAYS) for _ in range(rng.randint(1, 5)))
            last = None
            for day in gifts:
                if one_off_gift(phone, day, rng.choice(CAMPAIGNS)):
                    last = day
            for _ in range(rng.randint(0, 2)):
                call_outcome(phone, rng.choice(telefonistas), -rng.randint(1, CHART_DAYS), campaign)
            risk = risk_from_last(last)

        elif profile == 'lapsed':
            for _ in range(rng.randint(1, 4)):
                day = -rng.randint(200, 720)
                if day >= -CHART_DAYS:
                    one_off_gift(phone, day, rng.choice(CAMPAIGNS))
                else:
                    old_gift(phone, day, rng.choice(CAMPAIGNS))
            for _ in range(rng.randint(1, 3)):
                call_outcome(phone, rng.choice(telefonistas), -rng.randint(1, 150), campaign,
                             RECOVER_GOALS)
            risk = 'HIGH' if rng.random() < 0.8 else 'MEDIUM'

        elif profile == 'stopped_pledge':
            status = 'PAUSED' if rng.random() < 0.4 else 'CANCELLED'
            method = 'CASH' if rng.random() < 0.6 else 'TRANSFER'
            amount = rng.choice(PLEDGE_AMOUNTS)
            start = -rng.randint(250, 315)
            stop = -rng.randint(90, 200)
            next_day = recurring_history(phone, method, amount, campaign, start, stop,
                                         telefonista, recolector)
            add_pledge(phone, method, amount, campaign, start, next_day, status,
                       telefonista, recolector, end=None if status == 'PAUSED' else next_day,
                       notes='Pausó por gastos familiares' if status == 'PAUSED'
                       else 'Canceló, se mudó de ciudad' if rng.random() < 0.5
                       else 'Canceló por cambio de trabajo')
            call_outcome(phone, telefonista, -rng.randint(5, 80), campaign, RECOVER_GOALS)
            risk = 'HIGH' if rng.random() < 0.7 else 'MEDIUM'

        elif profile == 'prospect':
            for _ in range(rng.randint(0, 2)):
                call_outcome(phone, rng.choice(telefonistas), -rng.randint(1, 60), campaign,
                             PROSPECT_GOALS)
            risk = rng.choice(['LOW', 'LOW', 'MEDIUM'])

        donors.append((name, phone, address(), risk, profile))

by_profile = {}
for donor in donors:
    by_profile.setdefault(donor[4], []).append(donor)


def goal_for(profile, campaign):
    kind = {'prospect': PROSPECT_GOALS, 'lapsed': RECOVER_GOALS,
            'stopped_pledge': RECOVER_GOALS}.get(profile, REGULAR_GOALS)
    return rng.choice(kind).format(c=campaign.lower() if campaign != 'Fondo general' else 'campaña del mes')


call_targets = (by_profile['prospect'] + by_profile['lapsed'] + by_profile['stopped_pledge']
                + by_profile['occasional'] + by_profile['finished_pledge'])
rng.shuffle(call_targets)
targets = iter(call_targets)
for telefonista in telefonistas:
    for day, count in ((0, rng.randint(3, 5)), (1, rng.randint(1, 3)), (rng.randint(2, 7), rng.randint(1, 2))):
        for _ in range(count):
            donor = next(targets)
            add_call(donor[1], telefonista, day, notes=goal_for(donor[4], rng.choice(CAMPAIGNS)))

for telefonista in telefonistas[:6]:
    donor = next(targets)
    status = rng.choice(['NO_ANSWER', 'DECLINED', 'RESCHEDULED'])
    _, minute = slot(donor[1], 0, 9 * 60, 10 * 60)
    add_call(donor[1], telefonista, 0, status=status,
             notes=f"{goal_for(donor[4], 'Fondo general')}. {rng.choice(CALL_RESULT_NOTES[status][:-1])}",
             minute=minute)

collection_targets = by_profile['occasional'] + by_profile['finished_pledge'] + by_profile['pledge_cash']
for day in (0, 1):
    for recolector in recolectores:
        for _ in range(rng.randint(2, 4)):
            donor = rng.choice(collection_targets)
            amount = rng.choice(ONE_OFF_AMOUNTS)
            call = add_call(donor[1], rng.choice(telefonistas), day - rng.randint(1, 4),
                            status='ACCEPTED',
                            notes=f'{goal_for(donor[4], rng.choice(CAMPAIGNS))}. Aceptó donar ${amount} en efectivo')
            add_collection(donor[1], recolector, day, 'PENDING', amount,
                           notes=rng.choice(COLLECTION_NOTES), call=call)

for day in (0, 1):
    for recolector in recolectores:
        stops = sorted((c for c in collections
                        if c['user'] == recolector and c['day'] == day and c['status'] == 'PENDING'),
                       key=lambda c: c['minute'])
        for order, stop in enumerate(stops, start=1):
            stop['route_order'] = order

call_keys = {(c['phone'], c['day'], c['minute']) for c in calls}
assert len(call_keys) == len(calls), 'two calls of a donor share a date'
collection_keys = {(c['phone'], c['day'], c['minute']) for c in collections}
assert len(collection_keys) == len(collections), 'two collections of a donor share a date'
assert all(d['day'] < 0 for d in donations), 'donations must be in the past'
assert all(p['next'] >= p['start'] and (p['end'] is None or p['end'] >= p['start']) for p in pledges)
assert len({p['phone'] for p in pledges}) == len(pledges), 'one pledge per donor'
pledge_phones = {p['phone'] for p in pledges}
assert all(x['phone'] in pledge_phones for x in calls + collections + donations if x['pledge'])
assert all(c['day'] >= -CHART_DAYS for c in collections if c['status'] == 'SUCCESSFUL')
for item in calls + collections + donations:
    for text in (item.get('notes'), item.get('campaign')):
        assert text is None or ';' not in text, 'no ";" in texts: some clients split on it'

TODAY = 'CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0))'
TODAY_DATE = 'CAST(SYSDATETIME() AS DATE)'
CHUNK = 400


def at(day, minute):
    return f'DATEADD(MINUTE, {minute}, DATEADD(DAY, {day}, {TODAY}))'


def at_columns(day_col, minute_col):
    return f'DATEADD(MINUTE, {minute_col}, DATEADD(DAY, {day_col}, {TODAY}))'


def chunks(rows):
    for i in range(0, len(rows), CHUNK):
        yield rows[i:i + CHUNK]


def values(rows):
    return ',\n'.join('    (' + ', '.join(row) + ')' for row in rows)


def in_list(items, per_line=8):
    lines = [', '.join(sql_str(i) for i in items[i:i + per_line]) for i in range(0, len(items), per_line)]
    return '\n        ' + ',\n        '.join(lines)


demo_donors = f"(SELECT ID FROM dbo.Donor WHERE Phone IN ({in_list([d[1] for d in donors])}))"
demo_users = f"(SELECT ID FROM dbo.Users WHERE Email IN ({in_list([u[1] for u in users], 4)}))"
demo_calls = f"(SELECT ID FROM dbo.PhoneCall WHERE DonorID IN DEMO_DONORS OR UserID IN DEMO_USERS)"
demo_collections = f"(SELECT ID FROM dbo.Collection WHERE DonorID IN DEMO_DONORS OR UserID IN DEMO_USERS)"
demo_pledges = ("(SELECT ID FROM dbo.RecurringDonation WHERE DonorID IN DEMO_DONORS "
                "OR TelefonistaID IN DEMO_USERS OR RecolectorID IN DEMO_USERS)")


def expand(sql):
    return (sql.replace('DEMO_CALLS', demo_calls).replace('DEMO_COLLECTIONS', demo_collections)
            .replace('DEMO_PLEDGES', demo_pledges)
            .replace('DEMO_DONORS', demo_donors).replace('DEMO_USERS', demo_users))


out = []
w = out.append

w(f"""-- 03_demo_data.sql
-- GENERATED by generate_demo_data.py: do not edit by hand, change the generator
-- and run it again (python3 API/sql/generate_demo_data.py).
--
-- A large set of fictitious data so the apps have something to show:
-- {len(users)} users ({USER_COUNTS['Admin']} admins, {USER_COUNTS['Telefonista']} telefonistas, {USER_COUNTS['Recolector']} recolectores), {len(donors)} donors,
-- {len(pledges)} recurring pledges, {len(calls)} calls, {len(collections)} collections and {len(donations)} donations over
-- the last months. Dates are relative to the day it runs: every telefonista has
-- calls today and every recolector has a route today and tomorrow.
--
-- Every user has the password Caritas2026 (same as 02_seed_data.sql). The
-- emails are listed in API/sql/README.md. Do not use them in production.
--
-- It can run on its own after 01_create_database.sql, or after 02_seed_data.sql.
-- Running it again deletes its own rows (found by its donors' phones and its
-- users' emails, plus anything that points to them) and inserts them again,
-- with dates moved to the new day. Other rows are not touched.
--
-- Like the other scripts it has no GO and no variables, so it runs in DBeaver
-- with "Execute SQL Script" (Alt+X) or with sqlcmd -f 65001.

SET NOCOUNT ON;

------------------------------------------------------------------------------
-- 1. Delete the previous run's rows, children first.
------------------------------------------------------------------------------
""")

cleanup = [
    'DELETE FROM dbo.DonorNote WHERE DonorID IN DEMO_DONORS OR UserID IN DEMO_USERS',
    'UPDATE dbo.Donation SET CallID = NULL WHERE CallID IN DEMO_CALLS',
    'UPDATE dbo.Donation SET CollectionID = NULL WHERE CollectionID IN DEMO_COLLECTIONS',
    'UPDATE dbo.Donation SET RecurringDonationID = NULL WHERE RecurringDonationID IN DEMO_PLEDGES',
    'DELETE FROM dbo.Donation WHERE DonorID IN DEMO_DONORS',
    'UPDATE dbo.RecurringDonation SET OriginCallID = NULL WHERE OriginCallID IN DEMO_CALLS',
    'UPDATE dbo.RecurringDonation SET OriginCollectionID = NULL WHERE OriginCollectionID IN DEMO_COLLECTIONS',
    'UPDATE dbo.PhoneCall SET RecurringDonationID = NULL WHERE RecurringDonationID IN DEMO_PLEDGES',
    'UPDATE dbo.Collection SET RecurringDonationID = NULL WHERE RecurringDonationID IN DEMO_PLEDGES',
    'UPDATE dbo.Collection SET CallID = NULL WHERE CallID IN DEMO_CALLS',
    'DELETE FROM dbo.RecurringDonation WHERE ID IN DEMO_PLEDGES',
    'DELETE FROM dbo.Collection WHERE ID IN DEMO_COLLECTIONS',
    'DELETE FROM dbo.PhoneCall WHERE ID IN DEMO_CALLS',
    'DELETE FROM dbo.Donor WHERE ID IN DEMO_DONORS',
    'DELETE FROM dbo.Users WHERE ID IN DEMO_USERS',
]
for statement in cleanup:
    w(expand(statement) + ';\n')

w("""
------------------------------------------------------------------------------
-- 2. Roles (only if 02_seed_data.sql did not create them) and users.
------------------------------------------------------------------------------
INSERT INTO dbo.Role (Name)
SELECT r.Name FROM (VALUES ('Admin'), ('Telefonista'), ('Recolector')) AS r (Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Role WHERE Name = r.Name);

""")
w(f"""INSERT INTO dbo.Users (Name, Email, PasswordHash, RoleID)
SELECT u.Name, u.Email, '{PASSWORD_HASH}', r.ID
FROM (VALUES
{values([[sql_str(n), sql_str(e), sql_str(r)] for n, e, r in users])}
) AS u (Name, Email, RoleName)
JOIN dbo.Role r ON r.Name = u.RoleName;

------------------------------------------------------------------------------
-- 3. Donors.
------------------------------------------------------------------------------
""")
for rows in chunks(donors):
    w(f"""INSERT INTO dbo.Donor (Name, Phone, Address, RiskStatus) VALUES
{values([[sql_str(n), "'" + p + "'", sql_str(a), "'" + r + "'"] for n, p, a, r, _ in rows])};

""")

w("""------------------------------------------------------------------------------
-- 4. Recurring pledges (OriginCallID is filled in at the end).
------------------------------------------------------------------------------
""")
pledge_rows = [[f"'{p['phone']}'", str(p['amount']), f"'{p['method']}'", sql_str(p['campaign']),
                str(p['start']), str(p['next']), sql_num(p['end']), f"'{p['status']}'",
                sql_str(p['telefonista']), sql_str(p['recolector']), sql_str(p['notes'])]
               for p in pledges]
for rows in chunks(pledge_rows):
    w(f"""INSERT INTO dbo.RecurringDonation
    (DonorID, Amount, PaymentMethod, TargetCampaign, StartDate, NextInstallmentDate, EndDate,
     Status, TelefonistaID, RecolectorID, Notes)
SELECT d.ID, v.Amount, v.PaymentMethod, v.Campaign,
       DATEADD(DAY, v.StartDay, {TODAY_DATE}),
       DATEADD(DAY, v.NextDay, {TODAY_DATE}),
       DATEADD(DAY, v.EndDay, {TODAY_DATE}),
       v.Status, t.ID, r.ID, v.Notes
FROM (VALUES
{values(rows)}
) AS v (Phone, Amount, PaymentMethod, Campaign, StartDay, NextDay, EndDay, Status,
        TelefonistaEmail, RecolectorEmail, Notes)
JOIN dbo.Donor d ON d.Phone = v.Phone
JOIN dbo.Users t ON t.Email = v.TelefonistaEmail
JOIN dbo.Users r ON r.Email = v.RecolectorEmail;

""")

w("""------------------------------------------------------------------------------
-- 5. Phone calls.
------------------------------------------------------------------------------
""")
call_rows = [[f"'{c['phone']}'", sql_str(c['user']), f"'{c['type']}'", f"'{c['status']}'",
              sql_str(c['notes']), str(c['day']), str(c['minute']), '1' if c['pledge'] else '0']
             for c in sorted(calls, key=lambda c: (c['day'], c['minute']))]
for rows in chunks(call_rows):
    w(f"""INSERT INTO dbo.PhoneCall (UserID, DonorID, Type, Status, Notes, ScheduledDate, RecurringDonationID)
SELECT u.ID, d.ID, v.Type, v.Status, v.Notes, {at_columns('v.DayOffset', 'v.Minute')},
       CASE WHEN v.FromPledge = 1 THEN rd.ID END
FROM (VALUES
{values(rows)}
) AS v (Phone, Email, Type, Status, Notes, DayOffset, Minute, FromPledge)
JOIN dbo.Donor d ON d.Phone = v.Phone
JOIN dbo.Users u ON u.Email = v.Email
LEFT JOIN dbo.RecurringDonation rd ON rd.DonorID = d.ID;

""")

w("""------------------------------------------------------------------------------
-- 6. Collections, linked to the call that arranged them.
------------------------------------------------------------------------------
""")


def key_cols(item):
    return ['NULL', 'NULL'] if item is None else [str(item['day']), str(item['minute'])]


collection_rows = [[f"'{c['phone']}'", sql_str(c['user']), f"'{c['status']}'", sql_str(c['notes']),
                    str(c['day']), str(c['minute']), f"{c['amount']}.00", sql_num(c['route_order']),
                    *key_cols(c['call']), '1' if c['pledge'] else '0']
                   for c in sorted(collections, key=lambda c: (c['day'], c['minute']))]
for rows in chunks(collection_rows):
    w(f"""INSERT INTO dbo.Collection
    (UserID, DonorID, Status, Notes, ScheduledDate, ExpectedAmount, RouteOrder, CallID, RecurringDonationID)
SELECT u.ID, d.ID, v.Status, v.Notes, {at_columns('v.DayOffset', 'v.Minute')},
       v.ExpectedAmount, v.RouteOrder, pc.ID,
       CASE WHEN v.FromPledge = 1 THEN rd.ID END
FROM (VALUES
{values(rows)}
) AS v (Phone, Email, Status, Notes, DayOffset, Minute, ExpectedAmount, RouteOrder,
        CallDayOffset, CallMinute, FromPledge)
JOIN dbo.Donor d ON d.Phone = v.Phone
JOIN dbo.Users u ON u.Email = v.Email
LEFT JOIN dbo.PhoneCall pc
    ON pc.DonorID = d.ID AND pc.ScheduledDate = {at_columns('v.CallDayOffset', 'v.CallMinute')}
LEFT JOIN dbo.RecurringDonation rd ON rd.DonorID = d.ID;

""")

w("""------------------------------------------------------------------------------
-- 7. Donations (past only), linked to their collection, call and pledge.
------------------------------------------------------------------------------
""")
donation_rows = [[f"'{d['phone']}'", str(d['day']), str(d['minute']), f"{d['amount']}.00",
                  f"'{d['method']}'", sql_str(d['campaign']), sql_str(d['notes']),
                  *key_cols(d['collection']), *key_cols(d['call']), '1' if d['pledge'] else '0']
                 for d in sorted(donations, key=lambda d: (d['day'], d['minute']))]
for rows in chunks(donation_rows):
    w(f"""INSERT INTO dbo.Donation
    (DonorID, DonationDate, TotalAmount, PaymentMethod, TargetCampaign, Notes,
     CollectionID, CallID, RecurringDonationID)
SELECT d.ID, {at_columns('v.DayOffset', 'v.Minute')}, v.Amount, v.PaymentMethod, v.Campaign, v.Notes,
       c.ID, pc.ID, CASE WHEN v.FromPledge = 1 THEN rd.ID END
FROM (VALUES
{values(rows)}
) AS v (Phone, DayOffset, Minute, Amount, PaymentMethod, Campaign, Notes,
        CollectionDayOffset, CollectionMinute, CallDayOffset, CallMinute, FromPledge)
JOIN dbo.Donor d ON d.Phone = v.Phone
LEFT JOIN dbo.Collection c
    ON c.DonorID = d.ID AND c.ScheduledDate = {at_columns('v.CollectionDayOffset', 'v.CollectionMinute')}
LEFT JOIN dbo.PhoneCall pc
    ON pc.DonorID = d.ID AND pc.ScheduledDate = {at_columns('v.CallDayOffset', 'v.CallMinute')}
LEFT JOIN dbo.RecurringDonation rd ON rd.DonorID = d.ID;

""")

w(f"""------------------------------------------------------------------------------
-- 8. The call where each pledge was obtained.
------------------------------------------------------------------------------
UPDATE rd SET OriginCallID = pc.ID
FROM dbo.RecurringDonation rd
JOIN dbo.Donor d ON d.ID = rd.DonorID
JOIN (VALUES
{values([[f"'{p}'", str(day), str(minute)] for p, day, minute in origin_calls])}
) AS v (Phone, DayOffset, Minute) ON v.Phone = d.Phone
JOIN dbo.PhoneCall pc
    ON pc.DonorID = d.ID AND pc.ScheduledDate = {at_columns('v.DayOffset', 'v.Minute')};
""")

OUTPUT.write_text(''.join(out), encoding='utf-8')

print(f'{OUTPUT.name}: {len(users)} users, {len(donors)} donors, {len(pledges)} pledges, '
      f'{len(calls)} calls, {len(collections)} collections, {len(donations)} donations')
for role in USER_COUNTS:
    print(role, [e for _, e, r in users if r == role])
