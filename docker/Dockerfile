# Base image with CUDA 12.4 runtime support (aligns with torch+cu124)
# Removed cuDNN from base image name as PyTorch pip package will provide it.
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
    --no-install-recommends && \
    # Link python3 to python3.10 explicitly if needed (Ubuntu 22.04 usually does this)
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
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

# --- Combine all Python package installations into a SINGLE RUN command ---
# This minimizes layers and allows cleaning up temporary files within the same step
# Add cleanup at the end to remove downloaded wheels/cache if possible
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Add any build-time dependencies needed for packages in requirements.txt here
    # e.g., build-essential cmake etc. if needed, otherwise remove this line
    && \
    # Install all pip packages together
    pip3 install --no-cache-dir \
    # Base dependencies (consider pinning)
    boto3 \
    requests \
    pyyaml \
    faster-whisper \
    urllib3 \
    botocore \
    soundfile \
    # Install torch explicitly (PIN VERSION!) - ensure compatibility with CUDA 12.4
    # Example: torch==2.6.0+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    torch \
    torchvision \
    torchaudio \
    # Install from requirements.txt
    # **** INVESTIGATE the "UNKNOWN" package being built/installed - is it intended? ****
    # **** It might come from a line like '.' or similar in requirements.txt ****
    -r requirements.txt \
    # Install whisperx dependencies (PIN VERSIONS!)
    pandas \
    transformers \
    nltk \
    pyannote.audio \
    # --- Cleanup within the SAME RUN command ---
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
        # Add package names listed above if they were build-time only deps
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cache/pip

# Clone and install WhisperX from GitHub into /opt/whisperx
# (Recommend pinning WhisperX version via tag or commit)
RUN git clone https://github.com/m-bain/whisperx.git /opt/whisperx && \
    pip3 install --no-cache-dir /opt/whisperx && \
    # Clean up pip cache again after this specific install
    rm -rf /root/.cache/pip

# ---- CORE FIX for runtime: Set LD_LIBRARY_PATH ----
# Add the location of the cuDNN libraries installed via pip (by torch dependency nvidia-cudnn-cu12)
# to the dynamic linker search path. Assumes Python 3.10 from ubuntu22.04 base.
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/:$LD_LIBRARY_PATH

# Set PYTHONPATH so that /opt/whisperx is included in module search (May be redundant after pip install)
ENV PYTHONPATH=/opt/whisperx:$PYTHONPATH

# Copy application code (preserving directory structure)
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
# This seems redundant if src/worker.py exists, but keeping original structure
COPY src/worker.py /app/worker.py
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
