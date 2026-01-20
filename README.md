# Flight Blender

![blender-logo](images/blender-logo.jpg)

Flight Blender is an open-source backend and data-processing engine designed to support standards-compliant UTM (Unmanned Traffic Management) services. It adheres to the latest regulations for UTM/U-Space in the EU and other jurisdictions. With Flight Blender, you can:

- Implement a Remote ID "service provider" compatible with the ASTM-F3411 Remote ID standard, along with Flight Spotlight, an open-source Remote ID Display Application.
- Use an open-source implementation of the ASTM F3548 USS-to-USS standard, compatible with EU U-Space regulations for flight authorization.
- Interact with interoperability software like `interuss/dss` to exchange data with other UTM systems.
- Process geo-fences using the ED-269 standard.
- Monitor conformance and send operator notifications.
- Aggregate flight traffic feeds from various sources, including geo-fences, flight declarations, and air-traffic data.
- Configure Blender to act as a Surveillance SDSP per the ASTM F3623-23 standard.
- Implement alerts / near misses per the ASTM F3442 standard

## Key Features

### DSS Connectivity
Connect and retrieve data such as Remote ID information or perform strategic de-confliction and flight authorization.

### Flight Tracking
Ingest flight tracking feeds from sources like ADS-B, live telemetry, and Broadcast Remote ID. Outputs a unified JSON feed for real-time display.

### Geofence Management
Submit geofence to Flight Blender, which can then be transmitted to Spotlight for visualization.

### Flight Declaration
Submit future flight plans (up to 24 hours in advance) using the ASTM USS-to-USS API or as a standalone component. Supported DSS APIs are listed below.

### Network Remote ID
Compliant with ASTM standards, this module can act as a "display provider" or "service provider" for Network Remote ID.

### Operator Notifications
Send notifications to operators using an AMQP queue, enabling real-time alerts for flight updates, conformance issues, or other critical events.

### Conformance Monitoring
Monitor flight paths against declared 4D volumes for conformance and report outputs.

### Surveillance SDSP
Blender conforms to the requirements for Surveillance supplemental data service providers (SDSPs) and associated equipment and services.

### Detect, Alert and Avoid
Flight Blender implements the Detect Alert and Avoid standard F3442

## Roadmap

![roadmap](images/oss-roadmap.png)

The image above details a general roadmap to standards compatibility. To monitor activities and track progress effectively, issues are the best way to manage and see the current work. 

---

## ▶️ Get Started in 20 Minutes

Follow our simple 5-step guide to deploy Flight Blender and explore its core features.

📖 [Read the 20-minute quickstart guide](deployment_support/README.md) to get started now!

---

## 🚀 How to Run Flight Blender

### Prerequisites

- **Docker** and **Docker Compose** installed on your system
- **Python 3.12+** (if running locally without Docker)
- **PostgreSQL** (handled by Docker Compose)
- **Redis/Valkey** (handled by Docker Compose)

### Quick Start with Docker (Recommended)

#### 1. Create Environment File

Create a `.env` file in the root directory. You can use the sample from the [deployment guide](deployment_support/README.md) or create one with the following minimum required variables:

```bash
# Django Settings
SECRET_KEY=your-secret-key-here
IS_DEBUG=1
BYPASS_AUTH_TOKEN_VERIFICATION=1
ALLOWED_HOSTS=*

# Database Configuration
POSTGRES_USER=flightblender
POSTGRES_PASSWORD=your-password-here
POSTGRES_DB=flightblender
POSTGRES_HOST=db-blender
DATABASE_URL=postgresql://flightblender:your-password-here@db-blender:5432/flightblender

# Redis Configuration
REDIS_HOST=redis-blender
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
REDIS_BROKER_URL=redis://:your-redis-password@redis-blender:6379/

# Optional: Standalone Mode (set to 0 for standalone, 1 for DSS integration)
USSP_NETWORK_ENABLED=0

# Optional: Heartbeat Rate
HEARTBEAT_RATE_SECS=2
```

**⚠️ Security Note**: The `BYPASS_AUTH_TOKEN_VERIFICATION=1` setting is for local development only. Remove it for production deployments.

#### 2. Build and Run with Docker Compose

For **development** (using `docker-compose-dev.yml`):

```bash
# Build the Docker image
docker build . -t openutm/flight-blender-dev

# Start all services
docker compose -f docker-compose-dev.yml up
```

For **production-like** setup (using `docker-compose.yml`):

**⚠️ Important Production Checklist:**

1. **Update your `.env` file for production:**
   - Remove or set `BYPASS_AUTH_TOKEN_VERIFICATION=0` (security risk if enabled)
   - Set `IS_DEBUG=0`
   - Set `ALLOWED_HOSTS` to your domain name (e.g., `ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com`)
   - Ensure `USE_LOCAL_SQLITE_DATABASE=0` (use PostgreSQL)
   - Set strong passwords for `SECRET_KEY`, `POSTGRES_PASSWORD`, and `REDIS_PASSWORD`

2. **Create the external network (if it doesn't exist):**
```bash
docker network create interop_ecosystem_network
```

3. **Build the production Docker image:**
```bash
docker build . -t openutm/flight-blender
```

4. **Start all services:**
```bash
docker compose up -d  # -d runs in detached mode
```

**Platform Notes:**
- The production `docker-compose.yml` has `platform: linux/amd64` commented out for macOS compatibility
- For production on Linux servers, uncomment the `platform: linux/amd64` lines in `docker-compose.yml`
- For multi-platform builds: `docker buildx build --platform linux/amd64 -t openutm/flight-blender .`

Alternatively, use the provided startup script:

```bash
chmod +x start_flight_blender.sh
./start_flight_blender.sh
```

#### 3. Access the Application

Once the containers are running, access Flight Blender at:

- **Web Interface**: http://localhost:8000
- **API Documentation**: http://localhost:8000/api/docs

You should see the Flight Blender logo and links to the API documentation.

#### 4. Verify Services

The Docker Compose setup includes:
- **flight-blender**: Main Django application (port 8000)
- **db-blender**: PostgreSQL database (port 5432)
- **redis-blender**: Redis/Valkey cache and message broker (port 6379)
- **worker**: Celery worker for background tasks
- **flight-blender-beat**: Celery beat scheduler (in dev mode)

### Running Locally (Without Docker)

If you prefer to run without Docker:

#### 1. Install Dependencies

The project uses `uv` for dependency management:

```bash
# Install uv if not already installed
pip install uv

# Install project dependencies
uv sync
```

#### 2. Set Up Database

Ensure PostgreSQL and Redis are running locally, then update your `.env` file:

```bash
DATABASE_URL=postgresql://user:password@localhost:5432/flightblender
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_BROKER_URL=redis://localhost:6379/
```

#### 3. Run Database Migrations

```bash
python manage.py migrate
```

#### 4. Start the Development Server

```bash
python manage.py runserver
```

#### 5. Start Celery Worker (in separate terminal)

```bash
celery -A flight_blender worker -l info
```

#### 6. Start Celery Beat (optional, in another terminal)

```bash
celery -A flight_blender beat -l info
```

### Troubleshooting

**Issue: Port conflicts**
- Ensure ports 8000, 5432, and 6379 are not in use
- Stop local PostgreSQL/Redis if running: `sudo systemctl stop postgresql`

**Issue: Docker network errors**
- For `docker-compose.yml`, create the network: `docker network create interop_ecosystem_network`
- For `docker-compose-dev.yml`, the network is created automatically

**Issue: Database connection errors**
- Verify PostgreSQL container is running: `docker ps`
- Check `.env` file has correct database credentials
- Ensure database migrations have run

**Issue: Redis connection errors**
- Verify Redis container is running
- Check `REDIS_PASSWORD` matches in `.env` and `redis.conf`

### Next Steps

- Import the [Postman Collection](api/flight_blender_api.postman_collection.json) to test the API
- Generate access tokens using the [verification repository](https://github.com/openutm/verification)
- Explore the [API documentation](http://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/openutm/flight-blender/master/api/flight-blender-server-1.0.0-resolved.yaml)

---
## 💫 Join the community
[Discord](https://discord.gg/dnRxpZdd9a)

---

## Technical Resources and Background Information

- **API Specification**: Explore the [API documentation](http://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/openutm/flight-blender/master/api/flight-blender-server-1.0.0-resolved.yaml) to understand available endpoints and data interactions.
- **Flight Tracking Data**: Review the [Air-traffic Data Protocol](https://github.com/openutm-labs/airtraffic-data-protocol-development/blob/master/Airtraffic-Data-Protocol.md).

---

## Flight Blender Verification
Flight Blender includes a robust verification framework to ensure your deployment operates as expected. Explore the [verification](https://github.com/openutm/verification) repository to use and create verification scenarios. Additionally, Flight Blender is fully compliant with the InterUSS Monitoring test suite.

---

Flight Blender is your gateway to building robust, standards-compliant UTM services. Start exploring today!
