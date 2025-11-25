#!/bin/bash
# === UppyMon Auto Installer ===

APP_DIR="/opt/uppymon"
TMP_DIR=$(mktemp -d)
REPO_URL="https://github.com/atabekkadimi/uppymon.git"
PORT=18000

echo "=== UppyMon Auto Installer ==="

# 1. Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f "python.*app.py" 2>/dev/null || true

# 2. Free port
echo "[2/11] Freeing port $PORT..."
fuser -k $PORT/tcp 2>/dev/null || true

# 3. Remove old installation
echo "[3/11] Removing old installation..."
rm -rf "$APP_DIR"

# 4. Install system packages
echo "[4/11] Installing system packages..."
apt update
apt install -y git python3 python3-venv python3-pip ufw

# 5. Clone repository
echo "[5/11] Cloning repository..."
git clone "$REPO_URL" "$TMP_DIR"

# 6. Copy app files
echo "[6/11] Copying app files..."
mkdir -p "$APP_DIR"
cp "$TMP_DIR/app.py" "$APP_DIR/"
cp -r "$TMP_DIR/templates" "$APP_DIR/"

# 7. Setup virtual environment
echo "[7/11] Setting up Python virtual environment..."
python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --upgrade pip
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt" 2>/dev/null || true

# 8. Create systemd service
echo "[8/11] Creating systemd service..."
cat > /etc/systemd/system/uppymon.service <<EOL
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# 9. Reload systemd
echo "[9/11] Reloading systemd..."
systemctl daemon-reload

# 10. Enable and start service
echo "[10/11] Enabling and starting UppyMon service..."
systemctl enable uppymon
systemctl restart uppymon

# 11. Cleanup
echo "[11/11] Cleaning up..."
rm -rf "$TMP_DIR"

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:$PORT"
