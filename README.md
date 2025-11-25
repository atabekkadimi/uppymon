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
<pre> 
    sudo ufw allow 18000/tcp
    sudo ufw reload

    # Optional: If using firewalld:
    sudo firewall-cmd --add-port=18000/tcp --permanent
    sudo firewall-cmd --reload
</pre>

## 4 - Configure Systemd (Daemonize)
1. Edit the provided uppymon.service file:
   • Ensure "User=root" (or change to your specific user).
   • Ensure paths match "/opt/uppymon".
2. Copy it to the systemd directory:
<div class="zeroclipboard-container">
<pre>
<code>sudo cp uppymon.service /etc/systemd/system/uppymon.service</code>
</pre>
</div>



