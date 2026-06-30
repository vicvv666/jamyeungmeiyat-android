#!/bin/bash
set -e
D=/tmp/wm_deploy_result.txt

echo "=== SERVICE ===" > $D
systemctl status watermarkwipe >> $D 2>&1 || true
echo "=== JOURNAL ===" >> $D
journalctl -u watermarkwipe --no-pager -n 30 >> $D 2>&1 || true
echo "=== PORTS ===" >> $D
ss -tlnp >> $D 2>&1 || true
echo "=== NGINXCONF ===" >> $D
cat /etc/nginx/conf.d/watermarkwipe.conf >> $D 2>&1 || true
echo "=== SERVICEFILE ===" >> $D
cat /etc/systemd/system/watermarkwipe.service >> $D 2>&1 || true
echo "=== VENV ===" >> $D
ls -la /opt/watermarkwipe/venv/bin/gunicorn >> $D 2>&1 || true
echo "=== APPIMPORT ===" >> $D
cd /opt/watermarkwipe && /opt/watermarkwipe/venv/bin/python -c 'import app;print("APP_OK")' >> $D 2>&1 || true
echo "=== GUNICORN ===" >> $D
cd /opt/watermarkwipe && /opt/watermarkwipe/venv/bin/gunicorn --daemon --bind 127.0.0.1:5000 --workers 1 --timeout 120 app:app >> $D 2>&1 || true
sleep 2
echo "=== PORTCHECK ===" >> $D
ss -tlnp | grep 5000 >> $D 2>&1 || true
echo "=== CANTON ===" >> $D
systemctl status cantonesemusic >> $D 2>&1 || true
echo "=== NGINXTEST ===" >> $D
nginx -t >> $D 2>&1 || true
echo "=== CERTS ===" >> $D
ls /etc/letsencrypt/live/ >> $D 2>&1 || true
echo "=== SERVLST ===" >> $D
systemctl list-units --type=service --state=running >> $D 2>&1 || true
echo "=== DONE ===" >> $D
# Upload result to GitHub
python3 -c "
import urllib.request,json,base64,os
c=base64.b64encode(open('/tmp/wm_deploy_result.txt','rb').read()).decode()
P=os.environ.get('GH_TOKEN','')
if not P: print('NO_TOKEN'); exit(0)
d=json.dumps({'message':'wm_diag','content':c}).encode()
try:
 r=urllib.request.Request('https://api.github.com/repos/vicvv666/jamyeungmeiyat-android/contents/wm_diag.txt',data=d,headers={'Authorization':'token '+P,'Content-Type':'application/json'},method='PUT')
 urllib.request.urlopen(r,timeout=30)
 print('OK')
except Exception as e:
 if '422' in str(e):
  g=urllib.request.Request('https://api.github.com/repos/vicvv666/jamyeungmeiyat-android/contents/wm_diag.txt',headers={'Authorization':'token '+P})
  s=json.loads(urllib.request.urlopen(g,timeout=15).read())['sha']
  d2=json.dumps({'message':'wm_diag2','content':c,'sha':s}).encode()
  r2=urllib.request.Request('https://api.github.com/repos/vicvv666/jamyeungmeiyat-android/contents/wm_diag.txt',data=d2,headers={'Authorization':'token '+P,'Content-Type':'application/json'},method='PUT')
  urllib.request.urlopen(r2,timeout=30)
  print('OK2')
 else:
  print('ERR:'+str(e)[:200])
"
