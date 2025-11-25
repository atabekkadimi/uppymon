#!/bin/bash
# UppyMon Auto Installer (Fixed for correct structure)

set -e

APP_DIR="/opt/uppymon"
VENV_DIR="$APP_DIR/venv"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
REPO_URL="https://github.com/atabekkadimi/uppymon.git"
PORT=18000

echo "=== UppyMon Auto Installer ==="

# 1. Kill leftover processes
echo "[1/10] Killing leftover processes..."
pkill -f "python.*app.py" || true

# 2. Free port
echo "[2/10] Freeing port $PORT..."
fuser -k $PORT/tcp || true

# 3. Remove old installation
echo "[3/10] Removing old installation..."
rm -rf "$APP_DIR"

# 4. Install system packages
echo "[4/10] Installing system packages..."
apt update
apt install -y git python3 python3-venv python3-pip ufw

# 5. Clone repository directly to /opt/uppymon
echo "[5/10] Cloning repository..."
git clone "$REPO_URL" "$APP_DIR"

# 6. Create Python virtual environment
echo "[6/10] Creating Python virtual environment..."
python3 -m venv "$VENV_DIR"

# 7. Install Python dependencies if requirements.txt exists
if [ -f "$APP_DIR/requirements.txt" ]; then
    echo "[7/10] Installing Python dependencies..."
    "$VENV_DIR/bin/pip" install --upgrade pip
    "$VENV_DIR/bin/pip" install -r "$APP_DIR/requirements.txt"
else
    echo "[7/10] No requirements.txt found, skipping..."
fi

# 8. Set correct permissions
echo "[8/10] Setting permissions..."
chown -R root:root "$APP_DIR"
chmod -R 755 "$APP_DIR"

# 9. Create systemd service
echo "[9/10] Creating systemd service..."
cat > "$SERVICE_FILE" <<EOL
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
EOL

# 10. Enable and start service
echo "[10/10] Enabling and starting UppyMon..."
systemctl daemon-reload
systemctl enable uppymon
systemctl start uppymon

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:$PORT"
