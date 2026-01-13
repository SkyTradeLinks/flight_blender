#!/bin/bash
set -e

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
else
  echo "Warning: REDIS_HOST not set, skipping Redis check"
fi

# Start Celery worker
echo "Starting Celery worker..."
exec celery --app=flight_blender worker --loglevel=info
