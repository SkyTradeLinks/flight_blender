#!/bin/bash

echo Waiting for DBs...
if ! uv run python entrypoints/wait_for_service.py --service $REDIS_HOST:$REDIS_PORT; then
    exit 1
fi

uv run celery --app=flight_blender worker --loglevel=info
