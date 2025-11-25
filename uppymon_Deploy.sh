#!/bin/bash
set -e

REPO_URL="https://github.com/atabekkadimi/uppymon.git"
APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"

echo "Updating system..."
apt update -y
apt install -y git python3 python3-venv python3-pip

echo "Cloning repo..."
rm -rf $APP_DIR
git clone $REPO_URL $APP_DIR

echo "Setting permissions..."
chown -R root:root $APP_DIR

echo "Creating virtual environment..."
python3 -m venv $APP_DIR/venv
source $APP_DIR/venv/bin/activate

echo "Installing requirements..."
pip install --upgrade pip
if [ -f "$APP_DIR/requirements.txt" ]; then
    pip install -r $APP_DIR/requirements.txt
fi

echo "Creating systemd service..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=UppyMon Uptime Monitor
After=network.target

[Service]
User=root
WorkingDirectory=/opt/uppymon
ExecStart=/opt/uppymon/venv/bin/python /opt/uppymon/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
systemctl daemon-reload
systemctl enable uppymon
systemctl restart uppymon

echo ""
echo "=============================="
echo "  UppyMon Deployment Complete!"
echo "=============================="
echo "Check logs with: journalctl -u uppymon -f"
