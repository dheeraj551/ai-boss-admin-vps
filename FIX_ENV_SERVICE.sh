#!/bin/bash

echo "🔧 FIXING AI BOSS ADMIN SERVICE ISSUES"
echo "====================================="

# Step 1: Stop the service first
echo "🛑 Step 1: Stopping the problematic service..."
sudo systemctl stop ai-boss-admin.service
sudo systemctl disable ai-boss-admin.service

# Step 2: Verify environment file location
echo "📋 Step 2: Checking environment file..."
ENV_FILE="/opt/ai-boss-admin/.env.production"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Environment file not found at $ENV_FILE"
    echo "📝 Creating environment file..."
    
    # Create the .env.production file with correct content
    sudo mkdir -p /opt/ai-boss-admin
    sudo tee $ENV_FILE > /dev/null << 'EOF'
# AI Boss Admin - Production Environment
# Supabase Configuration
SUPABASE_URL=https://suaqywhmaheoansrinzw.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1YXF5d2htYWhlb2Fuc3Jpbnp3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzIxNTEwMCwiZXhwIjoyMDc4NzkxMTAwfQ.8Y8Y6Zf7n5TqH6sZb8cE1mI4sC6f5V2W8j9l3N5Q6f
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1YXF5d2htYWhlb2Fuc3Jpbnp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyMTUxMDAsImV4cCI6MjA3ODc5MTEwMH0.UBkJ-Cx6fRNQucvSQS47XY2Nn6ktj_pZQRa7UiTQhf4

# Admin Configuration  
ADMIN_USER_ID=550e8400-e29b-41d4-a716-446655440000
ADMIN_EMAILS=support@celorisdesigns.com,admin@celorisdesigns.com

# Security
JWT_SECRET_KEY=celoris_designs_production_secret_2024

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=false
EOF
    
    sudo chown -R www-data:www-data /opt/ai-boss-admin/
    sudo chmod 600 $ENV_FILE
    echo "✅ Environment file created at $ENV_FILE"
else
    echo "✅ Environment file exists at $ENV_FILE"
fi

# Step 3: Update the service file with correct paths
echo "📝 Step 3: Updating systemd service file..."
sudo tee /etc/systemd/system/ai-boss-admin.service > /dev/null << 'EOF'
[Unit]
Description=AI Boss Admin - Production VPS Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/ai-boss-admin
EnvironmentFile=/opt/ai-boss-admin/.env.production
ExecStart=/opt/ai-boss-admin/venv/bin/python -m uvicorn optimized_ai_boss_admin:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file updated"

# Step 4: Reload systemd and enable service
echo "🔄 Step 4: Reloading systemd configuration..."
sudo systemctl daemon-reload
sudo systemctl enable ai-boss-admin.service

# Step 5: Check for port conflicts
echo "🔍 Step 5: Checking for port conflicts..."
if lsof -i :8000 > /dev/null 2>&1; then
    echo "⚠️  Port 8000 is already in use. Processes:"
    lsof -i :8000
    echo "🧹 Killing processes on port 8000..."
    sudo fuser -k 8000/tcp
    sleep 2
else
    echo "✅ Port 8000 is available"
fi

# Step 6: Test the service manually first
echo "🧪 Step 6: Testing service manually..."
cd /opt/ai-boss-admin
source venv/bin/activate

echo "Testing database connection..."
python3 -c "
import os
from supabase import create_client, Client

# Test environment variables
print('Environment Variables:')
print(f'SUPABASE_URL: {os.getenv(\"SUPABASE_URL\", \"NOT SET\")}')
print(f'SUPABASE_SERVICE_ROLE_KEY: {\"SET\" if os.getenv(\"SUPABASE_SERVICE_ROLE_KEY\") else \"NOT SET\"}')

# Test database connection
try:
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    if url and key:
        supabase = create_client(url, key)
        result = supabase.table('courses').select('count').execute()
        print('✅ Database connection successful')
    else:
        print('❌ Missing environment variables')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
"

# Step 7: Start the service
echo "🚀 Step 7: Starting the service..."
sudo systemctl start ai-boss-admin.service

# Step 8: Check status
echo "📊 Step 8: Checking service status..."
sleep 5
sudo systemctl status ai-boss-admin.service

echo ""
echo "🎯 If service is still failing, check logs with:"
echo "   sudo journalctl -u ai-boss-admin -n 50 --no-pager"
echo ""
echo "🌐 Access the dashboard at: http://YOUR_SERVER_IP:8000"