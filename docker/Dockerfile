# ----------- Builder Stage -----------
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install build and Python dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3.10 python3.10-dev python3-pip \
    git wget curl unzip libsndfile1-dev libjpeg-dev libpng-dev libssl-dev \
 && ln -sf /usr/bin/python3.10 /usr/bin/python3 \
 && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install all Python packages
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    torchaudio==2.0.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install --no-cache-dir \
    numpy==1.24.3 boto3==1.28.0 requests==2.31.0 pyyaml==6.0 \
    python-dateutil==2.9.0 pytz soundfile==0.12.1 ffmpeg-python==0.2.0 \
    whisperx==3.3.2 pyannote.audio==3.3.2 transformers==4.35.2 \
    huggingface-hub==0.17.3 faster-whisper==1.1.0 pandas==2.0.3 \
    nltk==3.8.1 tqdm packaging "regex!=2019.12.17" \
    safetensors>=0.3.1 ctranslate2 av tokenizers==0.15.2 einops && \
    pip3 install --no-cache-dir -r requirements.txt

# ----------- Runtime Stage -----------
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Minimal OS packages for runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip ffmpeg libsndfile1 \
    libjpeg-dev libpng-dev libssl-dev \
 && ln -sf /usr/bin/python3.10 /usr/bin/python3 \
 && rm -rf /var/lib/apt/lists/*

# Copy Python environment from builder
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# Install AWS CLI and yt-dlp
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip /tmp/awscliv2.zip && ./aws/install && rm -rf /tmp/awscliv2.zip aws && \
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp && chmod a+rx /usr/local/bin/yt-dlp

# Set environment and working directory
ENV AWS_DEFAULT_REGION=us-east-2
WORKDIR /app

# Copy application code and entrypoint
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY src/worker.py /app/worker.py
COPY docs/ /app/docs

# Create temp directory
RUN mkdir -p /app/temp

# Healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 -c "import os, time; f='/app/health_check.txt'; exit(0 if os.path.exists(f) and time.time()-os.path.getmtime(f)<300 else 1)"

# Entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 22
CMD ["--help"]


