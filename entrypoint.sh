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

# Start Rasa server (port 5005)
rasa run \
  --enable-api \
  --cors "*" \
  --port ${RASA_PORT} \
  --credentials credentials.yml &

# Start Rasa Actions server (port 5055)
rasa run actions \
  --cors "*" \
  --port ${RASA_ACTIONS_PORT} &

# Start Django app with Gunicorn (port 8000)
cd psykh_web
echo "Starting Django with settings module: $DJANGO_SETTINGS_MODULE"
gunicorn psykh_web.wsgi:application \
  --bind 0.0.0.0:${PORT} \
  --workers 3 \
  --timeout 120 \
  --log-level debug

# Wait for all background processes
wait
