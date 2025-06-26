
import random
from datetime import datetime, timedelta
import mysql.connector
from mysql.connector import errorcode
from faker import Faker
from names import nombres_bolivianos, apellidos_bolivianos

DB_CONFIG = {
    "user": "admin",
    "password": "admin",
    "host": "localhost",
    "port": 3306,
    "database": "organization",
    "autocommit": False  # haremos COMMIT manual cada cierto lote
}

# ---------- Funciones auxiliares ----------

def random_date(start: datetime, end: datetime) -> str:
    """Genera una fecha aleatoria (YYYY-MM-DD) entre start y end."""
    delta = end - start
    random_days = random.randint(0, delta.days)
    d = start + timedelta(days=random_days)
    return d.strftime("%Y-%m-%d")


def generar_ci_boliviano() -> str:
    """Genera un número de CI sintético boliviano (6-8 dígitos)."""
    longitud = random.choice([6,7,8])
    return str(random.randint(10**(longitud-1), 10**longitud - 1))


def generar_telefono_boliviano() -> str:
    """Genera un teléfono móvil boliviano con prefijo +591 y 7 dígitos que empiecen en 6 o 7."""
    primera = random.choice(["6", "7"])
    resto = "".join(str(random.randint(0,9)) for _ in range(7))
    return f"+591 {primera}{resto}"


def nombre_completo_boliviano(faker: Faker) -> (str, str, str):
    """
    Construye un nombre (primer + segundo) y dos apellidos al estilo boliviano.
    Devuelve (first_name, middle_name, last_names).
    """
    # Aleatorizamos género para escoger nombre
    genero = random.choice(["masculinos", "femeninos"])
    first = random.choice(nombres_bolivianos[genero])
    # Para segundo nombre, podemos elegir al azar de ambos géneros
    second = random.choice(nombres_bolivianos["masculinos"] + nombres_bolivianos["femeninos"])

    # Apellidos: combinamos dos apellidos de la lista
    apellido1 = random.choice(apellidos_bolivianos)
    apellido2 = random.choice([a for a in apellidos_bolivianos if a != apellido1])

    last_names = f"{apellido1} {apellido2}"
    return first, second, last_names


# ---------- Inicio de script ----------

def main():
    faker = Faker("es_ES")  # para mails y algunas direcciones en español

    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("Conexión a MariaDB exitosa.")
    except mysql.connector.Error as err:
        print("Error al conectar:", err)
        return

    #### 1) Poblar tabla `equipment_type`
    tipos = [
        (1, "Parrilla"),
        (2, "Horno"),
        (3, "Freidora"),
        (4, "Plancha"),
        (5, "Microondas"),
        (6, "Batidora"),
        (7, "Refrigerador")
    ]
    cursor.executemany(
        "INSERT INTO equipment_type (type_id, equipment_type) VALUES (%s, %s);",
        tipos
    )
    print(f"  • Insertados {len(tipos)} registros en equipment_type")

    #### 2) Poblar tabla `charges` (cargos de empleados)
    cargos = [ 
        (1,'Marketing',        2000),
        (2,'Limpieza',     1500),
        (3,'Asistente de cocina',  2200),
        (4,'Recepcionista',1800),
        (5,'Delivery',      1700),
        (6,'Seguridad',    1600),
        (7,'Relaciones con el cliente',      1900),
        (8,'Pasante',   1400)
    ]
    cursor.executemany(
        "INSERT INTO charges (charge_id, charge, base_payment) VALUES (%s, %s, %s);",
        cargos
    )
    print(f"  • Insertados {len(cargos)} registros en charges")

    #### 3) Poblar tabla `suppliers` (~200 proveedores)
    NUM_SUPPLIERS = 200
    suppliers_data = []
    for sup_id in range(1, NUM_SUPPLIERS + 1):
        # Nombre de empresa: combinamos palabras típicas en español
        # Ejemplo: "Equipos Bolivianos SAC", "Insumos Gastronómicos LTDA"
        prefijos = ["Equipos", "Suministros", "Insumos", "Cocinas", "Maquinaria"]
        sufijos = ["Bolivia", "Gastronómica", "Profesional", "Industrial", "Logística"]
        tipo_legal = random.choice(["S.A.", "LTDA", "SAC", "SRL"])
        nombre_empresa = f"{random.choice(prefijos)} {random.choice(sufijos)} {tipo_legal}"

        contract_date = random_date(datetime(2018, 1, 1), datetime(2023, 12, 31))
        contacto = random.choice(nombres_bolivianos["masculinos"] + nombres_bolivianos["femeninos"]) \
                   + " " + random.choice(apellidos_bolivianos)
        phone = generar_telefono_boliviano()
        email = faker.email().replace(".com", ".bo")  #_forzar extensión .bo

        suppliers_data.append((sup_id, nombre_empresa, contract_date, contacto, phone, email))

    cursor.executemany(
        """INSERT INTO suppliers 
           (supplier_id, supplier_name, contract_date, contact_name, contact_phone, contact_email)
           VALUES (%s, %s, %s, %s, %s, %s);""",
        suppliers_data
    )
    print(f"  • Insertados {NUM_SUPPLIERS} registros en suppliers")

    #### 4) Poblar tabla `supplier_equipment_type` (relación N:M)
    # Para cada supplier, asignamos entre 1 y 3 tipos de equipo al azar
    supplier_eq_data = []
    for sup_id in range(1, NUM_SUPPLIERS + 1):
        tipos_aleatorios = random.sample([t[0] for t in tipos], k=random.randint(1, 3))
        for t_id in tipos_aleatorios:
            supplier_eq_data.append((sup_id, t_id))

    cursor.executemany(
        "INSERT INTO supplier_equipment_type (supplier_id, type_id) VALUES (%s, %s);",
        supplier_eq_data
    )
    print(f"  • Insertados {len(supplier_eq_data)} registros en supplier_equipment_type")

    #### Confirmamos las tablas de referencia
    conn.commit()
    print("  → Tablas de referencia pobladas y confirmadas (COMMIT).")

    #### 5) Poblar tabla `cooking_equipment` (~10 000 filas)
    NUM_EQUIPOS = 20000
    batch_size = 1000
    equipos_data = []

    for i in range(1, NUM_EQUIPOS + 1):
        equipment_type = random.choice([t[0] for t in tipos])  # 1..7
        supplier_id = random.randint(1, NUM_SUPPLIERS)        # 1..200
        purchase_date = random_date(datetime(2018, 1, 1), datetime(2024, 6, 1))
        purchase_price = round(random.uniform(500, 8000), 2)  # entre 500 y 8000 Bs.
        in_use = random.choice([0, 1])
        needs_repair = random.choice([0, 1])
        sucursal_id = random.randint(1, 15)  # supongamos 15 sucursales

        equipos_data.append((
            equipment_type,
            supplier_id,
            purchase_date,
            purchase_price,
            in_use,
            needs_repair,
            sucursal_id
        ))

        # Cuando lleguemos a batch_size, hacemos INSERT múltiple y limpiamos lista
        if len(equipos_data) >= batch_size:
            cursor.executemany(
                """INSERT INTO cooking_equipment 
                   (equipment_type, supplier_id, purchase_date, purchase_price, in_use, needs_repair, sucursal_id)
                   VALUES (%s,%s,%s,%s,%s,%s,%s);""",
                equipos_data
            )
            conn.commit()
            equipos_data.clear()
            print(f"  • Insertados {i} filas en cooking_equipment…")

    # Insertar el resto si queda algo en la lista
    if equipos_data:
        cursor.executemany(
            """INSERT INTO cooking_equipment 
               (equipment_type, supplier_id, purchase_date, purchase_price, in_use, needs_repair, sucursal_id)
               VALUES (%s,%s,%s,%s,%s,%s,%s);""",
            equipos_data
        )
        conn.commit()
        print(f"  • Insertados {NUM_EQUIPOS} filas en cooking_equipment (último batch).")

    #### 6) Poblar tabla `employees` (~10 000 filas)
    NUM_EMPLEADOS = 20000
    empleados_data = []

    for i in range(1, NUM_EMPLEADOS + 1):
        # Generamos nombre completo boliviano
        first_name, middle_name, last_names = nombre_completo_boliviano(faker)
        ci = generar_ci_boliviano()
        sucursal_id = random.randint(1, 15)
        phone = generar_telefono_boliviano()
        contract_date = random_date(datetime(2018, 1, 1), datetime(2024, 6, 1))
        charge_id = random.choice([c[0] for c in cargos])  # entre 1 y 4

        empleados_data.append((
            first_name,
            middle_name,
            last_names,
            ci,
            sucursal_id,
            phone,
            contract_date,
            charge_id
        ))

        if len(empleados_data) >= batch_size:
            cursor.executemany(
                """INSERT INTO employees 
                   (first_name, middle_name, last_names, ci, sucursal_id, phone, contract_date, charge_id)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s);""",
                empleados_data
            )
            conn.commit()
            empleados_data.clear()
            print(f"  • Insertados {i} filas en employees…")

    # Insertar el remanente
    if empleados_data:
        cursor.executemany(
            """INSERT INTO employees 
               (first_name, middle_name, last_names, ci, sucursal_id, phone, contract_date, charge_id)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s);""",
            empleados_data
        )
        conn.commit()
        print(f"  • Insertados {NUM_EMPLEADOS} filas en employees (último batch).")

    #### Cerramos la conexión
    cursor.close()
    conn.close()
    print("¡Población completa! ~10 000 equipos y ~10 000 empleados ingresados con datos bolivianos.")

if __name__ == "__main__":
    main()
