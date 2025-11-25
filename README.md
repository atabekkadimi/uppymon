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

<pre> ```text /opt/uppymon/app.py /opt/uppymon/requirements.txt /opt/uppymon/uppymon.service /opt/uppymon/templates/index.html <-- Must be inside 'templates' folder ``` </pre>
