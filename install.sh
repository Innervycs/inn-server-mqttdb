#!/usr/bin/env bash
# One‑shot installer for Ubuntu 24.04.
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash install.sh" >&2
  exit 1
fi

# ───────────────────────────────────────
# 0. Load environment variables
if [[ ! -f .env ]]; then
  echo "❌  .env not found.  Copy .env.sample to .env and edit your secrets first." >&2
  exit 1
fi
set -a; source .env; set +a

# 1. Base system update
apt update && apt -y upgrade
apt install -y curl gnupg lsb-release software-properties-common python3-venv python3-pip nginx

# 2. Install & configure Mosquitto + TimescaleDB
chmod +x scripts/*.sh
scripts/setup_mosquitto.sh
scripts/setup_timescale.sh

# 3. Python virtual‑env for the bridge
python3 -m venv /opt/mqtt2ts-env
/opt/mqtt2ts-env/bin/pip install -r requirements.txt

# 4. Install bridge as a systemd service
install -m 644 systemd/mqtt_to_timescale.service /etc/systemd/system/
sed -i "s|<REPO_PATH>|$(pwd)|" /etc/systemd/system/mqtt_to_timescale.service
systemctl daemon-reload
systemctl enable --now mqtt_to_timescale.service

# 5. Nginx reverse‑proxy
install -m 644 config/nginx.conf /etc/nginx/sites-available/iot-stack.conf
ln -sf /etc/nginx/sites-available/iot-stack.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

printf "\n✅  All components installed and running.\n"