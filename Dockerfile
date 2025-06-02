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
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir rasa django gunicorn

# Copy the application
COPY . .

# Train the Rasa model
RUN . /opt/venv/bin/activate && rasa train

# Set environment variables
ENV PORT=8000
ENV RASA_PORT=5005
ENV PYTHONPATH=/app
ENV RASA_TELEMETRY_ENABLED=false
ENV RASA_MODEL_PATH=/app/models
ENV RASA_ACTIONS_URL=http://localhost:5005
ENV RASA_CORS_ORIGINS=*

# Expose ports
EXPOSE 8000
EXPOSE 5005

# Start both servers directly with CMD
CMD . /opt/venv/bin/activate && \
    rasa run --enable-api --cors "*" --port ${RASA_PORT} --credentials credentials.yml & \
    rasa run actions --cors "*" --port 5005 & \
    cd psykh_web && \
    gunicorn psykh_web.wsgi:application --bind 0.0.0.0:${PORT} --workers 3 --timeout 120 --log-level debug 