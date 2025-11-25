#!/bin/bash
# ==========================================
# UppyMon Auto Installer
# ==========================================

set -e

echo "=== UppyMon Auto Installer ==="

# -------------------------
# 1/11 Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f app.py || true

# -------------------------
# 2/11 Free port 18000
echo "[2/11] Freeing port 18000..."
fuser -k 18000/tcp || true

# -------------------------
# 3/11 Remove old installation
echo "[3/11] Removing old installation..."
rm -rf /opt/uppymon
rm -f /etc/systemd/system/uppymon.service

# -------------------------
# 4/11 Install system packages
echo "[4/11] Installing system packages..."
apt update -y
apt install -y git python3 python3-pip python3-venv ufw firewalld curl

# -------------------------
# 5/11 Clone repository
echo "[5/11] Cloning repository..."
tmpdir=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git "$tmpdir"

# -------------------------
# 6/11 Copy app files
echo "[6/11] Copying app files..."
mkdir -p /opt/uppymon/templates
cp "$tmpdir"/app.py /opt/uppymon/
cp -r "$tmpdir"/templates/* /opt/uppymon/templates/

# -------------------------
# 7/11 Setup Python virtualenv
echo "[7/11] Setting up Python virtual environment..."
python3 -m venv /opt/uppymon/venv
/opt/uppymon/venv/bin/pip install --upgrade pip
/opt/uppymon/venv/bin/pip install flask flask_sqlalchemy requests jinja2

# -------------------------
# 8/11 Setup systemd service
echo "[8/11] Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/uppymon.service > /dev/null
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

sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl start uppymon

# -------------------------
# 9/11 Open port 18000 in firewalls
echo "[9/11] Opening port 18000..."
# ufw
ufw allow 18000/tcp || echo "Skipping adding existing rule"
ufw reload || true
# firewalld
if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --zone=public --add-port=18000/tcp --permanent || echo "Skipping existing rule"
    firewall-cmd --reload || true
fi

# -------------------------
# 10/11 Clean up
echo "[10/11] Cleaning up..."
rm -rf "$tmpdir"

# -------------------------
# 11/11 Detect public IPs
echo "[11/11] Detecting public IPs..."
IPv4=$(curl -4 -s ifconfig.me || curl -4 -s icanhazip.com)
IPv6=$(curl -6 -s ifconfig.me || curl -6 -s icanhazip.com)

[ -z "$IPv4" ] && IPv4="N/A"
[ -z "$IPv6" ] && IPv6="N/A"

# -------------------------
# Final output
echo "=============================================="
echo " Access your dashboard at"
echo ""
echo "ipv6    http://[$IPv6]:18000"
echo "ipv4    http://$IPv4:18000"
echo "=============================================="
echo "=== UppyMon Installed Successfully! ==="
