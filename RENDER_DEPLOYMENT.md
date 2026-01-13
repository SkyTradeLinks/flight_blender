# Deploying Flight Blender to Render.com (Docker)

This guide will walk you through deploying Flight Blender to Render.com using Docker, including the web service, background worker (Celery), PostgreSQL database, and Redis instance.

> **Note**: This guide uses Docker for deployment. The Dockerfile and entrypoint scripts are configured to automatically handle service dependencies, migrations, and static file collection.

## Prerequisites

- A GitHub account with your Flight Blender repository
- A Render.com account (free tier available)
- Basic understanding of environment variables and Docker

## Overview

Flight Blender requires the following services on Render:
1. **Web Service** - Main Django application
2. **Background Worker** - Celery worker for async tasks
3. **PostgreSQL Database** - For persistent data storage
4. **Redis** - For caching and Celery message broker

## Step 1: Create PostgreSQL Database

1. Go to your Render dashboard
2. Click **"New +"** → **"PostgreSQL"**
3. Configure:
   - **Name**: `flight-blender-db` (or your preferred name)
   - **Database**: `flight_blender` (or your preferred name)
   - **User**: Auto-generated (or custom)
   - **Region**: Choose closest to your users
   - **PostgreSQL Version**: 17 (or latest)
   - **Plan**: Free tier available for testing
4. Click **"Create Database"**
5. **Important**: Note down the connection string from the dashboard (you'll need it later)

## Step 2: Create Redis Instance

1. Go to your Render dashboard
2. Click **"New +"** → **"Redis"**
3. Configure:
   - **Name**: `flight-blender-redis` (or your preferred name)
   - **Region**: Same as PostgreSQL
   - **Plan**: Free tier available for testing
4. Click **"Create Redis"**
5. **Important**: Note down the connection details (host, port, password)

## Step 3: Deploy Web Service (Docker)

1. Go to your Render dashboard
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository:
   - Select your Flight Blender repository
   - Choose the branch (usually `main` or `master`)
4. Configure the service:
   - **Name**: `flight-blender-web` (or your preferred name)
   - **Environment**: `Docker`
   - **Region**: Same as your database
   - **Branch**: `main` (or your default branch)
   - **Dockerfile Path**: `Dockerfile` (or leave empty if Dockerfile is in root)
   - **Docker Context**: Leave empty (or set if Dockerfile is in subdirectory)
   - **Docker Command**: Leave empty (uses CMD from Dockerfile)
   - **Plan**: Choose based on your needs (free tier available)

   **Note**: The Dockerfile is configured to use the web entrypoint by default. The entrypoint script will:
   - Wait for Redis and PostgreSQL to be ready
   - Collect static files
   - Run database migrations
   - Start the uvicorn server

### Environment Variables for Web Service

Add these environment variables in the Render dashboard under "Environment":

#### Required Variables

```bash
# Django Settings
SECRET_KEY=your-secret-key-here-generate-a-long-random-string
IS_DEBUG=0
ALLOWED_HOSTS=your-app-name.onrender.com,localhost
USE_LOCAL_SQLITE_DATABASE=0

# Database (use the connection string from Step 1)
DATABASE_URL=postgresql://user:password@hostname:5432/database_name

# Redis Configuration (use details from Step 2)
REDIS_HOST=your-redis-host.onrender.com
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
# IMPORTANT: Use 'rediss://' (with double 's') if your Redis requires SSL/TLS
# For CloudClusters or other SSL-enabled Redis, use: rediss://username:password@host:port
REDIS_BROKER_URL=redis://:password@your-redis-host.onrender.com:6379/0
# Example with SSL: REDIS_BROKER_URL=rediss://flight_blender:password@redis-host.com:10023

# Application Settings
FLIGHTBLENDER_FQDN=https://your-app-name.onrender.com
HEARTBEAT_RATE_SECS=2

# Network Mode (set to 0 for standalone, 1 for DSS integration)
USSP_NETWORK_ENABLED=0
DSS_SELF_AUDIENCE=your-app-name.onrender.com
```

#### Optional Variables (for DSS integration)

```bash
# Only needed if USSP_NETWORK_ENABLED=1
AUTH_DSS_CLIENT_ID=your-client-id
AUTH_DSS_CLIENT_SECRET=your-client-secret
DSS_BASE_URL=https://your-dss-url.com
```

#### Security Note

**IMPORTANT**: For production, do NOT set `BYPASS_AUTH_TOKEN_VERIFICATION=1`. This should only be used for local development.

## Step 4: Deploy Background Worker (Celery) - Docker

1. Go to your Render dashboard
2. Click **"New +"** → **"Background Worker"**
3. Connect the same GitHub repository
4. Configure:
   - **Name**: `flight-blender-worker` (or your preferred name)
   - **Environment**: `Docker`
   - **Region**: Same as web service
   - **Branch**: Same as web service
   - **Dockerfile Path**: `Dockerfile` (or leave empty if Dockerfile is in root)
   - **Docker Context**: Leave empty
   - **Docker Command**: `./entrypoints/docker-entrypoint-worker.sh`
   - **Plan**: Choose based on your needs

   **Note**: The worker uses the same Dockerfile but with a different entrypoint command. The entrypoint script will:
   - Wait for Redis to be ready
   - Start the Celery worker

### Environment Variables for Worker

Add the same environment variables as the web service (except `ALLOWED_HOSTS` which is web-only):

- `SECRET_KEY`
- `DATABASE_URL`
- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_PASSWORD`
- `REDIS_BROKER_URL`
- All other variables from the web service

## Step 5: Database Migrations

**Good News**: Database migrations run automatically when the web service starts! The Docker entrypoint script (`docker-entrypoint-web.sh`) includes:
- Automatic migration execution on startup
- Static file collection

If you need to run migrations manually or create a superuser:

1. Go to your web service in Render dashboard
2. Click on **"Shell"** tab
3. Run:
   ```bash
   python manage.py migrate
   ```
4. (Optional) Create a superuser:
   ```bash
   python manage.py createsuperuser
   ```

## Step 6: Verify Deployment

1. Visit your web service URL: `https://your-app-name.onrender.com`
2. You should see the Flight Blender logo and API documentation links
3. Test the ping endpoint: `https://your-app-name.onrender.com/ping`
4. Check logs in Render dashboard to ensure no errors

## Using render.yaml (Alternative Method)

For a more automated setup, you can use a `render.yaml` file. The file is already included in the repository root and configured for Docker deployment:

```yaml
services:
  - type: web
    name: flight-blender-web
    env: docker
    dockerfilePath: Dockerfile
    dockerContext: .
    envVars:
      - key: SECRET_KEY
        generateValue: true
      - key: IS_DEBUG
        value: 0
      - key: USE_LOCAL_SQLITE_DATABASE
        value: 0
      - key: ALLOWED_HOSTS
        fromService:
          type: web
          name: flight-blender-web
          property: host
      - key: DATABASE_URL
        fromDatabase:
          name: flight-blender-db
          property: connectionString
      - key: REDIS_HOST
        fromService:
          type: redis
          name: flight-blender-redis
          property: host
      - key: REDIS_PORT
        fromService:
          type: redis
          name: flight-blender-redis
          property: port
      - key: REDIS_PASSWORD
        fromService:
          type: redis
          name: flight-blender-redis
          property: password
      - key: REDIS_BROKER_URL
        fromService:
          type: redis
          name: flight-blender-redis
          property: connectionString
      - key: FLIGHTBLENDER_FQDN
        fromService:
          type: web
          name: flight-blender-web
          property: host
      - key: HEARTBEAT_RATE_SECS
        value: 2
      - key: USSP_NETWORK_ENABLED
        value: 0

  - type: worker
    name: flight-blender-worker
    env: docker
    dockerfilePath: Dockerfile
    dockerContext: .
    dockerCommand: ./entrypoints/docker-entrypoint-worker.sh
    envVars:
      - key: SECRET_KEY
        fromService:
          type: web
          name: flight-blender-web
          property: envVar
          value: SECRET_KEY
      - key: DATABASE_URL
        fromDatabase:
          name: flight-blender-db
          property: connectionString
      - key: REDIS_HOST
        fromService:
          type: redis
          name: flight-blender-redis
          property: host
      - key: REDIS_PORT
        fromService:
          type: redis
          name: flight-blender-redis
          property: port
      - key: REDIS_PASSWORD
        fromService:
          type: redis
          name: flight-blender-redis
          property: password
      - key: REDIS_BROKER_URL
        fromService:
          type: redis
          name: flight-blender-redis
          property: connectionString

databases:
  - name: flight-blender-db
    databaseName: flight_blender
    user: flight_blender_user
    plan: free

services:
  - type: redis
    name: flight-blender-redis
    plan: free
```

Then deploy via:
1. Go to Render dashboard
2. Click **"New +"** → **"Blueprint"**
3. Connect your repository
4. Render will automatically detect and use `render.yaml`

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Verify `DATABASE_URL` is correctly set
   - Ensure PostgreSQL service is running
   - Check that database name, user, and password are correct

2. **Redis Connection Errors**
   - Verify `REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASSWORD` are set
   - Ensure Redis service is running
   - Check `REDIS_BROKER_URL` format: `redis://:password@host:port/0`
   - **If using SSL/TLS**: Use `rediss://` (with double 's') instead of `redis://`
   - **For CloudClusters or non-standard ports**: The entrypoint script will auto-detect SSL requirement
   - Check logs for "Detected SSL requirement" message
   - If connection keeps failing, verify your Redis provider requires SSL and update `REDIS_BROKER_URL` accordingly

3. **Static Files Not Loading**
   - Static files are automatically collected by the Docker entrypoint script
   - Check logs to see if `collectstatic` ran successfully
   - Check `STATIC_URL` setting in `settings.py`
   - For Docker: Ensure the entrypoint script has proper permissions

4. **Worker Not Processing Tasks**
   - Verify worker service is running
   - Check that `REDIS_BROKER_URL` matches in both web and worker services
   - Review worker logs for errors

5. **Application Crashes on Startup**
   - Check logs in Render dashboard
   - Verify all required environment variables are set
   - Ensure migrations have run (they run automatically in Docker)
   - For Docker: Check that entrypoint scripts are executable (`chmod +x entrypoints/docker-entrypoint-*.sh`)
   - Verify Docker image builds successfully

6. **Docker-Specific Issues**
   - **Build fails**: Check Dockerfile syntax and ensure all dependencies are listed in `pyproject.toml`
   - **Entrypoint script not found**: Ensure scripts are in `entrypoints/` directory and are executable
   - **Port binding errors**: Render automatically sets `$PORT` environment variable - ensure your app uses it
   - **Service wait timeouts**: Entrypoint scripts wait for Redis/PostgreSQL with 5-second timeouts - increase if services are slow to start

### Checking Logs

- **Web Service**: Dashboard → Your Web Service → "Logs" tab
- **Worker**: Dashboard → Your Worker → "Logs" tab
- **Database**: Dashboard → Your Database → "Logs" tab
- **Redis**: Dashboard → Your Redis → "Logs" tab

## Security Best Practices

1. **Never commit secrets**: Use Render's environment variables
2. **Use strong SECRET_KEY**: Generate a long random string
3. **Set IS_DEBUG=0**: For production deployments
4. **Configure ALLOWED_HOSTS**: Set to your actual domain
5. **Remove BYPASS_AUTH_TOKEN_VERIFICATION**: Never use in production
6. **Use HTTPS**: Render provides this automatically
7. **Regular updates**: Keep dependencies updated

## Scaling

Render allows you to scale services:
- **Web Service**: Scale horizontally by increasing instance count
- **Worker**: Scale workers based on task volume
- **Database**: Upgrade plan for better performance
- **Redis**: Upgrade plan for larger cache/message queue

## Next Steps

After deployment:
1. Set up custom domain (optional)
2. Configure Flight Passport for OAuth (production)
3. Set up monitoring and alerts
4. Configure backups for PostgreSQL
5. Review and optimize performance

## Additional Resources

- [Render Documentation](https://render.com/docs)
- [Flight Blender API Documentation](http://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/openutm/flight-blender/master/api/flight-blender-server-1.0.0-resolved.yaml)
- [Flight Blender Quickstart Guide](deployment_support/README.md)
