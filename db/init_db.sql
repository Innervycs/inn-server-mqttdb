# Crear base de datos si no existe
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'iot'" | grep -q 1; then
  echo "Creando base de datos iot..."
  sudo -u postgres createdb -O iot iot
else
  echo "La base de datos iot ya existe"
fi