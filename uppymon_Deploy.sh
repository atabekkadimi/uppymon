#!/bin/bash
set -e

REPO_URL="https://github.com/atabekkadimi/uppymon.git"
APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
PORT=18000

echo "=== UppyMon Auto Installer ==="

echo "[1/7] Installing system packages..."
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip ufw

echo "[2/7] Cloning repo..."
sudo rm -rf $APP_DIR
sudo git clone $REPO_URL $APP_DIR
sudo chown -R root:root $APP_DIR

echo "[3/7] Setting up Python virtual environment..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

echo "[4/7] Configuring firewall..."
sudo ufw allow ${PORT}/tcp || true
sudo ufw reload || true

echo "[5/7] Creating fixed systemd service..."
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

echo "[6/7] Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl restart uppymon

echo "[7/7] Installation complete!"
echo "URL: http://YOUR_VPS_IP:18000"
echo "Default login: admin"
echo "Check logs: sudo journalctl -u uppymon -f"
