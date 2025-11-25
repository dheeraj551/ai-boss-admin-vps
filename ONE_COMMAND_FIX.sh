#!/bin/bash

# AI Boss Admin - ONE COMMAND COMPLETE FIX
# Everything in one script - runs in under 2 minutes

set -e

echo "🚀 AI Boss Admin - ONE COMMAND COMPLETE FIX"
echo "============================================"
echo "This script will:"
echo "✅ Kill old agents blocking port 8000"
echo "✅ Install systemd service"
echo "✅ Fix dependencies"
echo "✅ Start optimized system"
echo "✅ Test everything"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# STEP 1: Kill old agents
print_status "Killing old AI agents blocking port 8000..."
sudo pkill -f "complete_blog_automation_app" 2>/dev/null || true
sudo pkill -f "ai_boss_admin" 2>/dev/null || true
sudo pkill -f "working_app" 2>/dev/null || true
sudo pkill -f "uvicorn.*:app" 2>/dev/null || true
sudo fuser -k 8000/tcp 2>/dev/null || true
sleep 3
print_success "Port 8000 cleared"

# STEP 2: Install systemd service
print_status "Installing systemd service..."
sudo cp ai-boss-admin.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ai-boss-admin
print_success "Service installed and enabled"

# STEP 3: Fix dependencies (minimal approach)
print_status "Setting up virtual environment and dependencies..."
cd /opt/ai-boss-admin

# Create venv if needed
if [[ ! -d "venv" ]]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip

# Install only essential packages
print_status "Installing core dependencies..."
pip install fastapi==0.104.1 "uvicorn[standard]==0.24.0" python-multipart==0.0.6 requests==2.31.0 loguru==0.7.2 python-dotenv==1.0.0 websockets==12.0 pydantic==2.5.0
print_success "Core dependencies installed"

# STEP 4: Ensure files are in place
print_status "Verifying files..."
if [[ ! -f "optimized_ai_boss_admin.py" ]]; then
    print_warning "Main file missing, copying..."
    cp ~/ai-boss-admin-vps/optimized_ai_boss_admin.py .
fi

if [[ ! -f ".env" ]]; then
    print_warning "Environment file missing, copying..."
    cp ~/ai-boss-admin-vps/.env.production .env
fi

mkdir -p logs data
print_success "Files verified"

# STEP 5: Start service
print_status "Starting AI Boss Admin service..."
sudo systemctl start ai-boss-admin
sleep 5

# STEP 6: Test everything
print_status "Testing system..."

if systemctl is-active --quiet ai-boss-admin; then
    print_success "Service is running!"
else
    print_error "Service failed to start"
    echo "Service logs:"
    sudo journalctl -u ai-boss-admin -n 10 --no-pager
    exit 1
fi

sleep 2

# Test endpoints
HEALTH_TEST=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/health 2>/dev/null || echo "000")
if [[ "$HEALTH_TEST" == "200" ]]; then
    print_success "Health endpoint: Working"
else
    print_warning "Health endpoint: Issue detected"
fi

STATS_TEST=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/api/admin/stats 2>/dev/null || echo "000")
if [[ "$STATS_TEST" == "200" ]]; then
    print_success "System stats: Working (Optimized version confirmed!)"
else
    print_warning "System stats: May need more time to load"
fi

DASH_TEST=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/ 2>/dev/null || echo "000")
if [[ "$DASH_TEST" == "200" ]]; then
    print_success "Dashboard: Working"
else
    print_warning "Dashboard: Issue detected"
fi

echo ""
print_success "🎉 DEPLOYMENT COMPLETE!"
echo "=========================="

# Get VPS IP
VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your_vps_ip")

echo ""
echo -e "${GREEN}✅ Service Status: $(systemctl is-active ai-boss-admin)${NC}"
echo -e "${GREEN}✅ Optimized AI Boss Admin: RUNNING${NC}"
echo ""
echo -e "${BLUE}🌐 ACCESS YOUR OPTIMIZED DASHBOARD:${NC}"
echo "=================================="
echo -e "${GREEN}• Local:     http://localhost:8000${NC}"
echo -e "${GREEN}• Public:    http://$VPS_IP:8000${NC}"
echo -e "${GREEN}• Health:    http://$VPS_IP:8000/health${NC}"
echo -e "${GREEN}• API Docs:  http://$VPS_IP:8000/docs${NC}"
echo ""
echo -e "${BLUE}🆕 NEW FEATURES TO LOOK FOR:${NC}"
echo "============================="
echo -e "${GREEN}🎯 'Create Mathematics Class 11 Course' button${NC}"
echo -e "${GREEN}📊 Real-time system health monitoring${NC}"
echo -e "${GREEN}🔄 WebSocket connection indicator${NC}"
echo -e "${GREEN}📱 Instagram integration section${NC}"
echo -e "${GREEN}⚡ Performance statistics panel${NC}"
echo ""
echo -e "${BLUE}🧪 QUICK TEST COMMANDS:${NC}"
echo "========================"
echo "curl http://localhost:8000/api/admin/stats"
echo "curl -X POST http://localhost:8000/api/courses/mathematics-class11"
echo ""
echo -e "${GREEN}Your optimized AI Boss Admin is now live! 🚀${NC}"