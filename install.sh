#!/bin/bash
set -e

# Make sure we are running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

echo "Installing required dependencies for building nfqws on Fedora..."
dnf install -y gcc make libnetfilter_queue-devel libcap-devel libmnl-devel libnfnetlink-devel zlib-devel git iptables

echo "Cloning zapret repository..."
rm -rf /tmp/zapret-build
git clone --depth 1 https://github.com/bol-van/zapret.git /tmp/zapret-build

echo "Building nfqws..."
cd /tmp/zapret-build
make -C nfq

echo "Copying compiled nfqws binary to the local bin/ folder..."
# Go back to the script's directory
cd "$SCRIPT_DIR"
mkdir -p bin
cp /tmp/zapret-build/nfq/nfqws bin/

echo "Cleaning up..."
rm -rf /tmp/zapret-build

echo "Installation complete. The nfqws binary is now in the bin/ directory."
