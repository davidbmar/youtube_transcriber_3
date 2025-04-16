# Base image with Ubuntu 22.04
FROM ubuntu:22.04

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# First update package lists
RUN apt-get update

# Install wget and curl explicitly first
RUN apt-get install -y wget curl unzip

RUN apt-get install -y \
    openssh-server \
    python3 \
    python3-distutils \
    python3-pip \
    ffmpeg \
    git \
    vim \
    jq \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Ensure pip is available
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3

# Create the /run/sshd directory required by sshd
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd

# Install AWS CLI v2
RUN wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install yt-dlp
RUN wget -O /usr/local/bin/yt-dlp "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" && \
    chmod a+rx /usr/local/bin/yt-dlp

# Create app directory and set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt /app/

# Install PyTorch with CUDA support compatible with newer whisperx
#RUN python3 -m pip install --no-cache-dir torch==2.0.1 torchaudio==2.0.1 --index-url https://download.pytorch.org/whl/cu118
RUN python3 -m pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install additional Python packages required for your application
RUN python3 -m pip install --no-cache-dir \
    boto3 \
    requests \
    pyyaml \
    soundfile

# Install WhisperX via pip first
RUN python3 -m pip install --no-cache-dir whisperx

# Check requirements.txt and remove any whisperx entries
RUN grep -v "whisperx\|git+https://github.com/m-bain/whisperx.git" requirements.txt > requirements_filtered.txt || cp requirements.txt requirements_filtered.txt

# Install Python dependencies from filtered requirements.txt
RUN python3 -m pip install --no-cache-dir -r requirements_filtered.txt

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
