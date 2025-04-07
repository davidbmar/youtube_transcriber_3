#!/bin/bash
set -e

# Map RunPod secrets to AWS environment variables
if [ ! -z "$RUNPOD_SECRET_AWS_ACCESS_KEY_ID" ]; then
  export AWS_ACCESS_KEY_ID=$RUNPOD_SECRET_AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$RUNPOD_SECRET_AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$RUNPOD_SECRET_AWS_DEFAULT_REGION
  echo "AWS credentials mapped from RunPod secrets"
fi

# Ensure /run/sshd exists
if [ ! -d /run/sshd ]; then
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
fi

# Start SSH daemon in the background
/usr/sbin/sshd

# Start the worker process in the background
echo "Starting worker process..."
python3 worker.py --queue_url "https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue" --s3_bucket 2025-03-15-youtube-transcripts --region us-east-2 &

# Store the worker process PID
WORKER_PID=$!

# Create a file to monitor the worker's status
echo $WORKER_PID > /app/worker.pid
echo "Worker started with PID: $WORKER_PID"

# Create a simple healthcheck file
touch /app/health_check.txt

# Keep the container running
echo "Container is now running with SSH and worker process active"
while true; do
    # Check if worker is still running
    if ! kill -0 $WORKER_PID 2>/dev/null; then
        echo "WARNING: Worker process died. Restarting..." 
        python3 worker.py --queue_url "https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue" --s3_bucket 2025-03-15-youtube-transcripts --region us-east-2 &
        WORKER_PID=$!
        echo $WORKER_PID > /app/worker.pid
        echo "Worker restarted with PID: $WORKER_PID"
    fi
    
    # Update health check file
    date > /app/health_check.txt
    
    # Sleep for a while before checking again
    sleep 60
done
