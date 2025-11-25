import time
import threading
import subprocess
import smtplib
import datetime
import platform
import logging
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import Flask, jsonify, request, render_template
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy.exc import OperationalError

# Configuration
PORT = 18000
DB_FILE = "uppymon.db"
DEFAULT_ADMIN_PASSWORD = "admin" 

app = Flask(__name__)
# Use absolute path to avoid confusion with working directories
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, DB_FILE)
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{DB_PATH}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Reduce logging noise
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

db = SQLAlchemy(app)

# --- Models ---

class GlobalConfig(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    sender_email = db.Column(db.String(120), default="")
    sender_password = db.Column(db.String(120), default="")
    receiver_email = db.Column(db.String(120), default="")
    check_interval = db.Column(db.Integer, default=60)
    retry_count = db.Column(db.Integer, default=3)
    timeout_sec = db.Column(db.Integer, default=2)
    admin_password_hash = db.Column(db.String(256), nullable=False)

class Server(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    address = db.Column(db.String(120), nullable=False)
    current_status = db.Column(db.String(10), default="UNKNOWN")
    last_checked = db.Column(db.DateTime, nullable=True)
    last_online = db.Column(db.DateTime, nullable=True)
    fail_count = db.Column(db.Integer, default=0)

# --- Helpers ---

def get_config():
    """
    Retrieves config, creating default if necessary.
    """
    conf = GlobalConfig.query.first()
    if not conf:
        print("[*] Creating default GlobalConfig.")
        conf = GlobalConfig(admin_password_hash=generate_password_hash(DEFAULT_ADMIN_PASSWORD))
        db.session.add(conf)
        db.session.commit()
    elif not conf.admin_password_hash:
        print("[*] Updating admin hash for existing config.")
        conf.admin_password_hash = generate_password_hash(DEFAULT_ADMIN_PASSWORD)
        db.session.commit()
    return conf

def send_email(subject, body, config):
    if not config.sender_email or not config.sender_password or not config.receiver_email:
        print("[!] Email not configured, skipping alert.")
        return

    try:
        msg = MIMEMultipart()
        msg['From'] = config.sender_email
        msg['To'] = config.receiver_email
        msg['Subject'] = f"[UppyMon] {subject}"
        msg.attach(MIMEText(body, 'plain'))

        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(config.sender_email, config.sender_password)
        text = msg.as_string()
        server.sendmail(config.sender_email, config.receiver_email, text)
        server.quit()
        print(f"[+] Email sent.")
    except Exception as e:
        print(f"[!] Failed to send email: {e}")

def ping_host(host, timeout=2):
    param = '-n' if platform.system().lower() == 'windows' else '-c'
    timeout_param = '-w' if platform.system().lower() == 'windows' else '-W'
    command = ['ping', param, '1', timeout_param, str(timeout), host]
    try:
        return subprocess.call(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0
    except Exception:
        return False

# --- Background Monitor ---

def monitor_loop():
    print(" [*] Monitor thread started.")
    with app.app_context():
        while True:
            try:
                conf = get_config()
                servers = Server.query.all()
                interval = conf.check_interval if conf.check_interval > 5 else 5
                
                for server in servers:
                    is_up = ping_host(server.address, conf.timeout_sec)
                    timestamp = datetime.datetime.now()
                    
                    if is_up:
                        server.fail_count = 0
                        server.last_online = timestamp
                        if server.current_status == "DOWN":
                            server.current_status = "UP"
                            send_email(f"RECOVERY: {server.name} is UP", f"{server.name} is back online.", conf)
                        elif server.current_status == "UNKNOWN":
                            server.current_status = "UP"
                    else:
                        server.fail_count += 1
                        if server.current_status != "DOWN" and server.fail_count >= conf.retry_count:
                            server.current_status = "DOWN"
                            send_email(f"ALERT: {server.name} is DOWN", f"{server.name} failed {server.fail_count} pings.", conf)
                    
                    server.last_checked = timestamp
                    db.session.commit()
                
                for _ in range(int(interval)):
                    time.sleep(1) 

            except Exception as e:
                print(f"[!] Monitor Loop Error: {e}")
                time.sleep(5)

# --- API Routes ---

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/auth', methods=['POST'])
def authenticate():
    data = request.json
    password = data.get('password')
    conf = get_config()
    if password and check_password_hash(conf.admin_password_hash, password):
        return jsonify({'success': True}), 200
    return jsonify({'success': False, 'message': 'Invalid Password'}), 401

@app.route('/api/status', methods=['GET'])
def get_status():
    servers = Server.query.all()
    output = []
    for s in servers:
        output.append({
            'id': s.id,
            'name': s.name,
            'address': s.address,
            'status': s.current_status,
            'last_checked': s.last_checked.strftime("%Y-%m-%d %H:%M:%S") if s.last_checked else "Never",
            'last_online': s.last_online.strftime("%Y-%m-%d %H:%M:%S") if s.last_online else "Never"
        })
    return jsonify(output)

@app.route('/api/server', methods=['POST'])
def add_server():
    data = request.json
    new_server = Server(name=data['name'], address=data['address'])
    db.session.add(new_server)
    db.session.commit()
    return jsonify({'message': 'Server added'})

@app.route('/api/server/<int:id>', methods=['DELETE', 'POST']) # <-- UPDATED: Added POST
def delete_server(id):
    try:
        server = Server.query.get(id)
        if server:
            db.session.delete(server)
            db.session.commit()
            print(f"[+] Deleted server ID: {id}")
            return jsonify({'message': 'Deleted'}), 200
        return jsonify({'error': 'Server not found'}), 404
    except Exception as e:
        db.session.rollback()
        print(f"[!] DB Error on deletion of ID {id}: {e}")
        return jsonify({'error': 'Internal server error during deletion'}), 500

@app.route('/api/trigger/<int:id>', methods=['POST'])
def trigger_ping(id):
    server = Server.query.get(id)
    conf = get_config()
    if server:
        is_up = ping_host(server.address, conf.timeout_sec)
        server.last_checked = datetime.datetime.now()
        server.current_status = "UP" if is_up else server.current_status
        db.session.commit()
        return jsonify({'status': server.current_status})
    return jsonify({'error': 'Not found'}), 404

@app.route('/api/config', methods=['GET', 'POST'])
def handle_config():
    conf = get_config()
    if request.method == 'POST':
        data = request.json
        if 'sender_email' in data: conf.sender_email = data['sender_email']
        if 'sender_password' in data: conf.sender_password = data['sender_password']
        if 'receiver_email' in data: conf.receiver_email = data['receiver_email']
        if 'check_interval' in data: conf.check_interval = int(data['check_interval'])
        if 'retry_count' in data: conf.retry_count = int(data['retry_count'])
        if 'timeout_sec' in data: conf.timeout_sec = int(data['timeout_sec'])
        if 'admin_password' in data and data['admin_password'] and data['admin_password'] != '**********':
            conf.admin_password_hash = generate_password_hash(data['admin_password'])
        db.session.commit()
        return jsonify({'message': 'Saved'})
    return jsonify({
        'sender_email': conf.sender_email,
        'sender_password': conf.sender_password,
        'receiver_email': conf.receiver_email,
        'check_interval': conf.check_interval,
        'retry_count': conf.retry_count,
        'timeout_sec': conf.timeout_sec,
        'admin_password': '**********'
    })

# --- Entry Point with Auto-Recovery ---

def init_db():
    with app.app_context():
        print(f"[*] Database Path: {DB_PATH}")
        try:
            # Try to create tables (no-op if they exist)
            db.create_all()
            # Try to query to ensure schema matches
            get_config()
        except OperationalError as e:
            if "no such column" in str(e):
                print("[!] Schema mismatch detected (Missing Columns).")
                print("[!] PERFORMING AUTO-RECOVERY: Dropping and Recreating Database...")
                db.drop_all()
                db.create_all()
                get_config()
                print("[+] Recovery successful. Database rebuilt.")
            else:
                raise e

if __name__ == '__main__':
    init_db()
    monitor_thread = threading.Thread(target=monitor_loop, daemon=True)
    monitor_thread.start()
    print(f"Server starting on port {PORT}...")
    app.run(host='0.0.0.0', port=PORT, debug=False)