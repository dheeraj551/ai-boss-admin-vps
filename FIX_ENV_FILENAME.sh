#!/bin/bash

echo "🔧 FIXING SERVICE TO USE .env FILE"
echo "=================================="

cd /opt/ai-boss-admin/

echo "📋 Current files:"
ls -la | grep -E "(\.env|\.py)"

echo ""
echo "🔧 Updating service file to use .env instead of .env.production..."

sudo tee /etc/systemd/system/ai-boss-admin.service > /dev/null << 'EOF'
[Unit]
Description=AI Boss Admin - Production VPS Service  
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data  
WorkingDirectory=/opt/ai-boss-admin
EnvironmentFile=/opt/ai-boss-admin/.env
ExecStart=/opt/ai-boss-admin/venv/bin/python -m uvicorn optimized_ai_boss_admin:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file updated"

echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

echo "🧪 Testing environment variables..."
source venv/bin/activate
python3 -c "
import os
from supabase import create_client

try:
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    print(f'✅ SUPABASE_URL: {url[:50]}...' if url else '❌ SUPABASE_URL: NOT SET')
    print(f'✅ SUPABASE_SERVICE_ROLE_KEY: {\"SET\" if key else \"NOT SET\"}')
    if url and key:
        supabase = create_client(url, key)
        print('✅ Database connection test: SUCCESS')
except Exception as e:
    print(f'❌ Database connection test: {e}')
"

echo "🚀 Starting service..."
sudo systemctl restart ai-boss-admin

echo "⏳ Waiting for startup..."
sleep 5

echo "📊 Service status:"
sudo systemctl status ai-boss-admin

echo ""
if sudo systemctl is-active --quiet ai-boss-admin; then
    echo "🎉 SUCCESS! AI Boss Admin is running!"
    echo "🌐 Access: http://$(curl -s ifconfig.me):8000"
else
    echo "❌ Service failed. Check logs:"
    echo "sudo journalctl -u ai-boss-admin -n 30 --no-pager"
fi