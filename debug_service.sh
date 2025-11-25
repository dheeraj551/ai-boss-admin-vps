#!/bin/bash

# AI Boss Admin - Service Debug & Fix
# Diagnose and fix service startup issues

set -e

echo "🔧 AI Boss Admin - Service Debug & Fix"
echo "====================================="

echo ""
echo "🔍 STEP 1: CHECK SERVICE STATUS"
echo "==============================="
systemctl status ai-boss-admin --no-pager -l

echo ""
echo "🔍 STEP 2: CHECK SERVICE LOGS"
echo "============================="
echo "Last 30 lines of service logs:"
journalctl -u ai-boss-admin -n 30 --no-pager

echo ""
echo "🔍 STEP 3: CHECK APPLICATION FILES"
echo "==================================="
echo "Files in /opt/ai-boss-admin:"
ls -la /opt/ai-boss-admin/

echo ""
echo "Main application file size and first few lines:"
if [[ -f "/opt/ai-boss-admin/optimized_ai_boss_admin.py" ]]; then
    echo "File size: $(wc -l < /opt/ai-boss-admin/optimized_ai_boss_admin.py) lines"
    echo "First 10 lines:"
    head -10 /opt/ai-boss-admin/optimized_ai_boss_admin.py
else
    echo "❌ Main application file missing!"
fi

echo ""
echo "🔍 STEP 4: CHECK VIRTUAL ENVIRONMENT"
echo "===================================="
cd /opt/ai-boss-admin
if [[ -d "venv" ]]; then
    echo "Virtual environment exists"
    source venv/bin/activate
    echo "Python executable: $(which python3)"
    echo "Python version: $(python3 --version)"
    echo "Installed packages:"
    pip list | head -10
else
    echo "❌ Virtual environment missing!"
fi

echo ""
echo "🔍 STEP 5: CHECK ENVIRONMENT FILE"
echo "================================="
if [[ -f "/opt/ai-boss-admin/.env" ]]; then
    echo "✅ .env file exists"
    echo "First 5 lines:"
    head -5 /opt/ai-boss-admin/.env
else
    echo "❌ .env file missing!"
fi

echo ""
echo "🛠️ STEP 6: FIX COMMON ISSUES"
echo "============================"

# Fix 1: Copy environment file
if [[ ! -f "/opt/ai-boss-admin/.env" ]]; then
    echo "Fixing: Creating .env file..."
    if [[ -f "/root/ai-boss-admin-vps/.env.production" ]]; then
        cp /root/ai-boss-admin-vps/.env.production /opt/ai-boss-admin/.env
        echo "✅ .env file copied"
    else
        echo "❌ Source .env.production not found"
    fi
fi

# Fix 2: Ensure application file exists
if [[ ! -f "/opt/ai-boss-admin/optimized_ai_boss_admin.py" ]]; then
    echo "Fixing: Copying application file..."
    if [[ -f "/root/ai-boss-admin-vps/optimized_ai_boss_admin.py" ]]; then
        cp /root/ai-boss-admin-vps/optimized_ai_boss_admin.py /opt/ai-boss-admin/
        echo "✅ Application file copied"
    else
        echo "❌ Source application file not found"
        exit 1
    fi
fi

# Fix 3: Check and fix permissions
echo "Fixing: Setting permissions..."
chown -R root:root /opt/ai-boss-admin
chmod +x /opt/ai-boss-admin/optimized_ai_boss_admin.py
chmod +x /opt/ai-boss-admin/*.sh
echo "✅ Permissions fixed"

# Fix 4: Create logs directory
mkdir -p /opt/ai-boss-admin/logs
chmod 755 /opt/ai-boss-admin/logs
echo "✅ Logs directory created"

echo ""
echo "🧪 STEP 7: TEST APPLICATION MANUALLY"
echo "===================================="
cd /opt/ai-boss-admin
source venv/bin/activate

echo "Testing if application can start (timeout 10 seconds)..."
timeout 10s python3 optimized_ai_boss_admin.py &
MANUAL_PID=$!

sleep 3

# Test if it's listening
echo "Testing if port 8000 is responding..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Manual test successful!"
    echo "✅ Application starts correctly"
    
    # Kill manual test
    kill $MANUAL_PID 2>/dev/null || true
    sleep 2
    
else
    echo "❌ Manual test failed"
    echo "Manual test process might have crashed or port not responding"
    kill $MANUAL_PID 2>/dev/null || true
fi

echo ""
echo "🚀 STEP 8: RESTART SERVICE"
echo "=========================="
sudo systemctl stop ai-boss-admin 2>/dev/null || true
sleep 2

echo "Starting service..."
sudo systemctl start ai-boss-admin
sleep 5

echo ""
echo "📊 STEP 9: FINAL STATUS CHECK"
echo "============================="
if systemctl is-active --quiet ai-boss-admin; then
    echo "✅ Service is running!"
    systemctl status ai-boss-admin --no-pager -l
else
    echo "❌ Service still failed"
    echo "Service status:"
    systemctl status ai-boss-admin --no-pager -l
    echo ""
    echo "Recent logs:"
    journalctl -u ai-boss-admin -n 10 --no-pager
fi

echo ""
echo "🧪 STEP 10: TEST ENDPOINTS"
echo "=========================="
sleep 3

echo -n "Health endpoint: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/health 2>/dev/null; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

echo -n "Dashboard: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/ 2>/dev/null; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your_vps_ip")
echo ""
echo "🌐 ACCESS URLS:"
echo "==============="
echo "✅ Local: http://localhost:8000"
echo "✅ Public: http://$VPS_IP:8000"
echo ""
echo "🔧 IF STILL NOT WORKING:"
echo "======================="
echo "1. Check for Python errors in the application"
echo "2. Verify all dependencies are installed correctly"
echo "3. Check if port 8000 is being used by another process"
echo "4. Look for specific error messages in the logs above"