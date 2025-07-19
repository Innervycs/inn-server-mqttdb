#!/usr/bin/env bash

# •	sudo bash install.sh all → ejecuta todo el proceso completo.
#	•	sudo bash install.sh section A C E → ejecuta solo los pasos A, C y E.
#	•	sudo bash install.sh --help → muestra la ayuda detallada.

usage() {
  echo "Uso: sudo bash install.sh [all | section A B C | --help]"
  echo
  echo "Opciones:"
  echo "  all             Ejecuta todo el proceso de instalación completo."
  echo "  section A       Actualización sistema base"
  echo "  section B       Instalando y configurando mosquitto "
  echo "  section C       Configurando Timescale"
  echo "  section D       Creando entorno virtual para el puente MQTT -> Timescale"
  echo "  section E       Instalando servicio systemd para el puente"
  echo "  section F       Configurando servidor Nginx como proxy inverso "
  echo "  --help          Muestra esta ayuda."
  exit 0
}

# ───────────────────────────────────────
# Validación de argumentos
if [[ "${1:-}" == "--help" ]]; then
  usage
fi

RUN_ALL=false
RUN_SECTION=()

if [[ $# -eq 0 ]]; then
  usage
elif [[ "$1" == "all" ]]; then
  RUN_ALL=true
elif [[ "$1" == "section" ]]; then
  shift
  RUN_SECTION=("$@")
else
  usage
fi

set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash install.sh" >&2
  exit 1
fi

# ───────────────────────────────────────
# 0. Load environment variables
if [[ ! -f .env ]]; then
  echo ".env not found.  Copy .env.sample to .env and edit your secrets first." >&2
  exit 1
fi
set -a; source .env; set +a

if $RUN_ALL || [[ " ${RUN_SECTION[*]} " =~ " A " ]]; then
  echo "🔧 Paso A: Actualizando sistema base..."
  apt update && apt -y upgrade
  apt install -y curl gnupg lsb-release software-properties-common python3-venv python3-pip nginx
  echo "Paquetes base instalados.\n"
fi

if $RUN_ALL || [[ " ${RUN_SECTION[*]} " =~ " B " ]]; then
  echo "🔧 Paso B: Instalando y configurando Mosquitto..."
  chmod +x scripts/*.sh
  bash scripts/setup_mosquitto.sh
  if [[ $? -ne 0 ]]; then
    echo "❌ Error al instalar/configurar Mosquitto." >&2
    exit 1
  fi
  echo "Mosquitto instalado correctamente.\n"
fi

if $RUN_ALL || [[ " ${RUN_SECTION[*]} " =~ " C " ]]; then
  echo "🔧 Paso C: Configurando TimescaleDB..."
  bash scripts/setup_timescale.sh
  if [[ $? -ne 0 ]]; then
    echo "❌ Error al instalar/configurar TimescaleDB." >&2
    exit 1
  fi
  echo "TimescaleDB configurado correctamente.\n"
fi

if $RUN_ALL || [[ " ${RUN_SECTION[*]} " =~ " D " ]]; then
  echo "🔧 Paso D: Creando entorno virtual para el puente MQTT → Timescale..."
  python3 -m venv /opt/mqtt2ts-env
  /opt/mqtt2ts-env/bin/pip install -r requirements.txt
  echo ll /opt/mqtt2ts-env/
  echo "Entorno virtual instalado y dependencias cargadas.\n"
fi

if $RUN_ALL || [[ " ${RUN_SECTION[*]} " =~ " E " ]]; then
  echo "🔧 Paso E: Instalando servicio systemd para el puente..."
  install -m 644 systemd/mqtt_to_timescale.service /etc/systemd/system/
  sed -i "s|<REPO_PATH>|$(pwd)|" /etc/systemd/system/mqtt_to_timescale.service
  systemctl daemon-reload
  systemctl enable --now mqtt_to_timescale.service
  echo "Servicio mqtt_to_timescale activado correctamente.\n"
  # En caso de fallo del servicio 
  # Verificar sudo systemctl status mqtt_to_timescale.service 
  # journalctl -u mqtt_to_timescale.service -b --no-pager --since "5 minutes ago" 
fi

if $RUN_ALL || [[ " ${RUN_SECTION[*]} " =~ " F " ]]; then
  echo "🔧 Paso F: Configurando servidor Nginx como proxy inverso..."
  install -m 644 config/nginx.conf /etc/nginx/sites-available/iot-stack.conf
  ln -sf /etc/nginx/sites-available/iot-stack.conf /etc/nginx/sites-enabled/
  nginx -t && systemctl reload nginx
  echo "Nginx recargado y configuración aplicada.\n"
fi

printf "\nAll components installed and running.\n"

chmod +x scripts/health_check.sh

echo "Instalación completada."