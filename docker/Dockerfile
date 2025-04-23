# Base image with CUDA 11.8 runtime support (more stable for ML workloads)
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

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
    procps \
    --no-install-recommends && \
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

# Install Python packages with fixed versions for better compatibility
RUN pip3 install --no-cache-dir \
    numpy==1.24.3 \
    boto3==1.28.0 \
    requests==2.31.0 \
    pyyaml==6.0 \
    soundfile==0.12.1 \
    ffmpeg-python==0.2.0

# Install PyTorch with CUDA 11.8
RUN pip3 install --no-cache-dir \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    torchaudio==2.0.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Install from requirements.txt (excluding already installed packages)
RUN pip3 install --no-cache-dir -r requirements.txt

# Install WhisperX and its dependencies
RUN pip3 install --no-cache-dir \
    faster-whisper==0.10.0 \
    transformers==4.35.2 \
    pyannote.audio==3.1.1 \
    pandas==2.0.3 \
    nltk==3.8.1

# Clone and install WhisperX from GitHub with fixed version
RUN git clone https://github.com/m-bain/whisperx.git /opt/whisperx && \
    cd /opt/whisperx && \
    git checkout 8d51593 && \
    pip3 install --no-cache-dir -e .

# Set LD_LIBRARY_PATH for the correct CUDA libraries
ENV LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib/:$LD_LIBRARY_PATH

# Set PYTHONPATH to include whisperx
ENV PYTHONPATH=/opt/whisperx:$PYTHONPATH

# Copy application code
COPY src/ /app/src/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY src/worker.py /app/worker.py
COPY docs/ /app/docs

# Create improved entrypoint script that doesn't exit on worker termination
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Map RunPod secrets to AWS environment variables\n\
if [ ! -z "$RUNPOD_SECRET_AWS_ACCESS_KEY_ID" ]; then\n\
  export AWS_ACCESS_KEY_ID=$RUNPOD_SECRET_AWS_ACCESS_KEY_ID\n\
  export AWS_SECRET_ACCESS_KEY=$RUNPOD_SECRET_AWS_SECRET_ACCESS_KEY\n\
  export AWS_DEFAULT_REGION=$RUNPOD_SECRET_AWS_DEFAULT_REGION\n\
  echo "AWS credentials mapped from RunPod secrets"\n\
fi\n\
\n\
# Ensure /run/sshd exists\n\
if [ ! -d /run/sshd ]; then\n\
    mkdir -p /run/sshd\n\
    chmod 0755 /run/sshd\n\
fi\n\
\n\
# Start SSH daemon in the background\n\
/usr/sbin/sshd\n\
\n\
# Define log file\n\
LOG_FILE="/app/worker.log"\n\
touch $LOG_FILE\n\
chmod 666 $LOG_FILE\n\
\n\
# Start the worker process in the background with output redirected to log file\n\
echo "Starting worker process..." | tee -a $LOG_FILE\n\
nohup python3 worker.py --queue_url "https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue" --s3_bucket 2025-03-15-youtube-transcripts --region us-east-2 >> $LOG_FILE 2>&1 &\n\
\n\
# Store the worker process PID\n\
WORKER_PID=$!\n\
echo "Worker started with PID: $WORKER_PID" | tee -a $LOG_FILE\n\
echo $WORKER_PID > /app/worker.pid\n\
\n\
# Create a simple healthcheck file\n\
touch /app/health_check.txt\n\
\n\
# Keep the container running independent of worker status\n\
echo "Container is now running with SSH and worker process active" | tee -a $LOG_FILE\n\
while true; do\n\
    # Update health check file\n\
    date > /app/health_check.txt\n\
    \n\
    # Check if worker is still running, but dont restart automatically\n\
    if ! kill -0 $WORKER_PID 2>/dev/null; then\n\
        echo "Worker process is not running (PID: $WORKER_PID)" | tee -a $LOG_FILE\n\
    else\n\
        # Log that worker is still running (less frequently to avoid log spam)\n\
        if [ $(($(date +%s) % 300)) -lt 10 ]; then  # Log approximately every 5 minutes\n\
            echo "Worker still running with PID: $WORKER_PID ($(date))" | tee -a $LOG_FILE\n\
        fi\n\
    fi\n\
    \n\
    # Sleep for a while before checking again\n\
    sleep 60\n\
done' > /usr/local/bin/entrypoint.sh && \
chmod +x /usr/local/bin/entrypoint.sh

# Create helper scripts for ease of use
RUN echo '#!/bin/bash\npython3 worker.py --queue_url "https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue" --s3_bucket 2025-03-15-youtube-transcripts --region us-east-2 >> /app/worker.log 2>&1' > /usr/local/bin/start-worker.sh && \
    chmod +x /usr/local/bin/start-worker.sh && \
    echo '#!/bin/bash\ntail -f /app/worker.log' > /usr/local/bin/monitor-worker.sh && \
    chmod +x /usr/local/bin/monitor-worker.sh

# Create necessary directories for your application
RUN mkdir -p /app/temp

# Set AWS region environment variable
ENV AWS_DEFAULT_REGION=us-east-2

# Health check configuration - check the health_check.txt file
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 -c "import os, time; health_file='/app/health_check.txt'; exit(0 if os.path.exists(health_file) and time.time() - os.path.getmtime(health_file) < 300 else 1)"

# Set entrypoint and expose SSH port
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 22

# Default command (not used due to entrypoint)
CMD ["--help"]
