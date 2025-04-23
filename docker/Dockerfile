# Base image with CUDA 12.4 runtime support
FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Install essential packages including openssh-server and dependencies
RUN apt-get update && apt-get install -y \
    openssh-server \
    python3.10 \
    python3-pip \
    ffmpeg \
    git \
    wget \
    curl \
    vim \
    unzip \
    jq \
    nano \
    htop \
    procps \  # Ensure we have ps command
    --no-install-recommends && \
    # Link python3 to python3.10 explicitly
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the /run/sshd directory required by sshd
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd

# Install AWS CLI v2
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

# Combine all Python package installations into a single run command for smaller layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    && pip3 install --no-cache-dir \
    boto3 \
    requests \
    pyyaml \
    faster-whisper \
    urllib3 \
    botocore \
    soundfile \
    torch \
    torchvision \
    torchaudio \
    -r requirements.txt \
    pandas \
    transformers \
    nltk \
    pyannote.audio \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cache/pip

# Clone and install WhisperX from GitHub into /opt/whisperx
RUN git clone https://github.com/m-bain/whisperx.git /opt/whisperx && \
    pip3 install --no-cache-dir /opt/whisperx && \
    rm -rf /root/.cache/pip

# Set LD_LIBRARY_PATH for cuDNN libraries
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/:$LD_LIBRARY_PATH

# Set PYTHONPATH so that /opt/whisperx is included in module search
ENV PYTHONPATH=/opt/whisperx:$PYTHONPATH

# Copy application code
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY src/worker.py /app/worker.py
COPY docs/ /app/docs

# Create helper scripts for manually starting/stopping the worker
RUN echo '#!/bin/bash\npython3 worker.py --queue_url "https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue" --s3_bucket 2025-03-15-youtube-transcripts --region us-east-2 >> /app/worker.log 2>&1' > /usr/local/bin/start-worker.sh && \
    chmod +x /usr/local/bin/start-worker.sh

# Create necessary directories for your application
RUN mkdir -p /app/temp

# Set AWS region environment variable
ENV AWS_DEFAULT_REGION=us-east-2

# Health check configuration - check the health_check.txt file
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 -c "import os, time; health_file='/app/health_check.txt'; exit(0 if os.path.exists(health_file) and time.time() - os.path.getmtime(health_file) < 300 else 1)"

RUN echo '#!/bin/bash\ntail -f /app/worker.log' > /usr/local/bin/monitor-worker.sh && \
    chmod +x /usr/local/bin/monitor-worker.sh


# Set entrypoint and expose SSH port
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 22

# Default arguments (can be overridden)
CMD ["--help"]
