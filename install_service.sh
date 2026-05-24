#!/bin/bash
set -e

# Make sure we are running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SERVICE_FILE="/etc/systemd/system/zapret-discord-youtube.service"

echo "Creating systemd service file..."

cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Zapret DPI Bypass for Discord and YouTube
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/start.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling and starting the service..."
systemctl enable --now zapret-discord-youtube.service

echo "Service installed and started successfully!"
echo "You can check its status with: sudo systemctl status zapret-discord-youtube.service"
