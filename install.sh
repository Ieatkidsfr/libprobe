#!/bin/bash
# libprobe installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Ieatkidsfr/libprobe/main/install.sh | bash

REPO="https://raw.githubusercontent.com/Ieatkidsfr/libprobe/main"
INSTALL_DIR="/usr/local/bin"

echo "Installing libprobe..."

curl -fsSL "$REPO/probe.sh" -o /tmp/libprobe
chmod +x /tmp/libprobe
sudo mv /tmp/libprobe "$INSTALL_DIR/libprobe"

echo "Done! Run: libprobe"
