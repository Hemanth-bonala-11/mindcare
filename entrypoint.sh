#!/bin/bash
set -e

# Activate virtual environment
source /opt/venv/bin/activate

# Debug output
echo "Current directory: $(pwd)"
echo "Python path: $PYTHONPATH"
echo "Virtual env: $VIRTUAL_ENV"

# Set Django settings module explicitly
export DJANGO_SETTINGS_MODULE=psykh_web.settings

# Create models directory if it doesn't exist
mkdir -p /app/models

# Train Rasa model
echo "Training Rasa model..."
rasa train --debug --fixed-model-name latest || {
    echo "Rasa training failed!"
    exit 1
}

# Start Rasa server (port 5005)
echo "Starting Rasa server..."
rasa run \
  --enable-api \
  --cors "*" \
  --port ${RASA_PORT:-5005} \
  --credentials credentials.yml \
  --endpoints endpoints.yml \
  --debug \
  --log-file rasa.log \
  --model models/latest.tar.gz &

# Start Rasa Actions server (port 5055)
echo "Starting Rasa Actions server..."
rasa run actions \
  --cors "*" \
  --port ${RASA_ACTIONS_PORT:-5055} \
  --debug \
  --log-file actions.log &

# Wait for Rasa servers to start
echo "Waiting for Rasa servers to start..."
sleep 10

# Start Django app with Gunicorn (port 8000)
cd psykh_web
echo "Starting Django with settings module: $DJANGO_SETTINGS_MODULE"
gunicorn psykh_web.wsgi:application \
  --bind 0.0.0.0:${PORT:-8000} \
  --workers 4 \
  --threads 2 \
  --worker-class gthread \
  --worker-connections 1000 \
  --timeout 300 \
  --keep-alive 120 \
  --max-requests 1000 \
  --max-requests-jitter 50 \
  --log-level debug \
  --access-logfile - \
  --error-logfile - \
  --capture-output \
  --enable-stdio-inheritance \
  --forwarded-allow-ips="*" \
  --proxy-protocol \
  --proxy-allow-from="*" \
  --graceful-timeout 300 \
  --worker-tmp-dir /dev/shm

# Wait for all background processes
wait
