# uppymon
UppyMon is an uptime monitoring tool that can be deployed on your VPS. This guide will walk you through installing, uninstalling, and troubleshooting.


# UppyMon Deployment

## Quick Install

Copy and paste this command to install UppyMon:

<div class="zeroclipboard-container">
<pre>
<code>bash &lt;(curl -sL https://raw.githubusercontent.com/atabekkadimi/uppymon/main/uppymon_Deploy.sh)</code>
</pre>
</div>

---

## Quick Uninstall

Copy and paste this command to remove UppyMon:

<div class="zeroclipboard-container">
<pre>
<code>bash &lt;(curl -sL https://raw.githubusercontent.com/atabekkadimi/uppymon/main/uppymon_Remove.sh)</code>
</pre>
</div>

# Manual Uninstall

## 1 - Upload Files
Upload the project files to /opt/uppymon. Ensure the structure looks exactly like this:

<pre> 
    /opt/uppymon/app.py 
    /opt/uppymon/requirements.txt 
    /opt/uppymon/uppymon.service 
    /opt/uppymon/templates/index.html <-- Must be inside 'templates' folder 
</pre>

## 2 - Install Dependencies
Create a Python virtual environment and install the required libraries:

<pre> 
    cd /opt/uppymon
    sudo apt update
    sudo apt install python3-venv python3-pip -y

    # Create virtual environment
        python3 -m venv venv
        source venv/bin/activate

    # Install requirements
        printf "flask\nflask_sqlalchemy\nrequests\nwerkzeug\n" > requirements.txt
        pip install -r requirements.txt
        deactivate 
    </pre>

## 3 - Configure Firewall 
Open port 18000 to access the dashboard:
<div class="zeroclipboard-container">
<pre>
<code>sudo ufw allow 18000/tcp
sudo ufw reload</code>
</pre>
</div> 
# Optional: If using firewalld:

<div class="zeroclipboard-container">
<pre>
<code>sudo firewall-cmd --add-port=18000/tcp --permanent
sudo firewall-cmd --reload</code>
</pre>
</div>
    
## 4 - Configure Systemd (Daemonize)
1. Edit the provided uppymon.service file:

    # Ensure "User=root" (or change to your specific user).
    # Ensure paths match "/opt/uppymon".
   
2. Copy it to the systemd directory:
<div class="zeroclipboard-container">
<pre>
<code>sudo cp uppymon.service /etc/systemd/system/uppymon.service</code>
</pre>
</div>

3. Start and enable the service:
<div class="zeroclipboard-container">
<pre>
<code>sudo systemctl daemon-reload
sudo systemctl start uppymon
sudo systemctl enable uppymon</code>
</pre>
</div>


## 5 - Access & Login

1. Open your browser and navigate to:
<pre> http://<YOUR_VPS_IP>:18000 </pre>
2. Default password is: 
<pre> admin </pre>
3. Important: Change the admin password immediately in Settings.

## 6 - Setup Email Alerts
1. In the Settings menu:
   
   # **Gmail Sender:** Your Gmail address

   # **App Password:** Generate a 16-character App Password from Google Account → Security → 2-Step Verification → App Passwords

   # **Receiver Email:** Where you want alerts sent
   
3. Click Save Settings

## 7 - Uninstallation
To completely remove UppyMon:
<div class="zeroclipboard-container">
<pre>
<code>sudo systemctl stop uppymon
sudo systemctl disable uppymon
sudo rm -rf /opt/uppymon
sudo rm -f /etc/systemd/system/uppymon.service
sudo systemctl daemon-reload</code>
</pre>
</div>
