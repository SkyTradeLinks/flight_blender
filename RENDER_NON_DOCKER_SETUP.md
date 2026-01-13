# Deploying Flight Blender to Render.com (Without Docker)

This guide will walk you through deploying Flight Blender to Render.com using Python buildpacks instead of Docker. This is useful if you prefer native Python deployment or want to avoid Docker overhead.

## Prerequisites

- A GitHub account with your Flight Blender repository
- A Render.com account (free tier available)
- Basic understanding of environment variables

## Overview

Flight Blender requires the following services on Render:
1. **Web Service** - Main Django application (Python)
2. **Background Worker** - Celery worker for async tasks (Python)
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
5. **Important**: Note down the connection string from the dashboard

## Step 2: Create Redis Instance

1. Go to your Render dashboard
2. Click **"New +"** → **"Redis"**
3. Configure:
   - **Name**: `flight-blender-redis` (or your preferred name)
   - **Region**: Same as PostgreSQL
   - **Plan**: Free tier available for testing
4. Click **"Create Redis"**
5. **Important**: Note down the connection details (host, port, password)

## Step 3: Deploy Web Service (Python Buildpack)

1. Go to your Render dashboard
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository:
   - Select your Flight Blender repository
   - Choose the branch (usually `main` or `master`)
4. Configure the service:
   - **Name**: `flight-blender-web` (or your preferred name)
   - **Environment**: `Python 3` (NOT Docker)
   - **Region**: Same as your database
   - **Branch**: `main` (or your default branch)
   - **Root Directory**: Leave empty (or set if app is in subdirectory)
   - **Python Version**: 3.12 (will use `runtime.txt`)
   - **Build Command**: 
     ```bash
     pip install uv && uv sync --frozen --no-dev && python manage.py collectstatic --noinput && python manage.py migrate
     ```
   - **Start Command**: 
     ```bash
     uvicorn flight_blender.asgi:application --host 0.0.0.0 --port $PORT --workers 3
     ```
   - **Plan**: Choose based on your needs (free tier available)

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
REDIS_BROKER_URL=redis://:password@your-redis-host.onrender.com:6379/0

# Application Settings
FLIGHTBLENDER_FQDN=https://your-app-name.onrender.com
HEARTBEAT_RATE_SECS=2

# Network Mode (set to 0 for standalone, 1 for DSS integration)
USSP_NETWORK_ENABLED=0
DSS_SELF_AUDIENCE=your-app-name.onrender.com

# Python Path (important for Python buildpack)
PYTHONPATH=/opt/render/project/src
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

## Step 4: Deploy Background Worker (Celery) - Python Buildpack

1. Go to your Render dashboard
2. Click **"New +"** → **"Background Worker"**
3. Connect the same GitHub repository
4. Configure:
   - **Name**: `flight-blender-worker` (or your preferred name)
   - **Environment**: `Python 3` (NOT Docker)
   - **Region**: Same as web service
   - **Branch**: Same as web service
   - **Root Directory**: Leave empty
   - **Python Version**: 3.12
   - **Build Command**: 
     ```bash
     pip install uv && uv sync --frozen --no-dev
     ```
   - **Start Command**: 
     ```bash
     celery --app=flight_blender worker --loglevel=info
     ```
   - **Plan**: Choose based on your needs

### Environment Variables for Worker

Add the same environment variables as the web service (except `ALLOWED_HOSTS` which is web-only):

- `SECRET_KEY`
- `DATABASE_URL`
- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_PASSWORD`
- `REDIS_BROKER_URL`
- `PYTHONPATH` (set to `/opt/render/project/src`)
- All other variables from the web service

## Step 5: Using render-no-docker.yaml (Alternative Method)

For automated setup, you can use the `render-no-docker.yaml` file:

1. Go to Render dashboard
2. Click **"New +"** → **"Blueprint"**
3. Connect your repository
4. Render will automatically detect and use `render-no-docker.yaml`
5. All services will be created automatically with correct configuration

**Note**: Make sure to use `render-no-docker.yaml` (not `render.yaml`) for non-Docker deployment.

## Step 6: Verify Deployment

1. Visit your web service URL: `https://your-app-name.onrender.com`
2. You should see the Flight Blender logo and API documentation links
3. Test the ping endpoint: `https://your-app-name.onrender.com/ping`
4. Check logs in Render dashboard to ensure no errors

## Key Differences from Docker Deployment

### Build Process
- **Docker**: Uses Dockerfile to build container image
- **Python Buildpack**: Uses `buildCommand` to install dependencies and prepare app

### Start Command
- **Docker**: Uses CMD or entrypoint script from Dockerfile
- **Python Buildpack**: Uses explicit `startCommand` in Render config

### Dependencies
- **Docker**: Installed during Docker build (in Dockerfile)
- **Python Buildpack**: Installed via `buildCommand` on each deploy

### Migrations
- **Docker**: Run in entrypoint script on container start
- **Python Buildpack**: Run in `buildCommand` during build (recommended) or manually via Shell

## Troubleshooting

### Common Issues

1. **Build Fails - uv not found**
   - Ensure build command includes `pip install uv` first
   - Check that `uv` is available in the Python environment

2. **Module Not Found Errors**
   - Verify `PYTHONPATH=/opt/render/project/src` is set
   - Check that all dependencies are in `pyproject.toml`
   - Ensure `uv sync` completes successfully

3. **Database Connection Errors**
   - Verify `DATABASE_URL` is correctly set
   - Ensure PostgreSQL service is running
   - Check that database name, user, and password are correct

4. **Redis Connection Errors**
   - Verify `REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASSWORD` are set
   - Ensure Redis service is running
   - Check `REDIS_BROKER_URL` format: `redis://:password@host:port/0`
   - **SSL/rediss:// URLs**: Render's Redis uses SSL (`rediss://`). The settings automatically add `ssl_cert_reqs=CERT_NONE` to the URL for Celery compatibility

5. **Static Files Not Loading**
   - Verify `collectstatic` runs in build command
   - Check `STATIC_URL` setting in Django settings
   - Ensure static files are being served correctly

6. **Worker Not Processing Tasks / Celery SSL Error**
   - Verify worker service is running
   - Check that `REDIS_BROKER_URL` matches in both web and worker services
   - If you see `ssl_cert_reqs` error with `rediss://` URLs, ensure settings.py includes the SSL fix (automatically adds `ssl_cert_reqs=CERT_NONE`)
   - Review worker logs for errors

7. **Port Binding Issues**
   - Render automatically sets `$PORT` environment variable
   - Ensure start command uses `$PORT` (not hardcoded port)
   - Check that uvicorn is configured correctly

### Checking Logs

- **Web Service**: Dashboard → Your Web Service → "Logs" tab
- **Worker**: Dashboard → Your Worker → "Logs" tab
- **Database**: Dashboard → Your Database → "Logs" tab
- **Redis**: Dashboard → Your Redis → "Logs" tab

### Manual Commands via Shell

To run commands manually:

1. Go to your service in Render dashboard
2. Click on **"Shell"** tab
3. Run commands like:
   ```bash
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py collectstatic
   ```

## Build Command Breakdown

The build command does the following:

```bash
pip install uv && \
uv sync --frozen --no-dev && \
python manage.py collectstatic --noinput && \
python manage.py migrate
```

1. `pip install uv` - Installs the uv package manager
2. `uv sync --frozen --no-dev` - Installs all production dependencies from `uv.lock`
3. `python manage.py collectstatic --noinput` - Collects static files for serving
4. `python manage.py migrate` - Runs database migrations

## Performance Considerations

- **Build Time**: Python buildpack builds are typically faster than Docker builds
- **Cold Starts**: First request may be slower (JIT compilation)
- **Memory**: Monitor memory usage; Python apps can be memory-intensive
- **Scaling**: Can scale horizontally by increasing instance count

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

- [Render Python Documentation](https://render.com/docs/deploy-python)
- [Flight Blender API Documentation](http://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/openutm/flight-blender/master/api/flight-blender-server-1.0.0-resolved.yaml)
- [Flight Blender Quickstart Guide](deployment_support/README.md)
