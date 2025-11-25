#!/bin/bash
set -e

echo "=== UppyMon Auto Installer ==="

# ---- CONFIG ----
INSTALL_DIR="/opt/uppymon"
REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
PORT=18000
# ----------------

echo "[1/7] Installing dependencies..."
sudo apt update
sudo apt install -y git python3-venv python3-pip ufw

echo "[2/7] Cloning repository..."
sudo rm -rf $INSTALL_DIR
sudo git clone $REPO_URL $INSTALL_DIR
sudo chown -R $USER:$USER $INSTALL_DIR

echo "[3/7] Setting up Python environment..."
cd $INSTALL_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

echo "[4/7] Firewall configuration..."
sudo ufw allow ${PORT}/tcp || true
sudo ufw reload || true

echo "[5/7] Creating systemd service..."
sudo bash -c "cat > ${SERVICE_FILE}" <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=/opt/uppymon
Environment="PATH=/opt/uppymon/venv/bin"
ExecStart=/opt/uppymon/venv/bin/python /opt/uppymon/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[6/7] Activating systemd service..."
sudo systemctl daemon-reload
sudo systemctl start uppymon
sudo systemctl enable uppymon

echo "[7/7] Installation complete!"
echo "-----------------------------------------"
echo "UppyMon running at: http://YOUR_VPS_IP:18000"
echo "Default login: admin"
echo "-----------------------------------------"
echo "To view logs: sudo journalctl -u uppymon -f"
