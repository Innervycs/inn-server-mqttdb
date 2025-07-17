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

echo "Creando usuario $TS_USER y base de datos $TS_DB si no existen..."
set -x  # <-- Esto muestra los comandos que se ejecutan a partir de aquí

sudo -u postgres psql -v ON_ERROR_STOP=1 \
  -v dbuser="$TS_USER" \
  -v dbpass="$TS_PASS" \
  -v dbname="$TS_DB" <<'EOF'
DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user WHERE usename = :'dbuser'
   ) THEN
      RAISE NOTICE 'Creando usuario %', :'dbuser';
      EXECUTE format('CREATE USER %I WITH PASSWORD %L', :'dbuser', :'dbpass');
   ELSE
      RAISE NOTICE 'Usuario % ya existe', :'dbuser';
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_database WHERE datname = :'dbname'
   ) THEN
      RAISE NOTICE 'Creando base de datos %', :'dbname';
      EXECUTE format('CREATE DATABASE %I OWNER %I', :'dbname', :'dbuser');
   ELSE
      RAISE NOTICE 'Base de datos % ya existe', :'dbname';
   END IF;
END
$$;
EOF

# Asegurar extensión timescaledb en la DB
psql "postgresql://$TS_USER:$TS_PASS@$TS_HOST:$TS_PORT/$TS_DB" \
     -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

psql "postgresql://$TS_USER:$TS_PASS@$TS_HOST:$TS_PORT/$TS_DB" \
     -f "$(dirname "$0")/../db/schema.sql"



