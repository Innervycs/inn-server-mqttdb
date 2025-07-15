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

# Bootstrap DB + hypertable
sudo -u postgres psql <<EOF
CREATE USER $TS_USER WITH PASSWORD '$TS_PASS';
CREATE DATABASE $TS_DB OWNER $TS_USER;
\c $TS_DB
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE TABLE IF NOT EXISTS sensor_data (
    time        TIMESTAMPTZ       NOT NULL,
    topic       TEXT              NOT NULL,
    payload     JSONB
);
SELECT create_hypertable('sensor_data', 'time', if_not_exists => TRUE);
GRANT ALL PRIVILEGES ON TABLE sensor_data TO $TS_USER;
EOF