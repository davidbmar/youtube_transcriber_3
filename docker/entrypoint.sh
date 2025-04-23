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

# Define log file
LOG_FILE="/app/worker.log"
touch $LOG_FILE
chmod 666 $LOG_FILE

# Start the worker process in the background with output redirected to log file
echo "Starting worker process..." | tee -a $LOG_FILE
nohup python3 worker.py --queue_url "https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue" --s3_bucket 2025-03-15-youtube-transcripts --region us-east-2 >> $LOG_FILE 2>&1 &

# Store the worker process PID
WORKER_PID=$!
echo "Worker started with PID: $WORKER_PID" | tee -a $LOG_FILE
echo $WORKER_PID > /app/worker.pid

# Create a simple healthcheck file
touch /app/health_check.txt

# Keep the container running independent of worker status
echo "Container is now running with SSH and worker process active" | tee -a $LOG_FILE
while true; do
    # Update health check file
    date > /app/health_check.txt
    
    # Check if worker is still running, but don't restart automatically
    if ! kill -0 $WORKER_PID 2>/dev/null; then
        echo "Worker process is not running (PID: $WORKER_PID)" | tee -a $LOG_FILE
        
        # Don't restart automatically, just log the status
        # User can restart manually via SSH if needed
    else
        # Log that worker is still running (less frequently to avoid log spam)
        if [ $(($(date +%s) % 300)) -lt 10 ]; then  # Log approximately every 5 minutes
            echo "Worker still running with PID: $WORKER_PID ($(date))" | tee -a $LOG_FILE
        fi
    fi
    
    # Sleep for a while before checking again
    sleep 60
done
