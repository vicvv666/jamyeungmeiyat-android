#!/bin/bash
set -e
D=/tmp/wm_deploy_result.txt

echo "=== WATERMARKWIPE SERVICE ===" > $D
systemctl status watermarkwipe >> $D 2>&1 || true
echo "=== JOURNAL ===" >> $D
journalctl -u watermarkwipe --no-pager -n 30 >> $D 2>&1 || true
echo "=== PORTS ===" >> $D
ss -tlnp >> $D 2>&1 || true
echo "=== NGINX CONF ===" >> $D  
cat /etc/nginx/conf.d/watermarkwipe.conf >> $D 2>&1 || true
echo "=== SERVICE FILE ===" >> $D
cat /etc/systemd/system/watermarkwipe.service >> $D 2>&1 || true
echo "=== VENV ===" >> $D
ls -la /opt/watermarkwipe/venv/bin/gunicorn >> $D 2>&1 || true
echo "=== APP IMPORT ===" >> $D
cd /opt/watermarkwipe && /opt/watermarkwipe/venv/bin/python -c 'import app;print("APP_OK")' >> $D 2>&1 || true
echo "=== GUNICORN START ===" >> $D
cd /opt/watermarkwipe && /opt/watermarkwipe/venv/bin/gunicorn --daemon --bind 127.0.0.1:5000 --workers 1 --timeout 120 app:app >> $D 2>&1 || true
sleep 2
echo "=== PORT CHECK ===" >> $D
ss -tlnp | grep 5000 >> $D 2>&1 || true
echo "=== CANTON STATUS ===" >> $D
systemctl status cantonesemusic >> $D 2>&1 || true
echo "=== NGINX TEST ===" >> $D
nginx -t >> $D 2>&1 || true
echo "=== CERTS ===" >> $D
ls /etc/letsencrypt/live/ >> $D 2>&1 || true
echo "=== ALL SERVICES ===" >> $D
systemctl list-units --type=service --state=running >> $D 2>&1 || true
echo "=== DONE ===" >> $D
