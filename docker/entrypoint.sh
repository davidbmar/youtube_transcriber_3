#!/bin/bash
set -e

# Default to worker if no specific command
if [ $# -eq 0 ]; then
    echo "Starting YouTube Phrase Scanner worker..."
    exec python3 run.py
else
    exec python3 run.py "$@"
fi
