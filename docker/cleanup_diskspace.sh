#!/bin/bash
# Remove all stopped containers
docker container prune -f

# Remove all unused images (not just dangling ones)
docker image prune -a -f

# Remove unused volumes
docker volume prune -f

# For a complete system cleanup
docker system prune -a -f --volumes
