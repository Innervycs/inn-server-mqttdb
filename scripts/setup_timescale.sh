#!/usr/bin/env bash
set -euo pipefail

# Add TimescaleDB Apt repo (Ubuntu 24.04 – Noble)
if [[ ! -f /etc/apt/sources.list.d/timescaledb.list ]]; then
  echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" \
    | tee /etc/apt/sources.list.d/timescaledb.list
  curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey | \
    gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg
fi
apt update
apt install -y timescaledb-2-postgresql-16 timescaledb-2-loader-postgresql-16

# Auto‑tune
yes | timescaledb-tune --quiet
systemctl enable --now postgresql

# Crear usuario y base de datos si no existen
echo "Creando usuario y base de datos si no existen..."
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user WHERE usename = '$TS_USER'
   ) THEN
      CREATE USER $TS_USER WITH PASSWORD '$TS_PASS';
   END IF;
END
\$\$;

DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_database WHERE datname = '$TS_DB'
   ) THEN
      CREATE DATABASE $TS_DB OWNER $TS_USER;
   END IF;
END
\$\$;
EOF

# Asegurar extensión timescaledb en la DB
psql "postgresql://$TS_USER:$TS_PASS@$TS_HOST:$TS_PORT/$TS_DB" \
     -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

psql "postgresql://$TS_USER:$TS_PASS@$TS_HOST:$TS_PORT/$TS_DB" \
     -f "$(dirname "$0")/../db/schema.sql"



