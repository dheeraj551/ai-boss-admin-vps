#!/bin/bash

# AI Boss Admin - Production Startup Script
# Optimized for celorisdesigns.com VPS deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="ai-boss-admin"
APP_DIR="/opt/ai-boss-admin"
SERVICE_FILE="/etc/systemd/system/ai-boss-admin.service"
PYTHON_VERSION="python3"
VENV_DIR="/opt/ai-boss-admin/venv"
LOG_FILE="/var/log/ai-boss-admin.log"
PID_FILE="/var/run/ai-boss-admin.pid"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons"
        exit 1
    fi
    
    # Check Python version
    if ! command -v $PYTHON_VERSION &> /dev/null; then
        log_error "Python 3 is required but not installed"
        exit 1
    fi
    
    local python_version=$($PYTHON_VERSION --version | cut -d" " -f2)
    log_success "Python version: $python_version"
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        log_error "pip3 is required but not installed"
        exit 1
    fi
    
    log_success "All requirements met"
}

create_directories() {
    log_info "Creating necessary directories..."
    
    sudo mkdir -p $APP_DIR
    sudo mkdir -p /var/log/ai-boss-admin
    sudo mkdir -p /var/run/ai-boss-admin
    sudo mkdir -p /opt/ai-boss-admin/venv
    sudo mkdir -p /opt/ai-boss-admin/logs
    sudo mkdir -p /opt/ai-boss-admin/blogs
    sudo mkdir -p /opt/ai-boss-admin/backups
    
    # Set proper permissions
    sudo chown -R $USER:$USER $APP_DIR
    sudo chmod 755 $APP_DIR
    
    log_success "Directories created"
}

setup_virtual_environment() {
    log_info "Setting up Python virtual environment..."
    
    cd $APP_DIR
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_DIR" ]; then
        $PYTHON_VERSION -m venv $VENV_DIR
        log_success "Virtual environment created"
    fi
    
    # Activate virtual environment
    source $VENV_DIR/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install production requirements
    if [ -f "requirements.production.txt" ]; then
        pip install -r requirements.production.txt
        log_success "Production requirements installed"
    else
        # Install core packages
        pip install fastapi uvicorn python-multipart requests loguru python-dotenv pydantic
        log_success "Core packages installed"
    fi
    
    deactivate
    log_success "Virtual environment setup complete"
}

copy_application_files() {
    log_info "Copying application files..."
    
    # Copy the optimized admin system
    cp optimized_ai_boss_admin.py $APP_DIR/
    cp .env.production $APP_DIR/.env
    
    # Copy any additional files
    if [ -f "ai_boss_admin.py" ]; then
        cp ai_boss_admin.py $APP_DIR/
    fi
    
    if [ -f "create_mathematics_course.py" ]; then
        cp create_mathematics_course.py $APP_DIR/
    fi
    
    log_success "Application files copied"
}

create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat << EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=AI Boss Admin - Optimized Database Management System
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
Environment=PATH=$VENV_DIR/bin
ExecStart=$VENV_DIR/bin/python optimized_ai_boss_admin.py
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
SyslogIdentifier=ai-boss-admin

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

# Resource limits
MemoryLimit=1G
CPUQuota=80%

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    sudo systemctl daemon-reload
    sudo systemctl enable ai-boss-admin.service
    
    log_success "Systemd service created"
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    # Check if ufw is installed
    if command -v ufw &> /dev/null; then
        # Allow port 8000
        sudo ufw allow 8000/tcp comment "AI Boss Admin"
        log_success "Firewall configured for port 8000"
    else
        log_warning "UFW not found. Please manually configure firewall to allow port 8000"
    fi
}

start_service() {
    log_info "Starting AI Boss Admin service..."
    
    # Start the service
    sudo systemctl start ai-boss-admin.service
    
    # Wait a moment for startup
    sleep 5
    
    # Check status
    if sudo systemctl is-active --quiet ai-boss-admin.service; then
        log_success "AI Boss Admin service started successfully"
        
        # Get service status
        sudo systemctl status ai-boss-admin.service --no-pager -l
        
        # Show access information
        echo
        log_info "🎉 AI Boss Admin is now running!"
        log_info "📊 Web Interface: http://$(hostname -I | awk '{print $1}'):8000"
        log_info "🔧 Admin Dashboard: http://$(hostname -I | awk '{print $1}'):8000/"
        log_info "📋 API Documentation: http://$(hostname -I | awk '{print $1}'):8000/docs"
        log_info "📊 Health Check: http://$(hostname -I | awk '{print $1}'):8000/api/health"
        echo
        
        # Service management commands
        log_info "Service Management Commands:"
        echo "  Start:   sudo systemctl start ai-boss-admin"
        echo "  Stop:    sudo systemctl stop ai-boss-admin"
        echo "  Restart: sudo systemctl restart ai-boss-admin"
        echo "  Status:  sudo systemctl status ai-boss-admin"
        echo "  Logs:    sudo journalctl -u ai-boss-admin -f"
        echo "  Log file: $LOG_FILE"
        
    else
        log_error "Failed to start AI Boss Admin service"
        log_info "Checking logs..."
        sudo journalctl -u ai-boss-admin.service --no-pager -n 20
        exit 1
    fi
}

verify_installation() {
    log_info "Verifying installation..."
    
    # Check if service is running
    if sudo systemctl is-active --quiet ai-boss-admin.service; then
        log_success "Service is running"
        
        # Test web interface
        local host_ip=$(hostname -I | awk '{print $1}')
        local health_url="http://localhost:8000/api/health"
        
        if curl -s $health_url > /dev/null; then
            log_success "Web interface is accessible"
            
            # Show system status
            echo
            log_info "System Status:"
            curl -s $health_url | python3 -m json.tool 2>/dev/null || echo "Health check response received"
            
        else
            log_warning "Web interface may not be ready yet"
        fi
        
    else
        log_error "Service is not running"
        exit 1
    fi
}

show_next_steps() {
    echo
    log_info "🚀 NEXT STEPS:"
    echo
    echo "1. 🔧 FIX RLS POLICY (Required for course creation):"
    echo "   - Go to your Supabase Dashboard"
    echo "   - Navigate to SQL Editor"
    echo "   - Execute this SQL command:"
    echo ""
    echo "   CREATE POLICY \"Allow admin to manage courses\" "
    echo "   ON public.courses "
    echo "   FOR ALL "
    echo "   TO authenticated "
    echo "   USING (auth.uid() = '550e8400-e29b-41d4-a716-446655440000'::uuid)"
    echo "   WITH CHECK (auth.uid() = '550e8400-e29b-41d4-a716-446655440000'::uuid);"
    echo ""
    echo "2. 🧪 TEST COURSE CREATION:"
    echo "   curl -X POST http://localhost:8000/api/courses/mathematics-class11"
    echo ""
    echo "3. 🌐 ACCESS WEB INTERFACE:"
    echo "   http://$(hostname -I | awk '{print $1}'):8000"
    echo ""
    echo "4. 📊 MONITOR LOGS:"
    echo "   sudo journalctl -u ai-boss-admin -f"
    echo ""
    log_success "AI Boss Admin deployment complete!"
}

# Main execution
main() {
    echo
    echo "=================================="
    echo "🚀 AI Boss Admin - Production Setup"
    echo "=================================="
    echo
    
    check_requirements
    create_directories
    setup_virtual_environment
    copy_application_files
    create_systemd_service
    configure_firewall
    start_service
    verify_installation
    show_next_steps
}

# Run main function
main "$@"