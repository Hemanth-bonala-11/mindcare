# Use Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies and tini
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    python3-venv \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Optional: install explicitly if not in requirements.txt
RUN pip install --no-cache-dir rasa django gunicorn

# Create models directory
RUN mkdir -p /app/models

# Copy the rest of the application
COPY . .

# Train initial Rasa model during build
RUN rasa train --debug --fixed-model-name latest && \
    ls -la /app/models/latest.tar.gz || echo "Warning: Model file not found!"

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Environment variables
ENV PORT=8000
ENV RASA_PORT=5005
ENV RASA_ACTIONS_PORT=5055
ENV PYTHONPATH=/app
ENV RASA_TELEMETRY_ENABLED=false
ENV RASA_MODEL_PATH=/app/models
ENV RASA_ACTIONS_URL=https://mindcare-bot.nicebay-5c30314d.westus2.azurecontainerapps.io:5055
ENV RASA_CORS_ORIGINS=*

# Create volume for models
VOLUME ["/app/models"]

# Expose ports
EXPOSE 8000
EXPOSE 5005
EXPOSE 5055

# Use tini to manage processes
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start all services via entrypoint script
CMD ["/app/entrypoint.sh"]
