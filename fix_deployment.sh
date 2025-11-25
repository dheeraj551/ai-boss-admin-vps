#!/bin/bash

# AI Boss Admin - Complete Deployment Fix Script
# Fixes all deployment issues from previous run

set -e

echo "🔧 AI Boss Admin - Deployment Fix"
echo "================================="

# Check current directory and files
echo ""
echo "1️⃣ CHECKING CURRENT STATE:"
echo "==========================="
echo "Current directory: $(pwd)"
echo "Files in current directory:"
ls -la

echo ""
echo "2️⃣ CHECKING SERVICE STATUS:"
echo "============================"
systemctl status ai-boss-admin --no-pager -l 2>/dev/null || echo "❌ Service not found"

echo ""
echo "3️⃣ CHECKING PROCESSES:"
echo "======================"
ps aux | grep python3 | grep -v grep || echo "⚠️ No Python processes found"

echo ""
echo "4️⃣ CHECKING PORT:"
echo "=================="
netstat -tlnp | grep :8000 || echo "⚠️ Port 8000 not listening"

echo ""
echo "5️⃣ FIXING FILE COPY ISSUE:"
echo "=========================="
echo "Copying all files including directories..."

# Fix the copy command with proper recursive copy
if [[ -d "docs" ]]; then
    echo "📁 Found docs directory, copying..."
    cp -r docs /opt/ai-boss-admin/ 2>/dev/null || echo "⚠️ Docs copy may have issues"
fi

if [[ -f "optimized_ai_boss_admin.py" ]]; then
    echo "📄 Copying main application..."
    cp optimized_ai_boss_admin.py /opt/ai-boss-admin/
    echo "✅ Main application copied"
fi

if [[ -f "requirements.production.txt" ]]; then
    echo "📋 Copying requirements..."
    cp requirements.production.txt /opt/ai-boss-admin/
    echo "✅ Requirements copied"
fi

if [[ -f ".env.production" ]]; then
    echo "🔧 Copying environment config..."
    cp .env.production /opt/ai-boss-admin/.env
    echo "✅ Environment config copied"
fi

if [[ -f "ai-boss-admin.service" ]]; then
    echo "⚙️ Copying service file..."
    cp ai-boss-admin.service /opt/ai-boss-admin/
    echo "✅ Service file copied"
fi

echo ""
echo "6️⃣ CREATING VIRTUAL ENVIRONMENT:"
echo "================================="
cd /opt/ai-boss-admin

if [[ ! -d "venv" ]]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Activating virtual environment and installing dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.production.txt

echo ""
echo "7️⃣ CREATING NECESSARY DIRECTORIES:"
echo "==================================="
mkdir -p logs
mkdir -p data
echo "✅ Directories created"

echo ""
echo "8️⃣ SETTING PERMISSIONS:"
echo "========================"
chown -R root:root /opt/ai-boss-admin
chmod +x *.sh
echo "✅ Permissions set"

echo ""
echo "9️⃣ INSTALLING SYSTEMD SERVICE:"
echo "==============================="
if [[ -f "/opt/ai-boss-admin/ai-boss-admin.service" ]]; then
    echo "Installing service..."
    cp /opt/ai-boss-admin/ai-boss-admin.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable ai-boss-admin
    echo "✅ Service installed and enabled"
else
    echo "❌ Service file not found!"
fi

echo ""
echo "🔟 STARTING SERVICE:"
echo "===================="
systemctl start ai-boss-admin
sleep 5

echo ""
echo "1️⃣1️⃣ VERIFYING SERVICE:"
echo "======================="
if systemctl is-active --quiet ai-boss-admin; then
    echo "✅ Service is running!"
    systemctl status ai-boss-admin --no-pager -l
else
    echo "❌ Service failed to start"
    echo "Service logs:"
    systemctl status ai-boss-admin --no-pager -l
    echo ""
    echo "Journal logs:"
    journalctl -u ai-boss-admin -n 20 --no-pager
fi

echo ""
echo "1️⃣2️⃣ TESTING ENDPOINTS:"
echo "======================="
sleep 3

echo -n "Health endpoint: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/health; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

echo -n "Main dashboard: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

echo ""
echo "1️⃣3️⃣ FINAL STATUS:"
echo "==================="
echo "Service Status: $(systemctl is-active ai-boss-admin)"
echo "Port Status: $(netstat -tlnp | grep :8000 || echo 'Not listening')"

VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your_vps_ip")
echo ""
echo "🌐 ACCESS URLS:"
echo "==============="
echo "✅ Local: http://localhost:8000"
echo "✅ Public: http://$VPS_IP:8000"
echo "✅ Health: http://$VPS_IP:8000/health"
echo ""
echo "🔧 IF ISSUES PERSIST:"
echo "===================="
echo "1. Check logs: sudo journalctl -u ai-boss-admin -f"
echo "2. Test manually: cd /opt/ai-boss-admin && source venv/bin/activate && python3 optimized_ai_boss_admin.py"
echo "3. Restart service: sudo systemctl restart ai-boss-admin"