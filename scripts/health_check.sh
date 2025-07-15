#!/usr/bin/env bash
set -euo pipefail
source .env

fail() { echo "❌ $1"; exit 1; }

# MQTT round‑trip
mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" -t health/test -m '{"probe":true}' || fail "Broker no responde (pub)"
mosquitto_sub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" -C 1 -t health/test >/dev/null || fail "Broker no responde (sub)"

echo "✓ MQTT broker ok"

# DB check
PGPASSWORD="$TS_PASS" psql -h "$TS_HOST" -U "$TS_USER" -d "$TS_DB" -c "SELECT 1" >/dev/null || fail "Timescale no responde"

echo "✓ TimescaleDB ok"

# Port listening
ss -tln | grep -q ":1883 " || fail "Puerto 1883 no está escuchando"
ss -tln | grep -q ":5432 " || fail "Puerto 5432 no está escuchando"

echo "✓ Puertos abiertos"

echo "✅ Health‑check completado con éxito"