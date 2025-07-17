DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user WHERE usename = 'iot'
   ) THEN
      RAISE NOTICE 'Creando usuario iot';
      CREATE USER iot WITH PASSWORD 'secret';
   ELSE
      RAISE NOTICE 'Usuario iot ya existe';
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_database WHERE datname = 'iot'
   ) THEN
      RAISE NOTICE 'Creando base de datos iot';
      CREATE DATABASE iot OWNER iot;
   ELSE
      RAISE NOTICE 'Base de datos iot ya existe';
   END IF;
END
$$;