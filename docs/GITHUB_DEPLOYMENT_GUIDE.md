# 🚀 GitHub Repository Deployment Guide

## 📋 Prerequisites

- VPS with Ubuntu/Debian
- Root access
- Git installed
- Internet connection

## 🔄 Step 1: Clone Repository

```bash
# Clone to your VPS
git clone https://github.com/YOUR_USERNAME/ai-boss-admin-vps.git
cd ai-boss-admin-vps

# Make scripts executable
chmod +x *.sh
```

## ⚡ Step 2: Quick Deployment (Recommended)

```bash
# One-command deployment
bash quick_deploy.sh
```

This script will:
- ✅ Update system packages
- ✅ Install Python 3 and dependencies
- ✅ Create application directory
- ✅ Set up virtual environment
- ✅ Install dependencies
- ✅ Configure systemd service
- ✅ Set up firewall
- ✅ Start the service
- ✅ Run health checks

## 🛠️ Step 3: Manual Deployment (Alternative)

If you prefer manual control:

```bash
# 1. Run full deployment script
bash deploy_production.sh

# 2. Test the system
python3 test_ai_boss_admin.py
```

## 🔧 Step 4: Verify Installation

```bash
# Check service status
sudo systemctl status ai-boss-admin

# Test health endpoint
curl http://localhost:8000/health

# Test course creation
curl -X POST http://localhost:8000/api/courses/mathematics-class11
```

## 🌐 Step 5: Access Your System

- **Web Interface**: `http://YOUR_VPS_IP:8000`
- **Health Check**: `http://YOUR_VPS_IP:8000/health`
- **API Docs**: `http://YOUR_VPS_IP:8000/docs`

## 🔄 Future Updates

```bash
# Pull latest changes from GitHub
git pull origin main

# Restart service to apply updates
sudo systemctl restart ai-boss-admin
```

## 📊 Monitoring

```bash
# View logs
tail -f /opt/ai-boss-admin/logs/ai_boss_admin.log

# System status
sudo systemctl status ai-boss-admin

# Performance metrics
curl http://localhost:8000/api/admin/stats
```

## 🔧 Troubleshooting

### Service Not Starting
```bash
# Check logs
sudo journalctl -u ai-boss-admin -f

# Restart service
sudo systemctl restart ai-boss-admin
```

### RLS Policy Issues
```bash
# Get fix command
curl http://localhost:8000/api/admin/rls-fix
```

### Database Connection
```bash
# Test connectivity
python3 -c "
import requests
response = requests.get('http://localhost:8000/api/health')
print('Status:', response.status_code)
print('Response:', response.json())
"
```

## 🔒 Security Notes

- Service runs on port 8000 (firewall configured)
- Environment variables secured
- RLS policies required for database access
- All logs monitored automatically

## 📞 Support

For issues:
1. Check logs: `sudo journalctl -u ai-boss-admin`
2. Verify environment: `cat /opt/ai-boss-admin/.env.production`
3. Test endpoints: `curl http://localhost:8000/health`
4. Review documentation in `docs/` folder

---

**🎯 Ready to go!** Your AI Boss Admin is now deployed and ready for direct Supabase operations!