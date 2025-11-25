#!/bin/bash
set -e

echo "=== UppyMon Auto Installer ==="

# 1/11 Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f app.py || true

# 2/11 Free port 18000
echo "[2/11] Freeing port 18000..."
fuser -k 18000/tcp || true

# 3/11 Remove old installation
echo "[3/11] Removing old installation..."
rm -rf /opt/uppymon

# 4/11 Install system packages
echo "[4/11] Installing system packages..."
apt update
apt install -y git python3 python3-pip python3-venv ufw

# 5/11 Clone repository
echo "[5/11] Cloning repository..."
tmpdir=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git "$tmpdir"

# 6/11 Copy app files (correct main structure)
echo "[6/11] Copying app files..."
mkdir -p /opt/uppymon/templates
cp "$tmpdir/app.py" /opt/uppymon/
cp -r "$tmpdir/templates/"* /opt/uppymon/templates/

# 7/11 Set up virtual environment
echo "[7/11] Setting up virtual environment..."
python3 -m venv /opt/uppymon/venv
/opt/uppymon/venv/bin/pip install --upgrade pip
/opt/uppymon/venv/bin/pip install flask flask_sqlalchemy jinja2 requests

# 8/11 Set permissions
echo "[8/11] Setting permissions..."
chown -R root:root /opt/uppymon
chmod -R 755 /opt/uppymon

# 9/11 Create systemd service
echo "[9/11] Creating systemd service..."
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

# 10/11 Reload systemd and enable service
echo "[10/11] Reloading systemd..."
systemctl daemon-reload
systemctl enable uppymon

# 11/11 Start service
echo "[11/11] Starting UppyMon service..."
systemctl restart uppymon

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:18000"
