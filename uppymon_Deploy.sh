#!/bin/bash
# UppyMon Auto Installer

set -e

APP_DIR="/opt/uppymon"
TMP_DIR="$(mktemp -d)"
REPO_URL="https://github.com/atabekkadimi/uppymon.git"
PORT=18000

echo "=== UppyMon Auto Installer ==="

# 2. Kill leftover processes
echo "[2/11] Killing leftover processes..."
pkill -f "app.py" || true

# 3. Free port
echo "[3/11] Freeing port $PORT..."
fuser -k $PORT/tcp || true

# 4. Remove old installation
echo "[4/11] Removing old installation..."
rm -rf "$APP_DIR"

# 5. Install system packages
echo "[5/11] Installing system packages..."
apt update
apt install -y git python3 python3-venv python3-pip ufw

# 6. Clone repository
echo "[6/11] Cloning repository..."
git clone "$REPO_URL" "$TMP_DIR"

# 7. Copy app files
echo "[7/11] Copying app files..."
mkdir -p "$APP_DIR"
cp "$TMP_DIR/app.py" "$APP_DIR/"
cp -r "$TMP_DIR/templates" "$APP_DIR/"

# 8. Setup virtual environment
echo "[8/11] Setting up Python virtual environment..."
python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --upgrade pip
"$APP_DIR/venv/bin/pip" install -r "$TMP_DIR/requirements.txt"

# 9. Setup systemd service
echo "[9/11] Creating systemd service..."
SERVICE_FILE="/etc/systemd/system/uppymon.service"

cat > "$SERVICE_FILE" <<EOL
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

systemctl daemon-reload
systemctl enable uppymon

# 10. Start service
echo "[10/11] Starting UppyMon service..."
systemctl restart uppymon

# 11. Cleanup
echo "[11/11] Cleaning temporary files..."
rm -rf "$TMP_DIR"

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:$PORT"
