#pip install faker

import csv
import random
from faker import Faker
from datetime import timedelta, datetime

faker = Faker('es_ES')
Faker.seed(42)
random.seed(42)

Configuración
NUM_USERS = 20000
NUM_RESERVAS = 20000
NUM_PAGOS = 20000
NUM_SUCURSALES = 10
NUM_ESTACIONES = 15
NUM_RESERVAS_SALON = 100
NUM_DIRECCIONES = NUM_SUCURSALES



# 1. BUSINESS TYPE (adaptado para cocinas)
kitchen_business_types = [
    "Pastelería", "Panadería", "Comida Vegana",
    "Pizzas Artesanales", "Heladería", "Comida Mexicana",
    "Sushi Bar", "Hamburguesas Gourmet", "Repostería",
    "Comida Italiana", "Cocina Asiática", "Catering",
    "Comida Saludable", "Postres", "Cafetería",
    "Comida Rápida", "Comida Orgánica", "Chocolatería",
    "Comida Peruana", "Empanadas"
]

with open("business_type.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["type_id", "type_name"])
    for i, bt in enumerate(kitchen_business_types, 1):
        writer.writerow([i, bt])

# 2. DIRECCIONES (para cocinas comerciales)
cities = ["Madrid", "Barcelona", "Valencia", "Sevilla", "Bilbao"]
with open("directions.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["directions_id", "number", "street_name", "city"])
    for i in range(1, NUM_DIRECCIONES + 1):
        writer.writerow([
            i,
            faker.building_number(),
            faker.street_name()[:25],
            random.choice(cities)
        ])

# 3. SUCURSALES (nombres más apropiados)
kitchen_names = [
    "Cocina Central", "Taller Gastronómico", "Espacio Culinario",
    "Laboratorio de Sabores", "Cocina Creativa"
]
with open("sucursales.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["sucursal_id", "sucursal_name", "id_direction"])
    for i in range(1, NUM_SUCURSALES + 1):
        name = f"{random.choice(kitchen_names)} {i}" if NUM_SUCURSALES > 1 else random.choice(kitchen_names)
        writer.writerow([i, name, i])

#4. ESTACIONES (con nombres y descripciones específicas para cocina)
kitchen_stations = [
    "Estación de Horneado Profesional",
    "Área de Cocción Industrial",
    "Zona de Preparación Fría",
    "Estación de Repostería Avanzada",
    "Área de Fermentación Controlada",
    "Estación de Fritura Industrial",
    "Zona de Elaboración de Pasta",
    "Estación de Ahumado Profesional",
    "Área de Trabajo con Chocolate",
    "Estación de Cocina al Vacío",
    "Zona de Pasteurización",
    "Estación de Heladería Profesional",
    "Área de Corte y Fileteado",
    "Estación de Plancha Grill",
    "Zona de Cocción Lenta",
    "Estación de Elaboración de Pan",
    "Área de Decoración Pastelera",
    "Estación de Cocina Asiática",
    "Zona de Preparación de Sushi",
    "Estación de Catering Profesional"
]

# Descripciones detalladas para cada tipo de estación
station_descriptions = {
    "Estación de Horneado Profesional": "Capacidad para 2 personas. Incluye horno convección 6 bandejas, mesa de acero inoxidable y sistema de extracción potente. Ideal para panadería y repostería.",
    "Área de Cocción Industrial": "Espacio para 3 personas. Equipada con 4 hornillos profesionales, campana extractora industrial y superficie antiadherente. Perfecta para cocina a alta temperatura.",
    "Zona de Preparación Fría": "Capacidad 2 personas. Mesa refrigerada, iluminación LED fría y almacenamiento para ingredientes. Especial para ensamblaje de platos fríos.",
    "Estación de Repostería Avanzada": "Área para 3 reposteros. Cuenta con batidora industrial, mesas de mármol y control de humedad ambiental. Incluye armario de secado.",
    "Área de Fermentación Controlada": "Cabina profesional para 1-2 personas. Control preciso de temperatura (10-40°C) y humedad (60-85%). Ideal para masas y fermentados.",
    "Estación de Fritura Industrial": "Zona para 2 personas. Freidora de 15L con filtrado automático, sistema de extracción reforzado y protección anti-incendios.",
    "Zona de Elaboración de Pasta": "Mesa de trabajo para 2-3 personas. Incluye laminadora, secadero y herramientas profesionales para pasta fresca.",
    "Estación de Ahumado Profesional": "Ahumador de acero inoxidable con control digital. Capacidad para 1 persona. Sistema de extracción especializado.",
    "Área de Trabajo con Chocolate": "Mesa de mármol temperado para 2 personas. Control de temperatura ambiente (18-20°C) y humedad (<50%).",
    "Estación de Cocina al Vacío": "Equipada con 3 baños termostáticos y envasadora al vacío. Espacio para 2 personas. Incluye tabla de programación.",
    "Zona de Pasteurización": "Área con equipos de tratamiento térmico controlado. Capacidad para procesamiento de 50L/h. 1-2 operarios.",
    "Estación de Heladería Profesional": "Máquina de helado profesional batch freezer, pasteurizador y abatidor de temperatura. Para 2 especialistas.",
    "Área de Corte y Fileteado": "Mesa de trabajo refrigerada con herramientas profesionales. Capacidad 1 persona. Incluye balanza de precisión.",
    "Estación de Plancha Grill": "Superficie de cocción de 1m² para 2 personas. Control de zonas de calor independientes. Extracción reforzada.",
    "Zona de Cocción Lenta": "Equipada con marmitas y ollas de cocción lenta. Capacidad para 3 personas. Sistema de regulación precisa.",
    "Estación de Elaboración de Pan": "Amasadora de 20L, fermentadora y horno de piedra. Espacio para 2 panaderos. Superficies antiadherentes.",
    "Área de Decoración Pastelera": "Mesa de trabajo con iluminación especial. Capacidad 1-2 personas. Incluye torreta giratoria y herramientas de decoración.",
    "Estación de Cocina Asiática": "Wok profesional con quemador de alta potencia. Espacio para 2 chefs. Incluye zona de preparación específica.",
    "Zona de Preparación de Sushi": "Mesa refrigerada para arroz, área de corte específica. Capacidad 1-2 sushiman. Iluminación especial.",
    "Estación de Catering Profesional": "Área multifunción para 4 personas. Equipada para emplatado, montaje y envasado profesional."
}

with open("estaciones.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["estacion_id", "estacion_name", "description", "sucursal_id"])

    for i in range(1, NUM_ESTACIONES + 1):
        station_name = random.choice(kitchen_stations)
        description = station_descriptions.get(station_name, "Estación profesional equipada")

        # Añadir características adicionales aleatorias
        features = [
            " | Certificación sanitaria",
            " | Sistema de seguridad alimentaria",
            " | Iluminación profesional 5000K",
            " | Conexión agua directa",
            " | Tomas eléctricas reforzadas",
            " | Superficie antiadherente",
            " | Control digital de parámetros",
            " | Materiales aptos para contacto alimentario",
            " | Sistema de emergencia incorporado",
            " | Ventilación industrial certificada"
        ]

        # Añadir 2-3 características extra sin duplicados
        selected_features = random.sample(features, k=random.randint(2, 3))
        full_description = description + "".join(selected_features)

        writer.writerow([
            i,
            f"{station_name} #{i}",
            full_description,
            random.randint(1, NUM_SUCURSALES)
        ])



# 5. USERS (nombres de negocios de comida)
def generate_kitchen_business_name(business_type):
    prefixes = ["El", "La", "Los", "Las", "Del", "Mi"]
    suffixes = ["Casera", "Gourmet", "Artisanal", "Express", "Premium", "Original"]
    name = faker.last_name()

    if random.random() > 0.5:
        return f"{random.choice(prefixes)} {name} {business_type}"
    else:
        return f"{business_type} {random.choice(suffixes)}"

with open("users.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["user_id", "first_name", "last_name", "business_name", "creation_date", "email", "phone_number", "business_type"])
    for i in range(1, NUM_USERS + 1):
        business_type_id = random.randint(1, len(kitchen_business_types))
        business_type_name = kitchen_business_types[business_type_id - 1]
        business_name = generate_kitchen_business_name(business_type_name)

        writer.writerow([
            i,
            faker.first_name(),
            faker.last_name(),
            business_name[:50],
            faker.date_between(start_date='-3y', end_date='today'),
            faker.email(),
            faker.phone_number(),
            business_type_id
        ])

# 6. RESERVAS (adaptado para cocinas)
with open("reservas.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["reserva_id", "user_id", "estacion_id", "start_date", "finish_date", "state", "reserva_type"])
    for i in range(1, NUM_RESERVAS + 1):
        tipo = random.choice(['hora', 'jornada', 'semana', 'mes'])
        duraciones = {'hora': 1, 'jornada': 8, 'semana': 40, 'mes': 160}
        start = faker.date_time_between(start_date='-6m', end_date='+6m')
        finish = start + timedelta(hours=duraciones[tipo])

        writer.writerow([
            i,
            random.randint(1, NUM_USERS),
            random.randint(1, NUM_ESTACIONES),
            start,
            finish,
            random.choice(['activa', 'finalizada', 'cancelada']),
            tipo
        ])

# 7. PAGOS (métodos comunes para negocios de comida)
with open("payments.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["payment_id", "user_id", "reserva_id", "payment_date", "amount", "payment_method"])
    for i in range(1, NUM_PAGOS + 1):
        writer.writerow([
            i,
            random.randint(1, NUM_USERS),
            i,
            faker.date_time_between(start_date='-6m', end_date='now'),
            round(random.uniform(50, 500), 2),  # Precios más realistas para cocinas
            random.choice(['efectivo', 'tarjeta', 'transferencia', 'bizum'])
        ])

# 8. RESERVAS SALÓN DE TALLERES (para eventos culinarios)
event_types = [
    "Taller de Repostería", "Clase de Cocina", "Degustación",
    "Presentación de Producto", "Team Building Culinario", "Show Cooking"
]
with open("reservas_salon_talleres.csv", "w", newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["reserva_salon_id", "user_id", "sucursal_id", "start_date", "finish_date", "hours", "description"])
    for i in range(1, NUM_RESERVAS_SALON + 1):
        start = faker.date_time_between(start_date='-3m', end_date='+3m')
        hours = random.choice([2, 4, 6, 8])  # Duración típica de talleres
        finish = start + timedelta(hours=hours)

        writer.writerow([
            i,
            random.randint(1, NUM_USERS),
            random.randint(1, NUM_SUCURSALES),
            start,
            finish,
            hours,
            f"{random.choice(event_types)}: {faker.sentence(nb_words=8)}"
        ])

print("Datos generados exitosamente para coworking de cocinas!")
