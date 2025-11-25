#!/bin/bash
# ==============================================
#           UppyMon Auto Installer
# ==============================================

# 1/11 Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f app.py 2>/dev/null || true

# 2/11 Free port 18000
echo "[2/11] Freeing port 18000..."
fuser -k 18000/tcp 2>/dev/null || true

# 3/11 Remove old installation
echo "[3/11] Removing old installation..."
rm -rf /opt/uppymon

# 4/11 Install system packages
echo "[4/11] Installing system packages..."
apt update -y
apt install -y git python3 python3-venv python3-pip ufw firewalld curl

# 5/11 Clone repository
echo "[5/11] Cloning repository..."
TMP_DIR=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git "$TMP_DIR"

# 6/11 Copy app files (correct structure)
echo "[6/11] Copying app files..."
mkdir -p /opt/uppymon/templates
cp "$TMP_DIR"/app.py /opt/uppymon/
cp -r "$TMP_DIR"/templates/* /opt/uppymon/templates/

# Remove temp folder
rm -rf "$TMP_DIR"

# 7/11 Create virtual environment
echo "[7/11] Creating Python virtual environment..."
python3 -m venv /opt/uppymon/venv

# 8/11 Install Python dependencies
echo "[8/11] Installing Python dependencies..."
/opt/uppymon/venv/bin/pip install --upgrade pip
/opt/uppymon/venv/bin/pip install flask flask_sqlalchemy jinja2 requests

# 9/11 Setup systemd service
echo "[9/11] Setting up systemd service..."
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

# 10/11 Open firewall port 18000
echo "[10/11] Opening port 18000..."
ufw allow 18000/tcp || echo "Skipping adding existing rule"
firewall-cmd --add-port=18000/tcp --permanent || echo "Skipping adding existing rule"
firewall-cmd --reload || echo "Firewall reload skipped"

# 11/11 Detect public IPs
echo "[11/11] Detecting public IPs..."
IPv4=$(curl -4 -s ifconfig.me || curl -4 -s icanhazip.com || echo "N/A")
IPv6=$(curl -6 -s ifconfig.me || curl -6 -s icanhazip.com || echo "N/A")

# Final output
echo "=============================================="
echo " Access your dashboard at"
echo ""

[ "$IPv6" != "N/A" ] && echo "ipv6    http://[$IPv6]:18000"
[ "$IPv4" != "N/A" ] && echo "ipv4    http://$IPv4:18000"

echo "=============================================="
echo "=== UppyMon Installed Successfully! ==="
