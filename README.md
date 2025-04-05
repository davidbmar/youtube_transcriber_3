# YouTube Phrase Scanner

A robust, serverless system for downloading YouTube videos, transcribing them using WhisperX, and scanning for specific phrases.

## Overview

This tool processes YouTube videos from an SQS queue, downloads their audio, transcribes the content using WhisperX, and identifies occurrences of specified phrases. All results are stored in S3 for analysis.

## Repository Structure
```
youtube-transcriber/                # Root of your Git repository
├── src/                            # Application source code
│   ├── worker.py                   # Main worker implementation
│   ├── job_tracker.py              # Job tracking functionality
│   ├── downloader.py               # YouTube downloader
│   ├── transcriber.py              # Audio transcription
│   └── scanner.py                  # Phrase scanning
│
├── docker/                         # Docker-related files
│   ├── Dockerfile                  # Main Dockerfile
│   ├── requirements.txt            # Python dependencies
│   └── entrypoint.sh               # Optional: startup script if needed
|
├── runpod-lambda                   # AWS Lambda-based solution for managing GPU instances on RunPod.
|                                   # creation, management, and termination of GPU pods on the RunPod platform.
|
├── tests/                          # Test files
│   ├── test_worker.py
│   ├── test_downloader.py
│   └── ...
│
├── configs/                        # Configuration files
│   └── default_config.json         # Default configuration
│
├── docs/                           # Documentation
│   └── README.md                   # Documentation specific to components
│
└── README.md                       # Main project documentation
```
- `src/` - Core source code
- `scripts/` - Utility scripts
- `docker/` - Docker configuration
- `web/` - Web frontend
- `runpod/` - RunPod integration
- `docs/` - Documentation
- `tests/` - Test files
- `examples/` - Example configurations

## Setup & Usage

See the documentation in the `docs/` directory for setup and usage instructions.
