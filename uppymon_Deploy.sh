#!/bin/bash
set -e

REPO_URL="https://github.com/atabekkadimi/uppymon.git"
APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
PORT=18000

echo "=== UppyMon Auto Installer (Safe Reset) ==="

# ---- Step 1: Stop existing service if running ----
if systemctl is-active --quiet uppymon; then
    echo "[1/8] Stopping existing service..."
    sudo systemctl stop uppymon
fi

echo "[2/8] Killing any leftover processes..."
sudo pkill -f "$APP_DIR/app.py" || true

# ---- Step 2: Remove old installation ----
echo "[3/8] Removing old installation..."
sudo rm -rf $APP_DIR

# ---- Step 3: Install system packages ----
echo "[4/8] Installing dependencies..."
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip ufw

# ---- Step 4: Clone repo ----
echo "[5/8] Cloning repo..."
sudo git clone $REPO_URL $APP_DIR
sudo chown -R root:root $APP_DIR

# ---- Step 5: Setup Python virtualenv ----
echo "[6/8] Setting up virtual environment..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# ---- Step 6: Configure firewall ----
echo "[7/8] Configuring firewall..."
sudo ufw allow ${PORT}/tcp || true
sudo ufw reload || true

# ---- Step 7: Create systemd service ----
echo "[8/8] Creating systemd service..."
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=/bin/bash -c 'source $APP_DIR/venv/bin/activate && python $APP_DIR/app.py'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl restart uppymon

echo ""
echo "=============================================="
echo " UppyMon Deployment Complete! Service running."
echo " URL: http://YOUR_VPS_IP:18000"
echo " Default login: admin"
echo " Logs: sudo journalctl -u uppymon -f"
echo "=============================================="
#!/bin/bash
set -e

REPO_URL="https://github.com/atabekkadimi/uppymon.git"
APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"
PORT=18000

echo "=== UppyMon Auto Installer (Safe Reset) ==="

# ---- Step 1: Stop existing service if running ----
if systemctl is-active --quiet uppymon; then
    echo "[1/8] Stopping existing service..."
    sudo systemctl stop uppymon
fi

echo "[2/8] Killing any leftover processes..."
sudo pkill -f "$APP_DIR/app.py" || true

# ---- Step 2: Remove old installation ----
echo "[3/8] Removing old installation..."
sudo rm -rf $APP_DIR

# ---- Step 3: Install system packages ----
echo "[4/8] Installing dependencies..."
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip ufw

# ---- Step 4: Clone repo ----
echo "[5/8] Cloning repo..."
sudo git clone $REPO_URL $APP_DIR
sudo chown -R root:root $APP_DIR

# ---- Step 5: Setup Python virtualenv ----
echo "[6/8] Setting up virtual environment..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# ---- Step 6: Configure firewall ----
echo "[7/8] Configuring firewall..."
sudo ufw allow ${PORT}/tcp || true
sudo ufw reload || true

# ---- Step 7: Create systemd service ----
echo "[8/8] Creating systemd service..."
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
ExecStart=/bin/bash -c 'source $APP_DIR/venv/bin/activate && python $APP_DIR/app.py'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable uppymon
sudo systemctl restart uppymon

echo ""
echo "=============================================="
echo " UppyMon Deployment Complete! Service running."
echo " URL: http://YOUR_VPS_IP:18000"
echo " Default login: admin"
echo " Logs: sudo journalctl -u uppymon -f"
echo "=============================================="
