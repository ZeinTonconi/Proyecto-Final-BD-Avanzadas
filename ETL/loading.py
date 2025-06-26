import psycopg2
from sqlalchemy import create_engine, text
import pandas as pd
from pymongo import MongoClient

# 🔌 Connections
ORIGINAL_PG_URI = "postgresql://admin:admin@localhost:5432/cowork"
NEW_PG_URI      = "postgresql://admin:admin@localhost:5432/cowork_snowflake"
MONGO_URI       = "mongodb://admin:secret@localhost:27017"
MONGO_DB        = "cowork_fase2"


def create_new_postgres_db():
    conn = psycopg2.connect(
        dbname="cowork",
        user="admin",
        password="admin",
        host="localhost",
        port="5432"
    )
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("DROP DATABASE IF EXISTS cowork_snowflake")
    cur.execute("CREATE DATABASE cowork_snowflake")
    cur.close()
    conn.close()
    print("✅ Database cowork_snowflake created.")


def extract_data():
    engine_old = create_engine(ORIGINAL_PG_URI)

    reservations  = pd.read_sql("SELECT * FROM reservations", engine_old)
    users         = pd.read_sql("SELECT * FROM users", engine_old)
    branches      = pd.read_sql("SELECT * FROM branches", engine_old)
    directions    = pd.read_sql("SELECT * FROM directions", engine_old)
    business_type = pd.read_sql("SELECT * FROM business_type", engine_old)
    stations      = pd.read_sql("SELECT station_id, branches_id FROM stations", engine_old)

    mongo        = MongoClient(MONGO_URI)[MONGO_DB]
    raw_payments = pd.DataFrame(mongo["payment_type"].find())

    return reservations, users, branches, directions, business_type, stations, raw_payments


def clean_transform(reservations, users, branches, directions,
                    business_type, stations, raw_payments):
    # reservation base
    fact = reservations.copy()
    fact["start_date"]  = pd.to_datetime(fact["start_date"])
    fact["finish_date"] = pd.to_datetime(fact["finish_date"])
    fact = fact[fact["finish_date"] > fact["start_date"]].copy()
    fact["duration_hours"] = (
        fact["finish_date"] - fact["start_date"]
    ).dt.total_seconds() / 3600

    # join branch_id via station
    fact = fact.merge(
        stations.rename(columns={"branches_id": "branch_id"}),
        on="station_id", how="left"
    )

    # extract payment dim
    raw_payments["payment_id"]     = raw_payments["_id"].astype(str)
    raw_payments["method"]         = raw_payments["payment_info"].map(lambda x: x.get("method"))
    raw_payments["status"]         = raw_payments["payment_info"].map(lambda x: x.get("status"))
    raw_payments["payment_amount"] = raw_payments["payment_info"].map(lambda x: x.get("amount", 0))
    # dim_payment table
    dim_payment = raw_payments[["payment_id","method","status","reservation_id","payment_amount"]]

    # merge payment_id and amount into fact
    fact = fact.merge(
        dim_payment[["reservation_id","payment_id","payment_amount"]],
        on="reservation_id", how="left"
    ).fillna({"payment_amount": 0})

    return fact, users, branches, directions, business_type, dim_payment


def load_to_new_db(fact, users, branches, directions, business_type, dim_payment):
    engine_new = create_engine(NEW_PG_URI)

    with engine_new.begin() as conn:
        conn.execute(text("""
            -- Dimensions
            CREATE TABLE dim_business_type (
                business_type_id INTEGER PRIMARY KEY,
                type_name       VARCHAR
            );

            CREATE TABLE dim_direction (
                direction_id INTEGER PRIMARY KEY,
                city         VARCHAR,
                street_name  VARCHAR,
                number       INTEGER
            );

            CREATE TABLE dim_branch (
                branch_id    INTEGER PRIMARY KEY,
                branch_name  VARCHAR,
                direction_id INTEGER,
                FOREIGN KEY(direction_id) REFERENCES dim_direction(direction_id)
            );

            CREATE TABLE dim_user (
                user_id          INTEGER PRIMARY KEY,
                first_name       VARCHAR,
                last_name        VARCHAR,
                business_type_id INTEGER,
                FOREIGN KEY(business_type_id) REFERENCES dim_business_type(business_type_id)
            );

            CREATE TABLE dim_time (
                time_id     TIMESTAMP PRIMARY KEY,
                date        DATE,
                hour_of_day INTEGER,
                day_of_week VARCHAR,
                month       INTEGER,
                year        INTEGER
            );

            CREATE TABLE dim_payment (
                payment_id  VARCHAR PRIMARY KEY,
                method      VARCHAR,
                status      VARCHAR
            );

            -- Fact table
            CREATE TABLE reservation_fact (
                reservation_id INTEGER PRIMARY KEY,
                user_id        INTEGER,
                branch_id      INTEGER,
                time_id        TIMESTAMP,
                payment_id     VARCHAR,
                duration_hours NUMERIC,
                payment_amount NUMERIC,
                FOREIGN KEY(user_id) REFERENCES dim_user(user_id),
                FOREIGN KEY(branch_id) REFERENCES dim_branch(branch_id),
                FOREIGN KEY(time_id) REFERENCES dim_time(time_id),
                FOREIGN KEY(payment_id) REFERENCES dim_payment(payment_id)
            );
        """))

    # ... load dims
    business_type.rename(columns={"type_id": "business_type_id"}) \
                 .to_sql("dim_business_type", engine_new, index=False, if_exists="append")
    directions.rename(columns={"directions_id": "direction_id"}) \
              .to_sql("dim_direction", engine_new, index=False, if_exists="append")
    branches.rename(columns={"id_direction": "direction_id"}) \
            .to_sql("dim_branch", engine_new, index=False, if_exists="append")
    users.loc[:, ["user_id","first_name","last_name","business_type"]] \
         .rename(columns={"business_type":"business_type_id"}) \
         .to_sql("dim_user", engine_new, index=False, if_exists="append")

    # load dim_time
    dim_time = fact[["start_date"]].drop_duplicates() \
                .rename(columns={"start_date":"time_id"})
    dim_time["date"]        = dim_time.time_id.dt.date
    dim_time["hour_of_day"] = dim_time.time_id.dt.hour
    dim_time["day_of_week"] = dim_time.time_id.dt.day_name()
    dim_time["month"]       = dim_time.time_id.dt.month
    dim_time["year"]        = dim_time.time_id.dt.year
    dim_time.to_sql("dim_time", engine_new, index=False, if_exists="append")

    # load dim_payment
    dim_payment[["payment_id","method","status"]] \
               .drop_duplicates(subset=["payment_id"]) \
               .to_sql("dim_payment", engine_new, index=False, if_exists="append")

    # load fact
    fp = fact.rename(columns={"start_date": "time_id"})[[
        "reservation_id","user_id","branch_id","time_id",
        "payment_id","duration_hours","payment_amount"
    ]]
    fp.to_sql("reservation_fact", engine_new, index=False, if_exists="append")

    print("✅ ETL with payment dim and FK complete.")


if __name__ == "__main__":
    create_new_postgres_db()
    res, u, b, d, bt, st, rp = extract_data()
    fact, u, b, d, bt, dp    = clean_transform(res, u, b, d, bt, st, rp)
    load_to_new_db(fact, u, b, d, bt, dp)
