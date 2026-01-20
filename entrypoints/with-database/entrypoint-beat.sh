#!/bin/bash

source .venv/bin/activate

echo Waiting for DBs...
# Use port 5432 for internal Docker network connections (db-blender), 5433 for host connections
if [ "$POSTGRES_HOST" = "db-blender" ]; then
    POSTGRES_PORT=5432
else
    POSTGRES_PORT=${POSTGRES_PORT:-5433}
fi
if ! wait-for-it --parallel --service $REDIS_HOST:$REDIS_PORT --service $POSTGRES_HOST:$POSTGRES_PORT; then
    exit
fi

celery --app=flight_blender beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
