#!/bin/bash
# ==============================================
#          UppyMon Auto Installer
# ==============================================

set -e

echo "=== UppyMon Auto Installer ==="

# 1. Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f app.py || true

# 2. Free port 18000
echo "[2/11] Freeing port 18000..."
fuser -k 18000/tcp || true

# 3. Remove old installation
echo "[3/11] Removing old installation..."
rm -rf /opt/uppymon

# 4. Install system packages
echo "[4/11] Installing system packages..."
apt update
apt install -y git python3 python3-venv python3-pip ufw firewalld

# 5. Clone repository
echo "[5/11] Cloning repository..."
TMP_DIR=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git "$TMP_DIR"

# 6. Copy files to /opt/uppymon
echo "[6/11] Copying app files..."
mkdir -p /opt/uppymon/templates
cp "$TMP_DIR/app.py" /opt/uppymon/
cp -r "$TMP_DIR/templates/"* /opt/uppymon/templates/

# Clean temp directory
rm -rf "$TMP_DIR"

# 7. Create virtual environment
echo "[7/11] Setting up Python virtual environment..."
python3 -m venv /opt/uppymon/venv
/opt/uppymon/venv/bin/pip install --upgrade pip
/opt/uppymon/venv/bin/pip install flask jinja2 requests flask_sqlalchemy

# 8. Create systemd service
echo "[8/11] Creating systemd service..."
sudo tee /etc/systemd/system/uppymon.service > /dev/null <<EOF
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

# 9. Enable and start service
echo "[9/11] Enabling and starting UppyMon service..."
sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl start uppymon

# 10. Configure firewall
echo "[10/11] Configuring firewall rules..."
# UFW
if command -v ufw >/dev/null 2>&1; then
    echo "[*] Opening port 18000 in UFW..."
    sudo ufw allow 18000/tcp
    sudo ufw reload
fi
# Firewalld
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "[*] Opening port 18000 in firewalld..."
    sudo firewall-cmd --permanent --add-port=18000/tcp
    sudo firewall-cmd --reload
fi

# 11. Cleanup
echo "[11/11] Cleaning up..."
echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:18000"
