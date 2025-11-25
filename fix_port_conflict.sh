#!/bin/bash

# AI Boss Admin - Port Conflict Resolution
# Kills old agents blocking port 8000 and starts optimized system

set -e

echo "🚀 AI Boss Admin - Port Conflict Resolution"
echo "==========================================="

echo ""
echo "🔍 STEP 1: IDENTIFY OLD PROCESSES BLOCKING PORT 8000"
echo "==================================================="

echo "Current processes on port 8000:"
ss -tlnp | grep :8000 || netstat -tlnp | grep :8000 || echo "⚠️ No process found on port 8000 (might be already killed)"

echo ""
echo "Processes that might be blocking port 8000:"
ps aux | grep -E "(uvicorn|complete_blog_automation|ai_boss_admin|working_app)" | grep -v grep || echo "✅ No blocking processes found"

echo ""
echo "🔪 STEP 2: KILL ALL OLD AI AGENTS"
echo "================================="

# Kill the specific process we know is blocking
if pgrep -f "complete_blog_automation_app" > /dev/null; then
    echo "🔴 Killing complete_blog_automation_app..."
    sudo pkill -f "complete_blog_automation_app"
    echo "✅ Killed complete_blog_automation_app"
else
    echo "ℹ️ complete_blog_automation_app not running"
fi

# Kill any AI boss admin processes that might be old versions
if pgrep -f "ai_boss_admin" > /dev/null; then
    echo "🔴 Killing old ai_boss_admin processes..."
    sudo pkill -f "ai_boss_admin"
    echo "✅ Killed ai_boss_admin processes"
else
    echo "ℹ️ ai_boss_admin processes not found"
fi

# Kill any working app processes
if pgrep -f "working_app" > /dev/null; then
    echo "🔴 Killing working_app processes..."
    sudo pkill -f "working_app"
    echo "✅ Killed working_app processes"
else
    echo "ℹ️ working_app processes not found"
fi

# Kill any generic uvicorn processes that might be old apps
if pgrep -f "uvicorn.*:app" > /dev/null; then
    echo "🔴 Killing generic uvicorn app processes..."
    sudo pkill -f "uvicorn.*:app"
    echo "✅ Killed uvicorn app processes"
else
    echo "ℹ️ Generic uvicorn app processes not found"
fi

echo ""
echo "⏳ STEP 3: WAIT FOR PORT CLEANUP"
echo "==============================="
sleep 5

# Verify port 8000 is free
if ss -tlnp | grep :8000 || netstat -tlnp | grep :8000; then
    echo "⚠️ Port 8000 is still occupied!"
    echo "Processes still on port 8000:"
    ss -tlnp | grep :8000 || netstat -tlnp | grep :8000
    echo ""
    echo "Force killing everything on port 8000..."
    sudo fuser -k 8000/tcp
    sleep 3
else
    echo "✅ Port 8000 is now free!"
fi

echo ""
echo "🚀 STEP 4: START OPTIMIZED AI BOSS ADMIN"
echo "========================================="

cd /opt/ai-boss-admin

if [[ ! -f "optimized_ai_boss_admin.py" ]]; then
    echo "❌ optimized_ai_boss_admin.py not found!"
    echo "Files in /opt/ai-boss-admin:"
    ls -la
    exit 1
fi

# Ensure virtual environment is activated
source venv/bin/activate

# Start the optimized service
echo "Starting optimized AI Boss Admin service..."
sudo systemctl restart ai-boss-admin
sleep 5

echo ""
echo "🔍 STEP 5: VERIFY OPTIMIZED SYSTEM IS RUNNING"
echo "============================================"

if systemctl is-active --quiet ai-boss-admin; then
    echo "✅ Service is running!"
    systemctl status ai-boss-admin --no-pager -l
else
    echo "❌ Service failed to start"
    echo "Service logs:"
    journalctl -u ai-boss-admin -n 20 --no-pager
    exit 1
fi

echo ""
echo "🧪 STEP 6: TEST OPTIMIZED ENDPOINTS"
echo "==================================="

sleep 3

echo -n "Health endpoint: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/health; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

echo -n "System stats: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/api/admin/stats; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

echo -n "Dashboard: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

echo ""
echo "🎯 STEP 7: FINAL STATUS"
echo "======================="
echo "Service Status: $(systemctl is-active ai-boss-admin)"
echo "Optimized Process: $(ps aux | grep optimized_ai_boss_admin | grep -v grep | wc -l) processes running"

# Check if optimized features are available
if curl -s http://localhost:8000/api/admin/stats 2>/dev/null | grep -q "system_info"; then
    echo "✅ OPTIMIZED VERSION CONFIRMED!"
    echo "✅ Real-time dashboard features active"
    echo "✅ Enhanced API endpoints working"
else
    echo "⚠️ Optimized features may not be fully loaded"
fi

VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your_vps_ip")
echo ""
echo "🌐 ACCESS YOUR OPTIMIZED DASHBOARD:"
echo "=================================="
echo "✅ Local: http://localhost:8000"
echo "✅ Public: http://$VPS_IP:8000"
echo "✅ Health: http://$VPS_IP:8000/health"
echo "✅ API Docs: http://$VPS_IP:8000/docs"
echo ""
echo "🆕 NEW FEATURES TO LOOK FOR:"
echo "============================"
echo "🎯 'Create Mathematics Class 11 Course' button"
echo "📊 Real-time system health monitoring"
echo "🔄 WebSocket connection indicator"
echo "📱 Instagram integration section"
echo "⚡ Performance statistics panel"

echo ""
echo "🎉 PORT CONFLICT RESOLVED!"
echo "=========================="
echo "Your optimized AI Boss Admin should now be running on port 8000!"
echo "The old agent has been killed and the new optimized system is active."