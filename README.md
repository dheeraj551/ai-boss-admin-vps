# AI Boss Admin VPS - Production System

🚀 **Production-ready AI Agent for VPS deployment with direct Supabase integration**

## 🎯 Overview

This is a comprehensive AI Agent system optimized for VPS deployment that performs all database operations directly to Supabase, bypassing frontend APIs for maximum performance and reliability.

## ✨ Features

- **Direct Supabase Integration**: Bypasses frontend APIs for faster operations
- **FastAPI Backend**: High-performance web application
- **Course Management**: Create, read, update, delete courses
- **Instagram Integration**: Automated social media posting
- **Blog System**: Content management capabilities
- **Real-time Dashboard**: WebSocket support for live updates
- **Health Monitoring**: Built-in system health checks
- **RLS Policy Detection**: Automatic detection and fix suggestions
- **Production Deployment**: One-command VPS deployment
- **Comprehensive Testing**: Full test suite included

## 🚀 Quick Deploy to VPS

```bash
# 1. Clone repository to your VPS
git clone https://github.com/YOUR_USERNAME/ai-boss-admin-vps.git
cd ai-boss-admin-vps

# 2. Run production deployment
bash deploy_production.sh

# 3. Test the system
python3 test_ai_boss_admin.py
```

## 🔧 System Architecture

```
ai-boss-admin-vps/
├── optimized_ai_boss_admin.py    # Main FastAPI application (1,678 lines)
├── deploy_production.sh           # VPS deployment script (313 lines)
├── test_ai_boss_admin.py          # Comprehensive test suite (274 lines)
├── maintenance.sh                 # System maintenance tools (299 lines)
├── requirements.production.txt    # Python dependencies (120 lines)
├── .env.production               # Production configuration (88 lines)
├── README.md                     # This file
├── .gitignore                    # Git ignore rules
├── docs/                         # Documentation directory
│   ├── DEPLOYMENT_COMPLETE_GUIDE.md
│   └── OPTIMIZATION_COMPLETE.md
└── logs/                         # Application logs
```

## 🔗 API Endpoints

### Course Management
- `GET /health` - System health check
- `GET /api/courses` - List all courses
- `POST /api/courses/mathematics-class11` - Create Mathematics Class 11 course
- `GET /api/courses/{course_id}` - Get specific course

### Instagram Integration
- `POST /api/instagram/post` - Create Instagram post
- `GET /api/instagram/posts` - List Instagram posts

### System Management
- `GET /api/admin/stats` - System statistics
- `WS /ws/admin` - Real-time admin dashboard

## 🛠️ Manual Installation

If you prefer manual setup:

```bash
# 1. Install dependencies
pip3 install -r requirements.production.txt

# 2. Copy environment configuration
cp .env.production .env
# Edit .env with your actual Supabase credentials

# 3. Run the application
python3 optimized_ai_boss_admin.py

# Or with systemd service
sudo cp ai-boss-admin.service /etc/systemd/system/
sudo systemctl enable ai-boss-admin
sudo systemctl start ai-boss-admin
```

## 📋 Environment Variables

Required in `.env` file:

```bash
# Supabase Configuration
SUPABASE_URL=https://suaqywhmaheoansrinzw.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
SUPABASE_ANON_KEY=your_anon_key_here
ADMIN_USER_ID=550e8400-e29b-41d4-a716-446655440000

# Application Settings
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO
PORT=8000
HOST=0.0.0.0

# Admin Configuration
ADMIN_EMAILS=support@celorisdesigns.com,admin@celorisdesigns.com
```

## 🧪 Testing

```bash
# Run all tests
python3 test_ai_boss_admin.py

# Test specific functionality
curl http://localhost:8000/health
curl -X POST http://localhost:8000/api/courses/mathematics-class11
```

## 🔧 Maintenance

```bash
# Check system health
bash maintenance.sh --health

# View logs
bash maintenance.sh --logs

# Restart service
bash maintenance.sh --restart

# Backup database
bash maintenance.sh --backup
```

## 📚 Documentation

- **[Deployment Guide](docs/DEPLOYMENT_COMPLETE_GUIDE.md)** - Complete VPS deployment instructions
- **[Optimization Details](docs/OPTIMIZATION_COMPLETE.md)** - Technical improvements and features

## 🔐 Security Features

- Service role authentication for admin operations
- CORS protection
- Input validation and sanitization
- Error logging and monitoring
- RLS policy detection and recommendations

## 🆘 Troubleshooting

### Common Issues

1. **RLS Policy Errors**: System automatically detects and provides SQL fix commands
2. **Service Not Starting**: Check logs with `bash maintenance.sh --logs`
3. **Database Connection**: Verify Supabase credentials in `.env` file

### Support

For issues or questions:
- Check the logs: `bash maintenance.sh --logs`
- Run health check: `curl http://localhost:8000/health`
- Review documentation in `docs/` directory

## 📄 License

Proprietary - Celoris Designs

---

**Built for Celoris Designs VPS deployment** 🎯