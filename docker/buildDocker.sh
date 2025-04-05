#!/bin/bash
# cd /Users/dmar/src/youtube_transcriber_3/docker

# NB:!!! The .. at the end is what sets the build context to the parent directory. This tells Docker:
#
# Use the Dockerfile in the current directory (-f Dockerfile)
# But set the build context to the parent directory (..)

docker build -t youtube-transcriber -f Dockerfile ..
