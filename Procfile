web: uvicorn flight_blender.asgi:application --host 0.0.0.0 --port $PORT --workers 3
worker: celery --app=flight_blender worker --loglevel=info
