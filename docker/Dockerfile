# Base image with CUDA support
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Install essential packages including openssh-server and dependencies
RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    python3-pip \
    ffmpeg \
    git \
    wget \
    curl \
    vim \
    unzip \
    jq \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the /run/sshd directory required by sshd
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd

# Install AWS CLI v2 (requires curl and unzip)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Create app directory and set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt /app/

# Install additional Python packages required for your application
RUN pip3 install --no-cache-dir \
    boto3 \
    requests \
    pyyaml \
    faster-whisper \
    torch \
    urllib3 \
    botocore \
    soundfile

# Install Python dependencies from requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Install additional dependencies required by whisperx
RUN pip3 install --no-cache-dir pandas transformers nltk pyannote.audio

# Clone and install WhisperX from GitHub into /opt/whisperx
RUN git clone https://github.com/m-bain/whisperx.git /opt/whisperx && \
    pip3 install --no-cache-dir /opt/whisperx

# Set PYTHONPATH so that /opt/whisperx is included in module search
ENV PYTHONPATH=/opt/whisperx:$PYTHONPATH

# Copy application code (preserving directory structure)
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
# This is redundant but to get the worker running.
COPY src/worker.py/ /app
COPY docs/ /app/docs

# Create necessary directories for your application
RUN mkdir -p /app/temp

# Set AWS region environment variable
ENV AWS_DEFAULT_REGION=us-east-2

# Health check configuration
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 -c "import os, time; health_file='/app/health_check.txt'; exit(0 if os.path.exists(health_file) and time.time() - os.path.getmtime(health_file) < 300 else 1)"

# Set entrypoint and expose SSH port
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 22

# Default arguments (can be overridden)
CMD ["--help"]

