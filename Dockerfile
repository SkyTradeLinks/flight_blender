# FROM --platform=linux/amd64 
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user first
RUN addgroup --gid 10000 django && adduser --shell /bin/bash --disabled-password --gecos "" --uid 10000 --ingroup django django

# Copy dependency files
COPY uv.lock pyproject.toml ./

# Install Python dependencies (without the project itself)
RUN pip install -U pip && pip install uv && uv sync --frozen --no-install-project --no-dev

# Set PYTHONPATH to include the current directory so Django can find the modules
ENV PYTHONPATH=/app

# Copy application code
COPY --chown=django:django . .

# Change ownership of entire /app directory (including .venv) to django user
RUN chown -R django:django /app

# Switch to django user and install the project
USER django:django
RUN uv sync --frozen --no-dev
USER root

# Make entrypoint scripts executable
RUN chmod +x entrypoints/docker-entrypoint-web.sh entrypoints/docker-entrypoint-worker.sh entrypoints/wait_for_service.py

USER django:django

EXPOSE 8000

# Default to web entrypoint (can be overridden)
CMD ["./entrypoints/docker-entrypoint-web.sh"]
