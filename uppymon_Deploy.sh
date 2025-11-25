#!/bin/bash
# UppyMon Auto Installer (Safe Reset)

set -e

APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
PORT=18000

echo "=== UppyMon Auto Installer ==="

# 1. Kill leftover processes
echo "[1/11] Killing leftover processes..."
pkill -f "app.py" || true

# 2. Free port 18000
echo "[2/11] Freeing port $PORT..."
fuser -k $PORT/tcp || true

# 3. Remove old installation
echo "[3/11] Removing old installation..."
sudo systemctl stop uppymon || true
sudo rm -rf $APP_DIR
sudo rm -f $SERVICE_FILE

# 4. Install system packages
echo "[4/11] Installing system packages..."
sudo apt update
sudo apt install -y git python3 python3-pip python3-venv ufw

# 5. Clone repository to temporary folder
echo "[5/11] Cloning repository to temporary folder..."
TMP_DIR=$(mktemp -d)
git clone https://github.com/atabekkadimi/uppymon.git $TMP_DIR

# 6. Create app directory
echo "[6/11] Creating app directory..."
sudo mkdir -p $APP_DIR

# 7. Copy app files, templates, and static
echo "[7/11] Copying app contents to $APP_DIR..."
sudo cp -r $TMP_DIR/uppymon/*.py $APP_DIR/
sudo cp -r $TMP_DIR/uppymon/templates $APP_DIR/
sudo cp -r $TMP_DIR/uppymon/static $APP_DIR/ || true

# 8. Setup Python virtual environment and install dependencies
echo "[8/11] Setting up virtual environment..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install flask flask_sqlalchemy requests werkzeug
deactivate

# 9. Setup UFW firewall
echo "[9/11] Configuring UFW firewall..."
sudo ufw allow $PORT/tcp
sudo ufw reload

# 10. Setup systemd service
echo "[10/11] Setting up systemd service..."
sudo bash -c "cat > $SERVICE_FILE" <<EOL
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

sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl start uppymon

# 11. Cleanup
echo "[11/11] Cleaning temporary files..."
rm -rf $TMP_DIR

echo "=== UppyMon Installed Successfully! ==="
echo "Access your dashboard at http://<YOUR_VPS_IP>:$PORT"
e
