FROM python:3.9-slim as builder

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

# Copy requirements first for better cache utilization
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Train the model
RUN rasa train

# Final stage
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    curl \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Copy only necessary files from builder
COPY --from=builder /app/models /app/models
COPY --from=builder /app/actions /app/actions
COPY --from=builder /app/data /app/data
COPY --from=builder /app/domain.yml /app/domain.yml
COPY --from=builder /app/config.yml /app/config.yml
COPY --from=builder /app/endpoints.yml /app/endpoints.yml
COPY --from=builder /app/credentials.yml /app/credentials.yml
COPY --from=builder /app/psykh_web /app/psykh_web

# Set environment variables
ENV PORT=8000
ENV RASA_PORT=5005
ENV PYTHONPATH=/app

# Expose the ports
EXPOSE 8000
EXPOSE 5005

# Create start script
RUN echo '#!/bin/bash\n\
# Activate virtual environment\n\
source /opt/venv/bin/activate\n\
\n\
# Start Rasa server in background\n\
rasa run --enable-api --cors "*" --port $RASA_PORT --credentials credentials.yml & \n\
rasa run actions --cors "*" --port 5055 & \n\
\n\
# Start Django with gunicorn\n\
cd psykh_web && \
gunicorn psykh_web.wsgi:application --bind 0.0.0.0:$PORT --workers 3 --timeout 120\n\
wait' > /app/start.sh && chmod +x /app/start.sh

# Start both servers
CMD ["/bin/bash", "/app/start.sh"] 