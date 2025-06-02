FROM python:3.9-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

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
    && rm -rf /var/lib/apt/lists/*

# Copy only necessary files from builder
COPY --from=builder /app/models /app/models
COPY --from=builder /app/actions /app/actions
COPY --from=builder /app/data /app/data
COPY --from=builder /app/domain.yml /app/domain.yml
COPY --from=builder /app/config.yml /app/config.yml
COPY --from=builder /app/endpoints.yml /app/endpoints.yml
COPY --from=builder /app/credentials.yml /app/credentials.yml
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Set environment variables
ENV PORT=8080
ENV PYTHONPATH=/app

# Expose the port
EXPOSE 8080

# Create start script
RUN echo '#!/bin/bash\n\
rasa run --enable-api --cors "*" --port $PORT --credentials credentials.yml & \
rasa run actions --cors "*" --port 5005\n\
wait' > /app/start.sh && chmod +x /app/start.sh

# Start both Rasa server and action server
CMD ["/app/start.sh"] 