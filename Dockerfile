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

# Copy the rest of the application
COPY . .

# Train the Rasa model
RUN rasa train

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Environment variables
ENV PORT=8000
ENV RASA_PORT=5005
ENV RASA_ACTIONS_PORT=5005
ENV PYTHONPATH=/app
ENV RASA_TELEMETRY_ENABLED=false
ENV RASA_MODEL_PATH=/app/models
ENV RASA_ACTIONS_URL=http://localhost:5005
ENV RASA_CORS_ORIGINS=*

# Expose ports
EXPOSE 8000
EXPOSE 5005
EXPOSE 5005

# Use tini to manage processes
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start all services via entrypoint script
CMD ["/app/entrypoint.sh"]
