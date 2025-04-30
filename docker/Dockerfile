# Use CUDA 11.8 with cuDNN 8 development libraries
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive \
    AWS_DEFAULT_REGION=us-east-2

# Install OS-level dependencies (including image libs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    python3.10 python3-pip \
    ffmpeg git wget curl vim unzip jq nano htop procps \
    libjpeg-dev libpng-dev \
 && ln -sf /usr/bin/python3.10 /usr/bin/python3 \
 && rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip /tmp/awscliv2.zip && ./aws/install && rm -rf /tmp/awscliv2.zip aws

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp && chmod a+rx /usr/local/bin/yt-dlp

WORKDIR /app

# Copy user requirements
COPY requirements.txt /app/

# Install CUDA-enabled PyTorch stack first (cu118)
RUN pip3 install --no-cache-dir \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    torchaudio==2.0.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Core Python libraries (including date/time support)
RUN pip3 install --no-cache-dir \
    numpy==1.24.3 \
    boto3==1.28.0 \
    requests==2.31.0 \
    pyyaml==6.0 \
    python-dateutil==2.9.0 \
    pytz \
    soundfile==0.12.1 \
    ffmpeg-python==0.2.0

# Install ASR & transcription stack without pulling in extra torch
RUN pip3 install --no-deps --no-cache-dir \
    whisperx==3.3.2 \
    pyannote.audio==3.3.2 \
    transformers==4.35.2 \
    huggingface-hub==0.17.3 \
    faster-whisper==1.1.0 \
    pandas==2.0.3 \
    nltk==3.8.1 \
    tqdm \
    packaging \
    "regex!=2019.12.17" \
    safetensors>=0.3.1 \
    ctranslate2 \
    av

# Install any remaining dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY src/worker.py /app/worker.py
COPY docs/ /app/docs

# Create temporary directory
RUN mkdir -p /app/temp

# Healthcheck for container
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 -c "import os, time; f='/app/health_check.txt'; exit(0 if os.path.exists(f) and time.time()-os.path.getmtime(f)<300 else 1)"

# Entrypoint and defaults
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 22
CMD ["--help"]


