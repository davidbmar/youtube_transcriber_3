#!/bin/bash
set -e

#!/bin/bash
# Ensure /run/sshd exists
if [ ! -d /run/sshd ]; then
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
fi

# Start the SSH daemon in the foreground
exec /usr/sbin/sshd -D
