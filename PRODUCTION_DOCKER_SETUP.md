# Running Flight Blender in Production Mode Locally with Docker

This guide will help you run Flight Blender in production mode locally using Docker. The production setup uses `docker-compose.yml` which is configured for production-like environments.

## Prerequisites

- **Docker** (version 20.10 or later)
- **Docker Compose** (version 2.0 or later)
- At least **4GB of RAM** available for Docker
- Ports **8000**, **5432**, and **6379** available on your system

## Step-by-Step Instructions

### 1. Create the External Docker Network

The production Docker Compose setup requires an external network. Create it first:

```bash
docker network create interop_ecosystem_network
```

If the network already exists, you'll see a message indicating that. This is fine - you can proceed.

### 2. Create Environment File (.env)

Create a `.env` file in the root directory of `flight_blender` with the following minimum required variables:

```bash
# Django Settings
SECRET_KEY=your-very-long-random-secret-key-here-minimum-50-characters
IS_DEBUG=0
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Configuration
POSTGRES_USER=flightblender
POSTGRES_PASSWORD=your-secure-password-here
POSTGRES_DB=flightblender
POSTGRES_HOST=db-blender
DATABASE_URL=postgresql://flightblender:your-secure-password-here@db-blender:5432/flightblender

# Redis Configuration
REDIS_HOST=redis-blender
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password-here
REDIS_BROKER_URL=redis://:your-redis-password-here@redis-blender:6379/

# Optional: Standalone Mode (set to 0 for standalone, 1 for DSS integration)
USSP_NETWORK_ENABLED=0

# Optional: Heartbeat Rate
HEARTBEAT_RATE_SECS=2

# Optional: Flight Blender FQDN (for production)
FLIGHTBLENDER_FQDN=http://localhost:8000
```

**⚠️ Important Security Notes:**
- **DO NOT** set `BYPASS_AUTH_TOKEN_VERIFICATION=1` in production mode
- Use strong, unique passwords for `POSTGRES_PASSWORD` and `REDIS_PASSWORD`
- Generate a secure `SECRET_KEY` (you can use: `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"`)

### 3. Build the Docker Image

Build the production Docker image:

```bash
cd /Users/petermunachiali/Documents/Github/SkyTrade/UTM/flight_blender
docker build . -t openutm/flight-blender
```

This will:
- Install system dependencies (gcc, postgresql-client)
- Install Python dependencies using `uv`
- Create a non-root user (django:django)
- Copy application code
- Set up entrypoint scripts

**Note:** The build process may take several minutes on first run as it downloads dependencies.

### 4. Start the Services

Start all services using Docker Compose:

```bash
docker compose up -d
```

Or to see logs in real-time:

```bash
docker compose up
```

This will start the following services:
- **db-blender**: PostgreSQL 17 database
- **redis-blender**: Redis/Valkey cache and message broker
- **flight-blender**: Main Django application (port 8000)
- **flight-blender-celery**: Celery worker for background tasks

### 5. Verify Services are Running

Check that all containers are running:

```bash
docker compose ps
```

You should see all four services with status "Up" or "Up (healthy)".

### 6. Check Application Logs

Monitor the application logs to ensure everything started correctly:

```bash
# View all logs
docker compose logs -f

# View logs for specific service
docker compose logs -f flight-blender
docker compose logs -f flight-blender-celery
```

Look for:
- Database migrations being applied successfully
- Server starting on port 8000
- No error messages

### 7. Access the Application

Once the services are running, access Flight Blender at:

- **Web Interface**: http://localhost:8000
- **API Documentation**: http://localhost:8000/api/docs
- **Health Check**: http://localhost:8000/ping

You should see the Flight Blender logo and links to the API documentation.

### 8. Stop the Services

When you're done, stop all services:

```bash
docker compose down
```

To also remove volumes (this will delete database data):

```bash
docker compose down -v
```

## Production vs Development Differences

The production setup (`docker-compose.yml`) differs from development (`docker-compose-dev.yml`) in several ways:

| Feature | Production | Development |
|---------|-----------|-------------|
| Network | External network required | Internal network |
| Volumes | No code volume mount | Code volume mounted |
| Image name | `openutm/flight-blender` | `openutm/flight-blender-dev` |
| Entrypoint | `no-database/entrypoint.sh` | `with-database/entrypoint.sh` |
| Celery Beat | Not included | Included |
| Database port | Not exposed | Exposed (5432) |

## Troubleshooting

### Issue: Network not found error

**Error:** `network interop_ecosystem_network not found`

**Solution:**
```bash
docker network create interop_ecosystem_network
```

### Issue: Port already in use

**Error:** `Bind for 0.0.0.0:8000 failed: port is already allocated`

**Solution:**
- Check what's using the port: `lsof -i :8000` (macOS/Linux) or `netstat -ano | findstr :8000` (Windows)
- Stop the conflicting service or change the port in `docker-compose.yml`

### Issue: Database connection errors

**Error:** `could not connect to server: Connection refused`

**Solution:**
1. Verify database container is running: `docker compose ps`
2. Check database logs: `docker compose logs db-blender`
3. Ensure `.env` file has correct `POSTGRES_HOST=db-blender`
4. Wait a few seconds for database to fully initialize

### Issue: Redis connection errors

**Error:** `Error connecting to Redis`

**Solution:**
1. Verify Redis container is running: `docker compose ps`
2. Check Redis logs: `docker compose logs redis-blender`
3. Ensure `REDIS_PASSWORD` in `.env` matches the password used in Redis command
4. Verify `REDIS_BROKER_URL` format: `redis://:password@host:port/`

### Issue: Migration errors

**Error:** `django.db.utils.OperationalError`

**Solution:**
1. Ensure database container is fully started (wait 10-15 seconds)
2. Check database logs: `docker compose logs db-blender`
3. Try restarting: `docker compose restart flight-blender`

### Issue: Permission errors

**Error:** `Permission denied` when accessing files

**Solution:**
- The Docker image runs as non-root user (django:django)
- Ensure entrypoint scripts are executable (handled in Dockerfile)
- Check file ownership if using volumes

### Viewing Container Logs

To debug issues, you can view logs for specific services:

```bash
# All services
docker compose logs

# Specific service
docker compose logs flight-blender
docker compose logs db-blender
docker compose logs redis-blender
docker compose logs flight-blender-celery

# Follow logs in real-time
docker compose logs -f flight-blender

# Last 100 lines
docker compose logs --tail=100 flight-blender
```

### Accessing Containers

To access a running container for debugging:

```bash
# Access flight-blender container
docker exec -it flight-blender bash

# Access database container
docker exec -it db-blender psql -U flightblender -d flightblender

# Access Redis container
docker exec -it redis-blender redis-cli -a your-redis-password
```

## Next Steps

Once Flight Blender is running:

1. **Test the API**: Import the [Postman Collection](api/flight_blender_api.postman_collection.json)
2. **Generate Access Tokens**: Use the [verification repository](https://github.com/openutm/verification) to generate tokens
3. **Explore API Documentation**: Visit http://localhost:8000/api/docs
4. **Submit Flight Data**: Use the API to submit flight declarations and other data

## Additional Resources

- [20-minute Quickstart Guide](deployment_support/README.md)
- [Render.com Deployment Guide](RENDER_DEPLOYMENT.md)
- [API Documentation](http://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/openutm/flight-blender/master/api/flight-blender-server-1.0.0-resolved.yaml)
- [Flight Blender Verification](https://github.com/openutm/verification)

## Clean Up

To completely remove all containers, volumes, and networks:

```bash
# Stop and remove containers
docker compose down -v

# Remove the external network (if not used by other services)
docker network rm interop_ecosystem_network

# Remove the Docker image
docker rmi openutm/flight-blender
```
