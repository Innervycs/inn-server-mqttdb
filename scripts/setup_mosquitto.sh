#!/usr/bin/env bash
set -euo pipefail

apt install -y mosquitto mosquitto-clients   # from Ubuntu 24.04 repos

# Credentials
mosquitto_passwd -b -c /etc/mosquitto/passwd "$MQTT_USER" "$MQTT_PASS"

# Config file
install -m 644 config/mosquitto.conf /etc/mosquitto/conf.d/iot.conf

systemctl enable --now mosquitto