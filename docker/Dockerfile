# Base image with PyTorch and CUDA 11.8 pre-installed
# to support GPU acceleration
FROM pytorch/pytorch:2.0.1-cuda11.8-cudnn8-runtime

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive \
    AWS_DEFAULT_REGION=us-east-2

# Install OS-level dependencies and image libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg git wget curl vim unzip jq nano htop procps \
    libsndfile1 libjpeg-dev libpng-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# Install AWS CLI and yt-dlp
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip /tmp/awscliv2.zip && ./aws/install && rm -rf /tmp/awscliv2.zip aws && \
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp && chmod a+rx /usr/local/bin/yt-dlp

# Set working directory
WORKDIR /app

# Copy Python requirements
COPY requirements.txt /app/

# Upgrade pip and install ASR & transcription dependencies
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
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
        av \
        tokenizers==0.15.2 \
        einops && \
    pip3 install --no-cache-dir -r requirements.txt

# Copy application code and entrypoint
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY src/worker.py /app/worker.py
COPY docs/ /app/docs

# Create temporary directory for app
RUN mkdir -p /app/temp

# Healthcheck for container (checks /app/health_check.txt freshness)
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 -c "import os, time; f='/app/health_check.txt'; exit(0 if os.path.exists(f) and time.time()-os.path.getmtime(f)<300 else 1)"

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 22
CMD ["--help"]


