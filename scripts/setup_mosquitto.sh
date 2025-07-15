#!/usr/bin/env bash
set -euo pipefail

apt install -y mosquitto mosquitto-clients
# Crear directorio de persistencia con permisos adecuados
install -d -m 750 -o mosquitto -g mosquitto /var/lib/mosquitto   # from Ubuntu 24.04 repos

# Credentials
mosquitto_passwd -b -c /etc/mosquitto/passwd "$MQTT_USER" "$MQTT_PASS"
# Ajustar permisos correctos
chown mosquitto: /etc/mosquitto/passwd
chmod 640 /etc/mosquitto/passwd

# Config file
install -m 644 config/mosquitto.conf /etc/mosquitto/conf.d/iot.conf

systemctl enable --now mosquitto