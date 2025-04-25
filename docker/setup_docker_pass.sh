#!/usr/bin/env bash
set -eo pipefail

# This script configures Docker to securely store Docker Hub credentials using 'pass'.
# It detects Amazon Linux version (2 vs 2023), sets up EPEL, installs 'pass', 'gpg',
# and downloads the Docker credential helper binary for 'pass'.
# It accepts the Docker Hub Personal Access Token via DOCKER_HUB_PAT env var or interactively.

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Run this script with sudo or as root." >&2
  exit 1
fi

# Determine non-root target user for Docker credentials
TARGET_USER=${SUDO_USER:-$(whoami)}
TARGET_HOME=$(eval echo ~${TARGET_USER})

# Load OS information
source /etc/os-release

# Detect Amazon Linux version and package manager
if [[ "$ID" == "amzn" && "$VERSION_ID" == "2023"* ]]; then
  PKG_MGR=dnf
else
  # Amazon Linux 2 or other
  if command -v dnf &>/dev/null; then PKG_MGR=dnf; else PKG_MGR=yum; fi
fi

echo "Using package manager: $PKG_MGR"

# Configure EPEL repository
ARCH=$(uname -m)
EPEL_MAJOR=7  # works for both AL2 and AL2023
cat >/etc/yum.repos.d/epel.repo <<EOF
[epel]
name=Extra Packages for Enterprise Linux ${EPEL_MAJOR} - \$basearch
baseurl=https://dl.fedoraproject.org/pub/epel/${EPEL_MAJOR}/Everything/${ARCH}
enabled=1
gpgcheck=0
EOF

# Refresh cache and install pass and gnupg2
echo "Installing 'pass' and 'gnupg2'..."
if [[ "$PKG_MGR" == "dnf" ]]; then
  dnf makecache --refresh
  dnf install -y pass gnupg2
else
  yum makecache
  yum install -y pass gnupg2
fi

echo "Installed 'pass' and 'gnupg2'."

# Download docker-credential-pass helper binary
echo "Installing docker-credential-pass helper..."
HELPER_VER="v0.6.4"
case "$ARCH" in
  x86_64) SUFFIX="amd64" ;; 
  aarch64) SUFFIX="arm64" ;; 
  *) echo "Unsupported architecture $ARCH; install helper manually." >&2; exit 1 ;; 
esac
DOWNLOAD_URL="https://github.com/docker/docker-credential-helpers/releases/download/${HELPER_VER}/docker-credential-pass-${HELPER_VER}-linux-${SUFFIX}"
TARGET_BIN="/usr/local/bin/docker-credential-pass"

if curl -fsSL "$DOWNLOAD_URL" -o "$TARGET_BIN"; then
  chmod +x "$TARGET_BIN"
  echo "docker-credential-pass installed at $TARGET_BIN."
else
  echo "Failed to download helper; please install manually from: https://github.com/docker/docker-credential-helpers/releases/tag/${HELPER_VER}" >&2
fi

# Initialize GPG key and pass store for target user
echo "Setting up GPG key and pass for user $TARGET_USER..."

# Generate GPG key if absent
sudo -u "$TARGET_USER" -H bash -c 'gpg --list-secret-keys --keyid-format LONG | grep -q "^sec" || gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 3072
Name-Real: pass user
Expire-Date: 0
%no-protection
EOF'

# Extract GPG key ID
GPG_KEY_ID=$(sudo -u "$TARGET_USER" -H bash -c "gpg --list-secret-keys --keyid-format LONG | awk '/^sec/ {print \$2; exit}' | cut -d'/' -f2")
echo "Using GPG key ID: $GPG_KEY_ID"

# Initialize pass store
sudo -u "$TARGET_USER" -H pass init "$GPG_KEY_ID"
echo "Pass store initialized at $TARGET_HOME/.password-store/."

# Configure Docker credsStore
mkdir -p "$TARGET_HOME/.docker"
cat >"$TARGET_HOME/.docker/config.json" <<EOF
{"credsStore":"pass"}
EOF
chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME/.docker"
echo "Docker credsStore configured for $TARGET_USER."

# Obtain Docker Hub PAT
if [[ -n "$DOCKER_HUB_PAT" ]]; then
  HUB_PAT="$DOCKER_HUB_PAT"
elif [[ -t 0 ]]; then
  read -s -p "Enter Docker Hub Personal Access Token: " HUB_PAT
  echo
else
  echo "Error: set DOCKER_HUB_PAT or run interactively." >&2
  exit 1
fi

# Perform docker login as target user
echo "$HUB_PAT" | sudo -u "$TARGET_USER" docker login --username davidbmar --password-stdin

echo "Docker login succeeded; credentials stored via pass for $TARGET_USER."

