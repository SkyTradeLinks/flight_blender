#!/bin/bash
set -e

# Wait for Redis
if [ -n "$REDIS_HOST" ]; then
  echo "Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT:-6379}..."
  if ! uv run python entrypoints/wait_for_service.py --service $REDIS_HOST:${REDIS_PORT:-6379}; then
    echo "Redis connection failed"
    exit 1
  fi
  echo "Redis is ready!"
else
  echo "Warning: REDIS_HOST not set, skipping Redis check"
fi

# Start Celery worker
echo "Starting Celery worker..."
exec uv run celery --app=flight_blender worker --loglevel=info
