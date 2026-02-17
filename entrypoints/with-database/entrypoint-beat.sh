#!/bin/bash

source .venv/bin/activate

echo Waiting for DBs...
POSTGRES_PORT=${POSTGRES_PORT:-5433}
if ! wait-for-it --parallel --service $REDIS_HOST:$REDIS_PORT --service $POSTGRES_HOST:$POSTGRES_PORT; then
    exit
fi

celery --app=flight_blender beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
