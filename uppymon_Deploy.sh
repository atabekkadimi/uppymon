#!/bin/bash
set -e

REPO_URL="https://github.com/atabekkadimi/uppymon.git"
APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
PORT=18000

echo "=== UppyMon Auto Installer (Safe Reset + Requirements Check) ==="

# Step 1: Stop existing service if running
if systemctl is-active --quiet uppymon; then
    echo "[1/9] Stopping existing service..."
    sudo systemctl stop uppymon
fi

# Step 2: Kill leftover processes
echo "[2/9] Killing leftover processes..."
sudo pkill -f "$APP_DIR/app.py" || true

# Step 3: Remove old installation
echo "[3/9] Removing old installation..."
sudo rm -rf $APP_DIR

# Step 4: Install system packages
echo "[4/9] Installing dependencies..."
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip ufw

# Step 5: Clone repo
echo "[5/9] Cloning repository..."
sudo git clone $REPO_URL $APP_DIR
sudo chown -R root:root $APP_DIR

# Step 6: Setup Python virtual environment
echo "[6/9] Setting up virtual environment..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

# Step 6a: Install Python packages
if [ -f "requirements.txt" ]; then
    echo "[INFO] Installing packages from requirements.txt..."
    pip install -r requirements.txt
else
    echo "[INFO] No requirements.txt found. Installing default packages..."
    pip install flask flask_sqlalchemy requests werkzeug
fi
deactivate

# Step 7: Configure firewall
echo "[7/9] Configuring firewall..."
sudo ufw allow ${PORT}/tcp || true
sudo ufw reload || true

# Step 8: Create systemd service
echo "[8/9] Creating systemd service..."
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=/bin/bash -c 'source $APP_DIR/venv/bin/activate && python $APP_DIR/app.py'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Step 9: Enable and start service
echo "[9/9] Enabling and starting UppyMon service..."
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
