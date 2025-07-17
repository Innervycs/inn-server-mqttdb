-- Crear usuario si no existe
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

-- Crear base de datos si no existe (fuera de DO)
-- Este bloque se ejecutará por separado desde bash