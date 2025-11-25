#!/bin/bash
# ==========================================
# UppyMon Auto Installer
# ==========================================

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

# -------------------------
# [4/11] Install system packages
echo "[4/11] Installing system packages..."
apt update -y
apt install -y git python3 python3-venv python3-pip ufw firewalld curl

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
echo "[8/11] Creating systemd service..."
cat <<EOF | tee /etc/systemd/system/uppymon.service > /dev/null
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

# -------------------------
# [9/11] Start service
echo "[9/11] Starting UppyMon service..."
systemctl start uppymon

# -------------------------
# [10/11] Open port 18000 in firewall
echo "[10/11] Opening port 18000 in ufw..."
ufw allow 18000/tcp || echo "Skipping adding existing rule"
ufw reload || echo "Firewall not enabled (skipping reload)"

echo "[*] Opening port 18000 in firewalld..."
firewall-cmd --zone=public --add-port=18000/tcp --permanent || echo "Warning: ALREADY_ENABLED: 18000:tcp"
firewall-cmd --reload || echo "success"

# -------------------------
# [11/11] Detect public IPs
echo "[11/11] Detecting public IPs..."
IPv4=$(curl -4 -s ifconfig.me || curl -4 -s icanhazip.com || echo "N/A")
IPv6=$(curl -6 -s ifconfig.me || curl -6 -s icanhazip.com || echo "N/A")

# -------------------------
# Final output
echo "=== UppyMon Installed Successfully! ==="
echo "=============================================="
echo " Access your dashboard at "
echo ""
echo "ipv6    http://[$IPv6]:18000"
echo ""
echo "ipv4    http://$IPv4:18000"
echo "=============================================="

# -------------------------
# Cleanup
rm -rf "$TMP_DIR"
