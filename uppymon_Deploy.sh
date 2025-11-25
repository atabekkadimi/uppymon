#!/bin/bash
set -e

echo "=== UppyMon Auto Installer ==="

# 1. Stop and remove old service
echo "[1/10] Stopping old service if exists..."
sudo systemctl stop uppymon 2>/dev/null || true
sudo systemctl disable uppymon 2>/dev/null || true

# 2. Kill any process on port 18000
echo "[2/10] Freeing port 18000..."
PID=$(sudo lsof -t -i :18000 || true)
if [ -n "$PID" ]; then
    sudo kill -9 $PID
fi

# 3. Remove old installation
echo "[3/10] Removing old installation..."
sudo rm -rf /opt/uppymon

# 4. Install system dependencies
echo "[4/10] Installing system packages..."
sudo apt update
sudo apt install -y git python3 python3-pip python3-venv ufw

# 5. Clone repository to a temp folder
echo "[5/10] Cloning repository..."
TMPDIR=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git "$TMPDIR"

# 6. Copy only necessary files to /opt/uppymon
echo "[6/10] Copying app files..."
sudo mkdir -p /opt/uppymon
sudo cp "$TMPDIR/app.py" /opt/uppymon/
sudo cp -r "$TMPDIR/templates" /opt/uppymon/

# 7. Setup Python virtual environment
echo "[7/10] Setting up Python virtual environment..."
cd /opt/uppymon
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
# Install requirements if any inside venv
if [ -f "$TMPDIR/requirements.txt" ]; then
    pip install -r "$TMPDIR/requirements.txt"
fi
deactivate

# 8. Create systemd service
echo "[8/10] Creating systemd service..."
sudo tee /etc/systemd/system/uppymon.service > /dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/uppymon
ExecStart=/opt/uppymon/venv/bin/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 9. Reload systemd and start service
echo "[9/10] Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl start uppymon

# 10. Clean up
echo "[10/10] Cleaning up..."
rm -rf "$TMPDIR"

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:18000"
