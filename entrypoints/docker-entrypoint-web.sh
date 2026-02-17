#!/bin/bash
set -e

echo "Waiting for services..."

# Wait for Redis
if [ -n "$REDIS_HOST" ]; then
  echo "Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT:-6379}..."
  if ! uv run python entrypoints/wait_for_service.py --service $REDIS_HOST:${REDIS_PORT:-6379}; then
    echo "Redis connection failed"
    exit 1
  fi
  echo "Redis is ready!"
fi

# Wait for PostgreSQL
if [ -n "$DATABASE_URL" ] || [ -n "$POSTGRES_HOST" ]; then
  echo "Waiting for PostgreSQL..."
  POSTGRES_PORT=${POSTGRES_PORT:-5433}
  if [ -n "$DATABASE_URL" ]; then
    # Extract host and port from DATABASE_URL
    DB_HOST=$(echo $DATABASE_URL | sed -E 's|.*@([^:]+):.*|\1|')
    DB_PORT=$(echo $DATABASE_URL | sed -E 's|.*:([0-9]+)/.*|\1|')
    if ! uv run python entrypoints/wait_for_service.py --service $DB_HOST:$DB_PORT; then
      echo "PostgreSQL connection failed"
      exit 1
    fi
  elif [ -n "$POSTGRES_HOST" ]; then
    if ! uv run python entrypoints/wait_for_service.py --service $POSTGRES_HOST:$POSTGRES_PORT; then
      echo "PostgreSQL connection failed"
      exit 1
    fi
  fi
  echo "PostgreSQL is ready!"
fi

echo "All services are ready!"

# Collect static files
echo "Collecting static files..."
uv run python manage.py collectstatic --noinput || echo "Warning: Static files collection failed, continuing..."

# Apply database migrations
echo "Applying database migrations..."
uv run python manage.py migrate || echo "Warning: Migrations failed, continuing..."

# Start server
echo "Starting server on port ${PORT:-8000}..."
exec uv run uvicorn flight_blender.asgi:application --host 0.0.0.0 --port ${PORT:-8000} --workers 3
