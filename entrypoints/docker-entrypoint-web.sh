#!/bin/bash
set -e

echo "Waiting for services..."

# Wait for Redis
if [ -n "$REDIS_HOST" ]; then
  echo "Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT:-6379}..."
  until python -c "
import redis
import sys
try:
    r = redis.Redis(
        host='${REDIS_HOST}',
        port=${REDIS_PORT:-6379},
        password='${REDIS_PASSWORD:-}' if '${REDIS_PASSWORD:-}' else None,
        decode_responses=True,
        socket_connect_timeout=5
    )
    r.ping()
    print('Redis is ready!')
except Exception as e:
    sys.exit(1)
" 2>/dev/null; do
    echo "Waiting for Redis..."
    sleep 2
  done
  echo "Redis is ready!"
fi

# Wait for PostgreSQL
if [ -n "$DATABASE_URL" ] || [ -n "$POSTGRES_HOST" ]; then
  echo "Waiting for PostgreSQL..."
  until python -c "
import sys
try:
    if '${DATABASE_URL}':
        import psycopg2
        from urllib.parse import urlparse
        conn = psycopg2.connect('${DATABASE_URL}')
        conn.close()
        print('PostgreSQL is ready!')
    elif '${POSTGRES_HOST}':
        import psycopg2
        conn = psycopg2.connect(
            host='${POSTGRES_HOST}',
            port=${POSTGRES_PORT:-5432},
            user='${POSTGRES_USER}',
            password='${POSTGRES_PASSWORD}',
            dbname='${POSTGRES_DB}',
            connect_timeout=5
        )
        conn.close()
        print('PostgreSQL is ready!')
except Exception as e:
    sys.exit(1)
" 2>/dev/null; do
    echo "Waiting for PostgreSQL..."
    sleep 2
  done
  echo "PostgreSQL is ready!"
fi

echo "All services are ready!"

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput || echo "Warning: Static files collection failed, continuing..."

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate || echo "Warning: Migrations failed, continuing..."

# Start server
echo "Starting server on port ${PORT:-8000}..."
exec uvicorn flight_blender.asgi:application --host 0.0.0.0 --port ${PORT:-8000} --workers 3
