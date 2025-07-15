# LeLfunko Server — MQTT + TimescaleDB + Nginx

Repositorio que automatiza el despliegue completo de un _backend_ IoT en **Ubuntu 24.04**. Incluye:

- **Mosquitto** → broker MQTT.  
- **TimescaleDB** → base de datos de series temporales.  
- **Nginx** → servidor inverso (reverse-proxy).  
- **Archivos de configuración** y _scripts_ de instalación.

> **Requisito previo** Habilita **SSH** en el servidor si trabajarás de forma remota:
> ```bash
> sudo apt install openssh-server
> sudo systemctl enable --now ssh
> ```

---

## Instalación paso a paso

### 1 · Instalar Git
```bash
sudo apt update && sudo apt install git
```

### 2 · Crear un workspace
```bash
mkdir ~/server-workspace
cd ~/server-workspace
```

### 3 · Clonar el repositorio
```bash
git clone https://github.com/Innervycs/inn-server-mqttdb.git
```

### 4 · Configurar variables de entorno
```bash
cd inn-server-mqttdb
cp .env.sample .env   # edita credenciales a tu gusto
```

### 5 · Ejecutar el instalador
```bash
sudo bash install.sh
```

### 6 · Abrir puertos en UFW
```bash
# 1 — Reglas esenciales
sudo ufw allow OpenSSH        # o sudo ufw limit 22/tcp
sudo ufw allow 1883/tcp       # MQTT

# 2 — Si UFW estaba inactivo
sudo ufw enable

# 3 — Comprobar reglas
sudo ufw status numbered
```

---

## Verificación de servicios

| Servicio | Comando para habilitar (el instalador ya lo hace) | Verificar estado |
|----------|---------------------------------------------------|------------------|
| **Mosquitto** | `systemctl enable --now mosquitto` | `systemctl status mosquitto` |
| **TimescaleDB / PostgreSQL** | `systemctl enable --now postgresql` | `systemctl status postgresql` |
| **Bridge MQTT → Timescale** | `systemctl enable --now mqtt_to_timescale.service` | `systemctl status mqtt_to_timescale` |
| **Nginx** | `systemctl reload nginx` | `systemctl status nginx` |

### Reiniciar servicios manualmente
```bash
sudo systemctl restart mosquitto
sudo systemctl restart postgresql
sudo systemctl restart mqtt_to_timescale
sudo systemctl restart nginx
```

---

## Chequeo rápido de salud

Se incluye un script automatizado:
```bash
./scripts/health_check.sh
```

Este comprueba:
1. Publicación/suscripción MQTT.
2. Conexión SQL a TimescaleDB.
3. Puertos 1883 y 5432 escuchando.

---

¡Con esto tu **LeLfunko Server** estará listo para recibir datos de tus dispositivos ESP32 y almacenarlos de forma segura! 🚀
