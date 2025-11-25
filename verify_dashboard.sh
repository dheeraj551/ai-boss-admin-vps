#!/bin/bash

# AI Boss Admin - Version Verification & Dashboard Check
# Helps verify if the updated system is running

set -e

echo "🔍 AI Boss Admin - Version Verification"
echo "========================================"

# Check service status
echo ""
echo "1️⃣ SERVICE STATUS:"
echo "=================="
systemctl status ai-boss-admin --no-pager -l

echo ""
echo "2️⃣ PROCESS CHECK:"
echo "================="
ps aux | grep "optimized_ai_boss_admin" | grep -v grep || echo "⚠️ Process not found"

echo ""
echo "3️⃣ PORT CHECK:"
echo "=============="
netstat -tlnp | grep :8000 || echo "⚠️ Port 8000 not listening"

echo ""
echo "4️⃣ HEALTH ENDPOINT TEST:"
echo "========================"
curl -s http://localhost:8000/health || echo "❌ Health endpoint not responding"
echo ""

echo "5️⃣ WEB INTERFACE TEST:"
echo "======================"
echo "Testing main dashboard endpoint..."
curl -s -I http://localhost:8000/ | head -5 || echo "❌ Web interface not responding"
echo ""

echo "6️⃣ API ENDPOINTS CHECK:"
echo "======================="
echo "Testing updated API endpoints..."

echo -n "• Courses endpoint: "
curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/api/courses || echo "FAILED"

echo -n "• Mathematics course creation: "
curl -s -X POST -w "%{http_code}" -o /dev/null http://localhost:8000/api/courses/mathematics-class11 || echo "FAILED"

echo -n "• System stats: "
curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/api/admin/stats || echo "FAILED"

echo ""
echo "7️⃣ VERSION IDENTIFICATION:"
echo "=========================="
echo "Checking if optimized system is running..."

# Try to identify the running version
if systemctl is-active --quiet ai-boss-admin; then
    echo "✅ Service is active"
    
    # Check if optimized features are available
    RESPONSE=$(curl -s http://localhost:8000/api/admin/stats 2>/dev/null || echo '{"error":"not_available"}')
    
    if echo "$RESPONSE" | grep -q '"system_info"'; then
        echo "✅ OPTIMIZED VERSION DETECTED"
        echo "✅ Real-time dashboard features available"
        echo "✅ Enhanced API endpoints working"
    else
        echo "⚠️ May be running old version"
    fi
else
    echo "❌ Service not running"
fi

echo ""
echo "8️⃣ TROUBLESHOOTING:"
echo "==================="
echo "If you see an old dashboard, try:"
echo "1. Restart service: sudo systemctl restart ai-boss-admin"
echo "2. Check logs: sudo journalctl -u ai-boss-admin -f"
echo "3. Verify files: ls -la /opt/ai-boss-admin/"
echo "4. Test health: curl http://localhost:8000/health"

echo ""
echo "9️⃣ ACCESS URLs:"
echo "==============="
VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your_vps_ip")
echo "🌐 Local Dashboard: http://localhost:8000"
echo "🌐 Public Dashboard: http://$VPS_IP:8000"
echo "🌐 Health Check: http://$VPS_IP:8000/health"
echo "🌐 API Docs: http://$VPS_IP:8000/docs"

echo ""
echo "🔟 NEW FEATURES TO LOOK FOR:"
echo "============================="
echo "✅ Real-time WebSocket updates"
echo "✅ Health monitoring dashboard"
echo "✅ Course management interface"
echo "✅ 'Create Mathematics Class 11 Course' button"
echo "✅ Instagram integration section"
echo "✅ System statistics panel"
echo "✅ RLS policy status indicator"