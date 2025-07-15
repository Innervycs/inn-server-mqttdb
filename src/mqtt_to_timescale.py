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
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "sensors/#")
MQTT_USER = os.getenv("MQTT_USER")
MQTT_PASS = os.getenv("MQTT_PASS")

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

INSERT_SQL = """
INSERT INTO sensor_data (time, topic, payload)
VALUES (%s, %s, %s);
"""

def insert_message(topic: str, payload_raw: bytes):
    try:
        payload = json.loads(payload_raw.decode())
    except json.JSONDecodeError:
        payload = {"raw": payload_raw.decode(errors="replace")}
    cur.execute(INSERT_SQL, (datetime.utcnow(), topic, json.dumps(payload)))

# ─────────────────────────────────────── MQTT callbacks

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        logging.info("MQTT connected — subscribing to %s", MQTT_TOPIC)
        client.subscribe(MQTT_TOPIC)
    else:
        logging.error("MQTT connection failed with code %s", rc)

def on_message(client, userdata, msg):
    insert_message(msg.topic, msg.payload)

# ─────────────────────────────────────── Main
client = mqtt.Client(clean_session=True, protocol=mqtt.MQTTv5)
client.username_pw_set(MQTT_USER, MQTT_PASS)
client.on_connect = on_connect
client.on_message = on_message
client.connect(MQTT_HOST, MQTT_PORT)

# Graceful shutdown
for sig in (signal.SIGINT, signal.SIGTERM):
    signal.signal(sig, lambda *args: (client.disconnect(), conn.close(), sys.exit(0)))

client.loop_forever()