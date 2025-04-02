# YouTube Phrase Scanner

A robust, serverless system for downloading YouTube videos, transcribing them using WhisperX, and scanning for specific phrases.

## Overview

This tool processes YouTube videos from an SQS queue, downloads their audio, transcribes the content using WhisperX, and identifies occurrences of specified phrases. All results are stored in S3 for analysis.

## Repository Structure

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
