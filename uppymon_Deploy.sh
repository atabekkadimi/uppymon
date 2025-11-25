#!/bin/bash
set -e

REPO_URL="https://github.com/atabekkadimi/uppymon.git"
APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
PORT=18000

echo "=== UppyMon Auto Installer ==="

# Step 1: Stop existing service if running
if systemctl is-active --quiet uppymon; then
    echo "[1/11] Stopping existing service..."
    sudo systemctl stop uppymon
fi

# Step 2: Kill leftover processes
echo "[2/11] Killing leftover processes..."
sudo pkill -f "$APP_DIR/app.py" || true

# Step 3: Free port 18000 if used
echo "[3/11] Freeing port $PORT..."
sudo fuser -k $PORT/tcp || true

# Step 4: Remove old installation
echo "[4/11] Removing old installation..."
sudo rm -rf $APP_DIR

# Step 5: Install system packages
echo "[5/11] Installing system packages..."
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip ufw

# Step 6: Clone repo to temporary folder
TMP_DIR=$(mktemp -d)
echo "[6/11] Cloning repository to temporary folder..."
git clone $REPO_URL $TMP_DIR

# Step 7: Copy contents of repo to /opt/uppymon (flattened)
echo "[7/11] Copying app contents to $APP_DIR..."
sudo mkdir -p $APP_DIR
sudo cp -r $TMP_DIR/uppymon/* $APP_DIR/
sudo cp -r $TMP_DIR/uppymon/.* $APP_DIR/ 2>/dev/null || true
sudo rm -rf $TMP_DIR

# Step 8: Setup Python virtual environment
echo "[8/11] Setting up virtual environment..."
cd $APP_DIR
python3 -m venv venv
$APP_DIR/venv/bin/pip install --upgrade pip

# Step 8a: Install required Python packages
echo "[8a/11] Installing Python dependencies..."
$APP_DIR/venv/bin/pip install flask flask_sqlalchemy requests werkzeug

# Step 9: Configure firewall
echo "[9/11] Configuring firewall..."
sudo ufw allow ${PORT}/tcp || true
sudo ufw reload || true

# Step 10: Create systemd service
echo "[10/11] Creating systemd service..."
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Step 11: Enable and start service
echo "[11/11] Enabling and starting UppyMon service..."
sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl restart uppymon

echo ""
echo "=============================================="
echo " UppyMon Deployment Complete! Service running."
echo " URL: http://YOUR_VPS_IP:18000"
echo " Default login: admin"
echo " Logs: sudo journalctl -u uppymon -f"
echo "=============================================="
