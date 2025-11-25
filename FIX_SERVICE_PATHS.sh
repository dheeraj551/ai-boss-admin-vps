#!/bin/bash

echo "🔧 FIXING AI BOSS ADMIN SERVICE PATHS"
echo "===================================="

# Step 1: Stop the failing service
echo "🛑 Stopping the problematic service..."
sudo systemctl stop ai-boss-admin.service
sudo systemctl disable ai-boss-admin.service

# Step 2: Check current directories
echo "📋 Checking current directories..."
echo "Git repo location: $(pwd)"
echo "Environment file: $(pwd)/.env.production"

# Step 3: Fix the service file to use correct paths
echo "📝 Fixing systemd service file..."
sudo tee /etc/systemd/system/ai-boss-admin.service > /dev/null << EOF
[Unit]
Description=AI Boss Admin - Production VPS Service  
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data  
WorkingDirectory=$(pwd)
EnvironmentFile=$(pwd)/.env.production
ExecStart=$(pwd)/venv/bin/python -m uvicorn optimized_ai_boss_admin:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file updated with correct paths"

# Step 4: Reload systemd and enable service
echo "🔄 Reloading systemd configuration..."
sudo systemctl daemon-reload  
sudo systemctl enable ai-boss-admin.service

# Step 5: Clear any port conflicts
echo "🔍 Checking for port conflicts..."
sudo fuser -k 8000/tcp 2>/dev/null || echo "No processes on port 8000"

# Step 6: Verify environment file
echo "✅ Verifying environment file..."
if [ -f ".env.production" ]; then
    echo "✅ Environment file found: $(pwd)/.env.production"
    echo "📄 First few lines of .env.production:"
    head -n 5 .env.production
else
    echo "❌ Environment file not found!"
    exit 1
fi

# Step 7: Test database connection
echo "🧪 Testing database connection..."
source venv/bin/activate
python3 -c "
import os
from supabase import create_client, Client

try:
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    if url and key:
        supabase = create_client(url, key)
        print('✅ Database connection successful')
    else:
        print('❌ Missing environment variables')
        print(f'SUPABASE_URL: {os.getenv(\"SUPABASE_URL\", \"NOT SET\")}')
        print(f'SUPABASE_SERVICE_ROLE_KEY: {\"SET\" if os.getenv(\"SUPABASE_SERVICE_ROLE_KEY\") else \"NOT SET\"}')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
"

# Step 8: Start the service
echo "🚀 Starting AI Boss Admin service..."
sudo systemctl start ai-boss-admin.service

# Step 9: Check status
echo "📊 Service status:"
sleep 3
sudo systemctl status ai-boss-admin.service

echo ""
echo "🎯 If successful, access: http://YOUR_SERVER_IP:8000"
echo "📊 If issues, check logs: sudo journalctl -u ai-boss-admin -n 20 --no-pager"