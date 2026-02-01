FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install ffsubsync
RUN pip install --no-cache-dir ffsubsync

# Set working directory
WORKDIR /data

# Default command shows help
ENTRYPOINT ["ffsubsync"]
CMD ["--help"]

