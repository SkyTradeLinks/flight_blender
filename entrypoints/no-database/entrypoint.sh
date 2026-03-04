#!/bin/bash

echo Waiting for DBs...
if ! uv run python entrypoints/wait_for_service.py --service $REDIS_HOST:$REDIS_PORT; then
    exit 1
fi

# Sync dependencies (ensures newly added packages are installed)
echo "Syncing dependencies..."
uv sync --frozen --no-dev

# Collect static files
echo "Collect static files"
uv run python manage.py collectstatic --noinput

# Apply database migrations
echo "Apply database migrations"
uv run python manage.py migrate

# Start server
echo "Starting server"
uv run uvicorn flight_blender.asgi:application --host 0.0.0.0 --port 8000 --workers 3 --reload
