#!/bin/bash
set -e

echo "=== UppyMon Auto Installer ==="

# -------------------------
# [1/11] Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f app.py || true

# -------------------------
# [2/11] Free port 18000
echo "[2/11] Freeing port 18000..."
fuser -k 18000/tcp || true

# -------------------------
# [3/11] Remove old installation
echo "[3/11] Removing old installation..."
rm -rf /opt/uppymon
rm -f /etc/systemd/system/uppymon.service

# -------------------------
# [4/11] Install system packages
echo "[4/11] Installing system packages..."
apt update -y
apt install -y git python3 python3-pip python3-venv ufw firewalld

# -------------------------
# [5/11] Clone repository
echo "[5/11] Cloning repository..."
TMP_DIR=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git "$TMP_DIR"

# -------------------------
# [6/11] Copy app files
echo "[6/11] Copying app files..."
mkdir -p /opt/uppymon/templates
cp "$TMP_DIR/app.py" /opt/uppymon/
cp -r "$TMP_DIR/templates/"* /opt/uppymon/templates/

# -------------------------
# [7/11] Setup Python virtual environment
echo "[7/11] Setting up Python virtual environment..."
python3 -m venv /opt/uppymon/venv
/opt/uppymon/venv/bin/pip install --upgrade pip
/opt/uppymon/venv/bin/pip install flask flask_sqlalchemy jinja2 requests

# -------------------------
# [8/11] Setup systemd service
echo "[8/11] Setting up systemd service..."
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
systemctl start uppymon

# -------------------------
# [9/11] Configure firewall
echo "[9/11] Opening port 18000 in UFW..."
ufw allow 18000/tcp || echo "Skipping adding existing rule"
ufw reload || true

echo "[*] Opening port 18000 in firewalld..."
firewall-cmd --add-port=18000/tcp --permanent || echo "Warning: ALREADY_ENABLED: 18000:tcp"
firewall-cmd --reload || true

# -------------------------
# [10/11] Cleanup temporary files
echo "[10/11] Cleaning up..."
rm -rf "$TMP_DIR"

# -------------------------
# [11/11] Detect public IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "<YOUR_VPS_IP>")

# -------------------------
# Final output
echo "=============================================="
echo " Access your dashboard at "
echo " http://$SERVER_IP:18000"
echo "=============================================="
