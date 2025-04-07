#!/bin/bash
set -e

# Map RunPod secrets to AWS environment variables
if [ ! -z "$RUNPOD_SECRET_AWS_ACCESS_KEY_ID" ]; then
  export AWS_ACCESS_KEY_ID=$RUNPOD_SECRET_AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$RUNPOD_SECRET_AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$RUNPOD_SECRET_AWS_DEFAULT_REGION
  echo "AWS credentials mapped from RunPod secrets"
fi

#!/bin/bash
# Ensure /run/sshd exists
if [ ! -d /run/sshd ]; then
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
fi

# Start the SSH daemon in the foreground
exec /usr/sbin/sshd -D
