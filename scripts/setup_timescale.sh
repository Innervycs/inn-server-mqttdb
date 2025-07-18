#!/usr/bin/env bash
set -euo pipefail

set -a
source "$(dirname "$0")/../.env"
set +a
# Atención
# Usa la siguiente linea en el terminal en caso de que sea tu segunda ejecución del script
# Esto permite borrar la base de datos y partir de cero con la ejecución.
# sudo -u postgres psql -c "DROP DATABASE IF EXISTS iot;"

# Add TimescaleDB Apt repo (Ubuntu 24.04 – Noble)
if [[ ! -f /etc/apt/sources.list.d/timescaledb.list ]]; then
  echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" \
    | tee /etc/apt/sources.list.d/timescaledb.list
  curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey | \
    gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg
fi
apt update
apt install -y timescaledb-2-postgresql-16 timescaledb-2-loader-postgresql-16

echo " Auto‑tune "
echo "y" | sudo -u postgres timescaledb-tune --quiet
systemctl enable --now postgresql

echo "Creando usuario $TS_USER y base de datos $TS_DB si no existen..."
set -x  # <-- Esto muestra los comandos que se ejecutan a partir de aquí
sudo -u postgres psql -v ON_ERROR_STOP=1 -f "$(dirname "$0")/../db/init_user.sql"

echo "Creando la base de datos $TS_DB ..."
set -x  # <-- Esto muestra los comandos que se ejecutan a partir de aquí
sudo -u postgres psql -v ON_ERROR_STOP=1 -f "$(dirname "$0")/../db/init_db.sql"

echo "Asegurar extensión timescaledb en la DB"
psql "postgresql://$TS_USER:$TS_PASS@$TS_HOST:$TS_PORT/$TS_DB" \
     -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

echo "Ejecución de schema para creación de tablas"
psql "postgresql://$TS_USER:$TS_PASS@$TS_HOST:$TS_PORT/$TS_DB" \
     -f "$(dirname "$0")/../db/schema.sql"

echo "Fin de la ejecución"


