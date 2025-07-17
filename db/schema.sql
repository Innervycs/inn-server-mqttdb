-- Add your custom schema tweaks here
-- Extensión Timescale (si aún no existe)
CREATE EXTENSION IF NOT EXISTS timescaledb;

----------------------------------------------------------------
--  Tabla 1  ·  sensor_readings  (topic: up_data_sensors)
----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensor_readings (
    id               SERIAL,
    datetime_input   TIMESTAMPTZ NOT NULL DEFAULT now(),
    device           TEXT NOT NULL,
    ts_payload       TIMESTAMPTZ,
    cap_lvl15        DOUBLE PRECISION,
    cap_lvl25        DOUBLE PRECISION,
    cap_lvl35        DOUBLE PRECISION,
    temp_lvl15       DOUBLE PRECISION,
    temp_lvl25       DOUBLE PRECISION,
    temp_lvl35       DOUBLE PRECISION,
    weight           DOUBLE PRECISION,
    PRIMARY KEY (id, datetime_input, device)
);
-- convertir en hypertable 
SELECT create_hypertable(
    'sensor_readings',
    'datetime_input',
    chunk_time_interval => interval '3 day',
    partitioning_column => 'device',
    number_partitions => 4,
    if_not_exists => TRUE
);

----------------------------------------------------------------
--  Tabla 2  ·  alert_log  (topic: up_alerts)
----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alert_log (
    id             SERIAL PRIMARY KEY,
    datetime_input TIMESTAMPTZ NOT NULL DEFAULT now(),
    message        TEXT NOT NULL
);

----------------------------------------------------------------
--  Tabla 3  ·  env_readings  (topic: up_env)
----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS env_readings (
    id             SERIAL,
    datetime_input TIMESTAMPTZ NOT NULL DEFAULT now(),
    ts_payload     TIMESTAMPTZ,
    ambient_temp   DOUBLE PRECISION,
    ambient_hum    DOUBLE PRECISION,
    PRIMARY KEY (id, datetime_input)
);
-- convertir en hypertable 
SELECT create_hypertable(
    'env_readings',
    'datetime_input',
    chunk_time_interval => interval '3 day',
    if_not_exists=>TRUE);

