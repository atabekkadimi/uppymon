#!/bin/bash
set -e

INSTALL_DIR="/opt/uppymon"
REPO_URL="https://github.com/atabekkadimi/uppymon.git"

echo "=== UppyMon Auto Installer ==="

# Stop old service if exists
echo "[1/11] Stopping leftover service..."
sudo systemctl stop uppymon || true

# Remove old installation
echo "[2/11] Removing old installation..."
sudo rm -rf "$INSTALL_DIR"

# Create install directory
sudo mkdir -p "$INSTALL_DIR"

# Clone repository to temp folder
echo "[3/11] Cloning repository..."
TMP_DIR=$(mktemp -d)
git clone "$REPO_URL" "$TMP_DIR"

# Copy only the main files
echo "[4/11] Copying app files..."
sudo cp "$TMP_DIR/app.py" "$INSTALL_DIR/"
sudo cp -r "$TMP_DIR/templates" "$INSTALL_DIR/"

# Clean temp
rm -rf "$TMP_DIR"

# Setup virtual environment
echo "[5/11] Setting up virtual environment..."
python3 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip
"$INSTALL_DIR/venv/bin/pip" install flask requests jinja2

# Setup systemd service
echo "[6/11] Setting up systemd service..."
sudo tee /etc/systemd/system/uppymon.service > /dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl restart uppymon

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:18000"
