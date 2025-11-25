#!/bin/bash
set -e

APP_DIR="/opt/uppymon"
SERVICE_FILE="/etc/systemd/system/uppymon.service"

echo "=== UppyMon Uninstall Script ==="

# Step 1: Stop the service if running
if systemctl is-active --quiet uppymon; then
    echo "[1/5] Stopping UppyMon service..."
    sudo systemctl stop uppymon
fi

# Step 2: Disable service at startup
if systemctl is-enabled --quiet uppymon; then
    echo "[2/5] Disabling service from startup..."
    sudo systemctl disable uppymon
fi

# Step 3: Kill any leftover processes
echo "[3/5] Killing leftover processes..."
sudo pkill -f "$APP_DIR/app.py" || true

# Step 4: Remove application files
if [ -d "$APP_DIR" ]; then
    echo "[4/5] Removing application folder..."
    sudo rm -rf "$APP_DIR"
fi

# Step 5: Remove systemd service file
if [ -f "$SERVICE_FILE" ]; then
    echo "[5/5] Removing systemd service file..."
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
fi

echo ""
echo "=============================================="
echo " UppyMon has been completely uninstalled!"
echo "=============================================="
