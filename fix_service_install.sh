#!/bin/bash

# AI Boss Admin - Service Installation Fix
# Fixes missing systemd service and gets optimized system running

set -e

echo "🔧 AI Boss Admin - Service Installation Fix"
echo "=========================================="

echo ""
echo "🔍 DIAGNOSIS:"
echo "============="
echo "Current working directory: $(pwd)"
echo "Checking if service file exists..."
if [[ -f "ai-boss-admin.service" ]]; then
    echo "✅ Service file found in current directory"
    cat ai-boss-admin.service | head -5
else
    echo "❌ Service file not found in current directory"
    echo "Files in current directory:"
    ls -la
    exit 1
fi

echo ""
echo "1️⃣ INSTALLING SYSTEMD SERVICE:"
echo "==============================="

# Copy service file to systemd directory
echo "Copying service file to /etc/systemd/system/..."
sudo cp ai-boss-admin.service /etc/systemd/system/
echo "✅ Service file copied"

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "✅ Systemd daemon reloaded"

# Enable the service
echo "Enabling ai-boss-admin service..."
sudo systemctl enable ai-boss-admin
echo "✅ Service enabled"

echo ""
echo "2️⃣ FIXING DEPENDENCY ISSUES:"
echo "============================"

cd /opt/ai-boss-admin

if [[ ! -d "venv" ]]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Activating virtual environment..."
source venv/bin/activate

# Fix the requirements that have issues
echo "Installing dependencies (fixing problematic packages)..."
pip install --upgrade pip

# Install critical packages one by one to avoid dependency issues
echo "Installing FastAPI and Uvicorn..."
pip install fastapi==0.104.1
pip install "uvicorn[standard]==0.24.0"

echo "Installing core dependencies..."
pip install python-multipart==0.0.6
pip install requests==2.31.0
pip install httpx==0.25.2
pip install aiofiles==23.2.1
pip install loguru==0.7.2
pip install python-dotenv==1.0.0
pip install websockets==12.0
pip install python-dateutil==2.8.2
pip install pydantic==2.5.0
pip install prometheus-client==0.19.0

# Skip problematic packages for now
echo "Skipping problematic packages (not critical for core functionality)..."
echo "Skipped: python-systemd (alternative: systemd socket activation available)"

echo "✅ Core dependencies installed"

echo ""
echo "3️⃣ VERIFYING FILES:"
echo "==================="
if [[ -f "/opt/ai-boss-admin/optimized_ai_boss_admin.py" ]]; then
    echo "✅ Main application file exists"
    echo "Lines: $(wc -l < /opt/ai-boss-admin/optimized_ai_boss_admin.py)"
else
    echo "❌ Main application file missing!"
    echo "Copying optimized_ai_boss_admin.py..."
    cp optimized_ai_boss_admin.py /opt/ai-boss-admin/
fi

if [[ -f "/opt/ai-boss-admin/.env" ]]; then
    echo "✅ Environment file exists"
else
    echo "❌ Environment file missing!"
    echo "Copying .env..."
    cp .env.production /opt/ai-boss-admin/.env
fi

# Create necessary directories
mkdir -p /opt/ai-boss-admin/logs
mkdir -p /opt/ai-boss-admin/data
echo "✅ Directories created"

echo ""
echo "4️⃣ STARTING SERVICE:"
echo "===================="

echo "Starting ai-boss-admin service..."
sudo systemctl start ai-boss-admin

# Wait for startup
sleep 5

echo ""
echo "5️⃣ SERVICE STATUS CHECK:"
echo "========================"

if systemctl is-active --quiet ai-boss-admin; then
    echo "✅ Service is running!"
    systemctl status ai-boss-admin --no-pager -l
else
    echo "❌ Service failed to start"
    echo "Last service logs:"
    sudo journalctl -u ai-boss-admin -n 20 --no-pager
    echo ""
    echo "Let me try to start it manually to see the error..."
    cd /opt/ai-boss-admin
    source venv/bin/activate
    echo "Running manually to check for errors:"
    timeout 10s python3 optimized_ai_boss_admin.py || echo "Manual run completed"
fi

echo ""
echo "6️⃣ TESTING ENDPOINTS:"
echo "===================="

sleep 3

echo "Testing health endpoint..."
echo -n "Health: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/health; then
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

echo -n "API Stats: "
if curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/api/admin/stats; then
    echo "✅ Working"
else
    echo "❌ Not responding"
fi

echo ""
echo "7️⃣ FINAL VERIFICATION:"
echo "======================"
echo "Service Status: $(systemctl is-active ai-boss-admin)"
echo "Process check:"
ps aux | grep optimized_ai_boss_admin | grep -v grep || echo "⚠️ Process not found"

VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your_vps_ip")
echo ""
echo "🌐 ACCESS URLS:"
echo "==============="
echo "✅ Local: http://localhost:8000"
echo "✅ Public: http://$VPS_IP:8000"
echo "✅ Health: http://$VPS_IP:8000/health"
echo ""
echo "🔧 IF STILL NOT WORKING:"
echo "======================="
echo "1. Check logs: sudo journalctl -u ai-boss-admin -f"
echo "2. Manual test: cd /opt/ai-boss-admin && source venv/bin/activate && python3 optimized_ai_boss_admin.py"
echo "3. Check port: sudo ss -tlnp | grep :8000"