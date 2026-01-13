#!/bin/bash
set -e

# Determine Python command - prefer uv run, fallback to venv python
if command -v uv &> /dev/null; then
    PYTHON_CMD="uv run python"
elif [ -f ".venv/bin/python" ]; then
    PYTHON_CMD=".venv/bin/python"
else
    PYTHON_CMD="python"
fi

echo "Waiting for services..."

# Wait for Redis
if [ -n "$REDIS_HOST" ]; then
  echo "Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT:-6379}..."
  
  # Determine if SSL is needed
  # Check REDIS_BROKER_URL first, then check if port is non-standard (likely SSL)
  SSL_FLAG="False"
  REDIS_PORT_VAL=${REDIS_PORT:-6379}
  
  if [ -n "$REDIS_BROKER_URL" ]; then
    if [[ "$REDIS_BROKER_URL" == rediss://* ]]; then
      SSL_FLAG="True"
      echo "Detected SSL requirement from REDIS_BROKER_URL (rediss://)"
    fi
  elif [ "$REDIS_PORT_VAL" != "6379" ]; then
    # Non-standard port often indicates SSL requirement (e.g., CloudClusters)
    SSL_FLAG="True"
    echo "Detected SSL requirement from non-standard port: ${REDIS_PORT_VAL}"
  fi
  
  # Extract username from REDIS_BROKER_URL if not set
  REDIS_USER_VAL="${REDIS_USERNAME:-}"
  if [ -z "$REDIS_USER_VAL" ] && [ -n "$REDIS_BROKER_URL" ]; then
    # Try to extract username from URL (format: redis://user:pass@host:port)
    if [[ "$REDIS_BROKER_URL" =~ redis://([^:]+): ]]; then
      REDIS_USER_VAL="${BASH_REMATCH[1]}"
    fi
  fi
  
  MAX_ATTEMPTS=30
  ATTEMPT=0
  
  until ${PYTHON_CMD} -c "
import redis
import sys
import os

ssl_enabled = ${SSL_FLAG}
host = '${REDIS_HOST}'
port = ${REDIS_PORT_VAL}
username = '${REDIS_USER_VAL}' if '${REDIS_USER_VAL}' else None
password = os.getenv('REDIS_PASSWORD', '') if os.getenv('REDIS_PASSWORD') else None

try:
    r = redis.Redis(
        host=host,
        port=port,
        username=username,
        password=password,
        decode_responses=True,
        socket_connect_timeout=5,
        socket_timeout=5,
        ssl=ssl_enabled,
        ssl_cert_reqs=None if ssl_enabled else None
    )
    r.ping()
    print('Redis is ready!')
except redis.ConnectionError as e:
    print(f'Connection error: {e}', file=sys.stderr)
    sys.exit(1)
except redis.AuthenticationError as e:
    print(f'Authentication error: {e}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
      echo "ERROR: Failed to connect to Redis after $MAX_ATTEMPTS attempts"
      echo "Host: ${REDIS_HOST}"
      echo "Port: ${REDIS_PORT_VAL}"
      echo "SSL: ${SSL_FLAG}"
      echo "Please check your Redis configuration and ensure REDIS_BROKER_URL uses 'rediss://' if SSL is required"
      exit 1
    fi
    echo "Waiting for Redis... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 2
  done
  echo "Redis is ready!"
fi

# Wait for PostgreSQL
if [ -n "$DATABASE_URL" ] || [ -n "$POSTGRES_HOST" ]; then
  echo "Waiting for PostgreSQL..."
  until ${PYTHON_CMD} -c "
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
${PYTHON_CMD} manage.py collectstatic --noinput || echo "Warning: Static files collection failed, continuing..."

# Apply database migrations
echo "Applying database migrations..."
${PYTHON_CMD} manage.py migrate || echo "Warning: Migrations failed, continuing..."

# Start server
echo "Starting server on port ${PORT:-8000}..."
if command -v uv &> /dev/null; then
    exec uv run uvicorn flight_blender.asgi:application --host 0.0.0.0 --port ${PORT:-8000} --workers 3
else
    exec ${PYTHON_CMD} -m uvicorn flight_blender.asgi:application --host 0.0.0.0 --port ${PORT:-8000} --workers 3
fi
