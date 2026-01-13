FROM --platform=linux/amd64 python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY uv.lock pyproject.toml ./

# Install Python dependencies
RUN pip install -U pip && pip install uv && uv sync --frozen --no-install-project --no-dev

# Create non-root user
RUN addgroup --gid 10000 django && adduser --shell /bin/bash --disabled-password --gecos "" --uid 10000 --ingroup django django

# Copy application code
COPY --chown=django:django . .

# Make entrypoint scripts executable
RUN chmod +x entrypoints/docker-entrypoint-web.sh entrypoints/docker-entrypoint-worker.sh

USER django:django

EXPOSE 8000

# Default to web entrypoint (can be overridden)
CMD ["./entrypoints/docker-entrypoint-web.sh"]
