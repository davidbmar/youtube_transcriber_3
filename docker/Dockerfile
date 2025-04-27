# ---------- BASE IMAGE ----------
#FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04


# ---------- ENV VARS ----------
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# ---------- OS PACKAGES ----------
RUN apt-get update && apt-get install -y \
    openssh-server python3.10 python3-pip ffmpeg git wget curl vim unzip jq nano htop procps \
    --no-install-recommends && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd && chmod 0755 /run/sshd

# ---------- AWS CLI ----------
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip

# ---------- yt-dlp ----------
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp && chmod a+rx /usr/local/bin/yt-dlp

# ---------- PYTHON DEPENDENCIES ----------
WORKDIR /app
COPY requirements.txt /app/

# Core libs
RUN pip3 install --no-cache-dir \
    numpy==1.24.3 boto3==1.28.0 requests==2.31.0 pyyaml==6.0 \
    soundfile==0.12.1 ffmpeg-python==0.2.0

# CUDA-enabled PyTorch stack
RUN pip3 install --no-cache-dir \
    torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Your own requirements file
RUN pip3 install --no-cache-dir -r requirements.txt

# ASR + diarization stack (now includes WhisperX from PyPI)
RUN pip3 install --no-cache-dir \
    faster-whisper==1.1.0 transformers==4.35.2 pyannote.audio==3.3.2 \
    pandas==2.0.3 nltk==3.8.1 whisperx==3.3.2

# ---------- APP CODE ----------
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY src/worker.py /app/worker.py
COPY docs/ /app/docs

# ─── replace the faulty placeholder with these two lines ───
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ─── helper scripts ───
#COPY docker/start-worker.sh   /usr/local/bin/start-worker.sh
COPY docker/monitor-worker.sh /usr/local/bin/monitor-worker.sh
RUN chmod +x /usr/local/bin/monitor-worker.sh

RUN mkdir -p /app/temp
ENV AWS_DEFAULT_REGION=us-east-2

HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 -c "import os, time; f=\"/app/health_check.txt\"; exit(0 if os.path.exists(f) and time.time()-os.path.getmtime(f)<300 else 1)"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 22
CMD ["--help"]

