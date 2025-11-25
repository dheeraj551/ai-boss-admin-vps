#!/bin/bash

# AI Boss Admin - Quick VPS Deployment Script
# One-command deployment for maximum ease of use

set -e

echo "🚀 AI Boss Admin - Quick VPS Deployment"
echo "========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

# System update
print_status "Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Install Python 3 and pip
print_status "Installing Python 3 and dependencies..."
apt install -y python3 python3-pip python3-venv git curl wget
print_success "Python 3 installed"

# Create application directory
print_status "Creating application directory..."
mkdir -p /opt/ai-boss-admin
cd /opt/ai-boss-admin
print_success "Directory created"

# Copy files from current location
print_status "Copying application files..."
if [[ -f "/root/ai-boss-admin-vps/optimized_ai_boss_admin.py" ]]; then
    cp /root/ai-boss-admin-vps/* .
    print_success "Files copied from /root/ai-boss-admin-vps"
else
    print_error "Files not found in /root/ai-boss-admin-vps"
    print_status "Please ensure you're running this from the correct directory"
    exit 1
fi

# Create virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.production.txt
print_success "Virtual environment created and dependencies installed"

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs
mkdir -p data
print_success "Directories created"

# Set proper permissions
print_status "Setting proper permissions..."
chown -R root:root /opt/ai-boss-admin
chmod +x *.sh
print_success "Permissions set"

# Install systemd service
print_status "Installing systemd service..."
cp ai-boss-admin.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ai-boss-admin
print_success "Service installed and enabled"

# Configure firewall
print_status "Configuring firewall..."
ufw allow 8000/tcp
print_success "Firewall configured (port 8000 allowed)"

# Start the service
print_status "Starting AI Boss Admin service..."
systemctl start ai-boss-admin
sleep 5

# Check service status
if systemctl is-active --quiet ai-boss-admin; then
    print_success "AI Boss Admin service is running!"
else
    print_error "Service failed to start. Checking logs..."
    systemctl status ai-boss-admin
    exit 1
fi

# Test the service
print_status "Testing service endpoints..."
sleep 2

# Health check
if curl -s http://localhost:8000/health > /dev/null; then
    print_success "Health endpoint is working!"
else
    print_warning "Health endpoint not responding - this might be normal during startup"
fi

# Get VPS IP
VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your_vps_ip")

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================="
echo ""
echo "✅ Service Status: $(systemctl is-active ai-boss-admin)"
echo "✅ Service: ai-boss-admin"
echo "✅ Port: 8000"
echo ""
echo "🌐 Access URLs:"
echo "   Local:     http://localhost:8000"
echo "   Public:    http://$VPS_IP:8000"
echo "   Health:    http://$VPS_IP:8000/health"
echo ""
echo "🔧 Management Commands:"
echo "   Status:    systemctl status ai-boss-admin"
echo "   Logs:      tail -f /opt/ai-boss-admin/logs/ai_boss_admin.log"
echo "   Restart:   systemctl restart ai-boss-admin"
echo "   Stop:      systemctl stop ai-boss-admin"
echo ""
echo "🧪 Quick Test:"
echo "   curl http://localhost:8000/api/courses/mathematics-class11"
echo ""
echo "📚 Documentation:"
echo "   Full Guide: /opt/ai-boss-admin/docs/DEPLOYMENT_COMPLETE_GUIDE.md"
echo ""
print_success "AI Boss Admin is now live on your VPS!"