-- Add your custom schema tweaks here
-- Extensión Timescale (si aún no existe)
CREATE EXTENSION IF NOT EXISTS timescaledb;

----------------------------------------------------------------
--  Tabla 1  ·  sensor_readings  (topic: up_data_sensors)
----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensor_readings (
    id               SERIAL PRIMARY KEY,
    datetime_input   TIMESTAMPTZ NOT NULL DEFAULT now(),   -- fecha/hora de inserción
    ts_payload       TIMESTAMPTZ,                          -- timestamp dentro del paquete
    device           TEXT NOT NULL,                        -- MAC o identificador
    cap_lvl15        DOUBLE PRECISION,
    cap_lvl25        DOUBLE PRECISION,
    cap_lvl35        DOUBLE PRECISION,
    temp_lvl15       DOUBLE PRECISION,
    temp_lvl25       DOUBLE PRECISION,
    temp_lvl35       DOUBLE PRECISION,
    weight           DOUBLE PRECISION
);
-- convertir en hypertable por la columna datetime_input
SELECT create_hypertable('sensor_readings','datetime_input',if_not_exists=>TRUE);

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
    id             SERIAL PRIMARY KEY,
    datetime_input TIMESTAMPTZ NOT NULL DEFAULT now(),
    ts_payload     TIMESTAMPTZ,
    ambient_temp   DOUBLE PRECISION,
    ambient_hum    DOUBLE PRECISION
);
SELECT create_hypertable('env_readings','datetime_input',if_not_exists=>TRUE);

