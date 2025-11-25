#!/bin/bash
# UppyMon Auto Installer (Flat Structure)

APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"

echo "=== UppyMon Auto Installer ==="

# 1. Stop service if running
echo "[1/10] Stopping any running service..."
sudo systemctl stop uppymon 2>/dev/null

# 2. Kill leftover processes
echo "[2/10] Killing leftover processes..."
sudo pkill -f "/opt/uppymon/venv/bin/python" 2>/dev/null || true

# 3. Free port 18000 if occupied
echo "[3/10] Freeing port 18000..."
sudo fuser -k 18000/tcp 2>/dev/null || true

# 4. Remove old installation
echo "[4/10] Removing old installation..."
sudo rm -rf "$APP_DIR"

# 5. Install system packages
echo "[5/10] Installing dependencies..."
sudo apt update -y
sudo apt install -y git python3 python3-pip python3-venv ufw

# 6. Clone repository to temporary folder
TMP_DIR=$(mktemp -d)
echo "[6/10] Cloning repository..."
git clone https://github.com/atabekkadimi/uppymon.git "$TMP_DIR"

# 7. Copy files to APP_DIR
echo "[7/10] Setting up application directory..."
sudo mkdir -p "$APP_DIR"
sudo cp -r "$TMP_DIR/"* "$APP_DIR/"

# 8. Setup virtual environment
echo "[8/10] Setting up virtual environment..."
cd "$APP_DIR" || exit
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install flask jinja2

# 9. Create systemd service
echo "[9/10] Creating systemd service..."
sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 10. Reload systemd and start service
echo "[10/10] Starting UppyMon service..."
sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl restart uppymon

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:18000"
