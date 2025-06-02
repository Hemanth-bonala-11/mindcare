FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir rasa django gunicorn

# Copy the application
COPY . .

# Train the Rasa model
RUN rasa train

# Set environment variables
ENV PORT=8000
ENV RASA_PORT=5005
ENV PYTHONPATH=/app
ENV RASA_TELEMETRY_ENABLED=false
ENV RASA_MODEL_PATH=/app/models
ENV RASA_ACTIONS_URL=http://localhost:5055
ENV RASA_CORS_ORIGINS=*

# Expose ports
EXPOSE 8000
EXPOSE 5005

# Start services
CMD rasa run --enable-api --cors "*" --port ${RASA_PORT} --credentials credentials.yml & \
    rasa run actions --cors "*" --port 5055 & \
    cd psykh_web && gunicorn --bind 0.0.0.0:${PORT} psykh_web.wsgi:application --workers 3 --timeout 120 --log-level debug 