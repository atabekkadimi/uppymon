#!/bin/bash
# UppyMon Auto Installer (Corrected Structure)

set -e

echo "=== UppyMon Auto Installer ==="

APP_DIR="/opt/uppymon"
REPO_URL="https://github.com/atabekkadimi/uppymon.git"
VENV_DIR="$APP_DIR/venv"

# 1. Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f "app.py" || true

# 2. Free port 18000
echo "[2/11] Freeing port 18000..."
fuser -k 18000/tcp || true

# 3. Remove old installation
echo "[3/11] Removing old installation..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

# 4. Install system packages
echo "[4/11] Installing system packages..."
apt update -y
apt install -y git python3 python3-venv python3-pip ufw

# 5. Clone repository to temporary folder
echo "[5/11] Cloning repository..."
TMP_DIR=$(mktemp -d)
git clone "$REPO_URL" "$TMP_DIR"

# 6. Copy only uppymon folder contents to APP_DIR
echo "[6/11] Copying app files..."
cp "$TMP_DIR/uppymon/app.py" "$APP_DIR/"
cp -r "$TMP_DIR/uppymon/templates" "$APP_DIR/"

# 7. Setup Python virtual environment
echo "[7/11] Setting up Python virtual environment..."
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "$TMP_DIR/uppymon/requirements.txt"

# 8. Clean up temporary folder
echo "[8/11] Cleaning up..."
rm -rf "$TMP_DIR"

# 9. Setup systemd service
echo "[9/11] Setting up systemd service..."
SERVICE_FILE="/etc/systemd/system/uppymon.service"
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=$VENV_DIR/bin/python $APP_DIR/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 10. Reload systemd and enable service
echo "[10/11] Enabling and starting service..."
systemctl daemon-reload
systemctl enable uppymon
systemctl restart uppymon

# 11. Finished
echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:18000"
