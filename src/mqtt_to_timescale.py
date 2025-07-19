#!/usr/bin/env python3
"""MQTT → TimescaleDB bridge service."""
import os, json, logging, signal, sys
from datetime import datetime

import psycopg2
from dotenv import load_dotenv
import paho.mqtt.client as mqtt

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

MQTT_HOST = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))
MQTT_USER = os.getenv("MQTT_USER")
MQTT_PASS = os.getenv("MQTT_PASS")

MQTT_TOPIC_DATA_SNS = os.getenv("MQTT_TOPIC_DATA_SNS", "up_data_sensors") 
MQTT_TOPIC_ALERT = os.getenv("MQTT_TOPIC_ALERT", "up_alerts")
MQTT_TOPIC_DATA_ENV = os.getenv("MQTT_TOPIC_DATA_ENV", "up_data_env")

TS_HOST = os.getenv("TS_HOST", "localhost")
TS_PORT = os.getenv("TS_PORT", "5432")
TS_DB   = os.getenv("TS_DB", "iot")
TS_USER = os.getenv("TS_USER", "iot")
TS_PASS = os.getenv("TS_PASS", "secret")

LOGLEVEL = os.getenv("BRIDGE_LOGLEVEL", "INFO").upper()
logging.basicConfig(level=LOGLEVEL, format="[%(asctime)s] %(levelname)s: %(message)s")

# ─────────────────────────────────────── DB helpers
conn = psycopg2.connect(host=TS_HOST, port=TS_PORT, dbname=TS_DB, user=TS_USER, password=TS_PASS)
conn.autocommit = True
cur  = conn.cursor()


TOPIC_TO_SQL = {
    "up_data_sensors": """
        INSERT INTO sensor_readings (
            datetime_input, ts_payload, device,
            cap_lvl15, cap_lvl25, cap_lvl35,
            temp_lvl15, temp_lvl25, temp_lvl35,
            weight
        )
        VALUES (now(), %(ts)s, %(device)s,
                %(cap15)s, %(cap25)s, %(cap35)s,
                %(temp15)s, %(temp25)s, %(temp35)s,
                %(weight)s);
    """,
    "up_alerts": """
        INSERT INTO alert_log (datetime_input, message)
        VALUES (now(), %(msg)s);
    """,
    "up_data_env": """
        INSERT INTO env_readings (
            datetime_input, ts_payload,
            ambient_temp, ambient_hum
        )
        VALUES (now(), %(ts)s, %(temperature)s, %(humidity)s);
    """
}


# ─────────────────────────────────────── MQTT callbacks

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        logging.info("MQTT connected — subscribing to up_data_sensors, up_alerts, up_env")
        client.subscribe(MQTT_TOPIC_DATA_SNS)
        client.subscribe(MQTT_TOPIC_ALERT)
        client.subscribe(MQTT_TOPIC_DATA_ENV)
    else:
        logging.error("MQTT connection failed with code %s", rc)

# def on_message(client, userdata, msg):
#     insert_message(msg.topic, msg.payload)

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
    except json.JSONDecodeError:
        logging.warning("Payload no es JSON: %s", msg.payload)
        return

    sql = TOPIC_TO_SQL.get(msg.topic)
    if not sql:
        logging.info("Tópico ignorado: %s", msg.topic)
        return

    try:
        cur.execute(sql, payload)
    except KeyError as e:
        logging.error("Falta campo en payload: %s — payload: %s", e, payload)
    except Exception as e:
        logging.error("Error al insertar en base de datos: %s", e)

# ─────────────────────────────────────── Main
client = mqtt.Client(protocol=mqtt.MQTTv5)
client.username_pw_set(MQTT_USER, MQTT_PASS)
client.on_connect = on_connect
client.on_message = on_message
client.connect(MQTT_HOST, MQTT_PORT, clean_start=mqtt.MQTT_CLEAN_START_FIRST_ONLY)

# Graceful shutdown
for sig in (signal.SIGINT, signal.SIGTERM):
    signal.signal(sig, lambda *args: (client.disconnect(), conn.close(), sys.exit(0)))

client.loop_forever()