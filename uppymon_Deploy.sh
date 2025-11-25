#!/bin/bash

echo "=== UppyMon Auto Installer ==="

# 1. Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f app.py &>/dev/null || true

# 2. Free port 18000
echo "[2/11] Freeing port 18000..."
fuser -k 18000/tcp &>/dev/null || true

# 3. Remove old installation
echo "[3/11] Removing old installation..."
rm -rf /opt/uppymon

# 4. Install system packages
echo "[4/11] Installing system packages..."
apt update -y
apt install -y git python3 python3-pip python3-venv ufw firewalld curl

# 5. Clone repository
echo "[5/11] Cloning repository..."
TMP_DIR=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git "$TMP_DIR"

# 6. Copy files
echo "[6/11] Copying app files..."
mkdir -p /opt/uppymon/templates
cp "$TMP_DIR/app.py" /opt/uppymon/
cp -r "$TMP_DIR/templates/"* /opt/uppymon/templates/

# 7. Create Python virtual environment
echo "[7/11] Setting up Python virtual environment..."
python3 -m venv /opt/uppymon/venv

# 8. Install Python dependencies
echo "[8/11] Installing Python packages..."
/opt/uppymon/venv/bin/pip install --upgrade pip
/opt/uppymon/venv/bin/pip install flask flask_sqlalchemy jinja2 requests

# 9. Setup systemd service
echo "[9/11] Creating systemd service..."
tee /etc/systemd/system/uppymon.service > /dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/uppymon
ExecStart=/opt/uppymon/venv/bin/python /opt/uppymon/app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable uppymon
systemctl restart uppymon

# 10. Open firewall port
echo "[10/11] Configuring firewall..."
ufw allow 18000/tcp
firewall-cmd --permanent --add-port=18000/tcp
firewall-cmd --reload

# 11. Cleanup and output
echo "[11/11] Cleaning up..."
rm -rf "$TMP_DIR"

# Detect public IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "<YOUR_VPS_IP>")

echo "=== UppyMon Installed Successfully! ==="
# Final output
echo "=============================================="
echo " Access your dashboard at "
echo " http://$SERVER_IP:18000"
echo "=============================================="
