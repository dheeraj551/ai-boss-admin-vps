#!/bin/bash

# AI Boss Admin - Maintenance Script
# For celorisdesigns.com VPS operations

set -e

# Configuration
APP_NAME="ai-boss-admin"
SERVICE_FILE="/etc/systemd/system/ai-boss-admin.service"
LOG_FILE="/var/log/ai-boss-admin.log"
BACKUP_DIR="/opt/ai-boss-admin/backups"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

show_status() {
    log_info "Checking AI Boss Admin status..."
    
    if systemctl is-active --quiet $APP_NAME.service; then
        log_success "Service is running"
        
        # Get service details
        echo
        echo "Service Information:"
        systemctl status $APP_NAME.service --no-pager -l | head -10
        
        # Check memory and CPU usage
        echo
        echo "Resource Usage:"
        systemctl show $APP_NAME.service --property=MainPID --value | xargs ps -p -o pid,pcpu,pmem,cmd --no-headers 2>/dev/null || echo "Process info not available"
        
        return 0
    else
        log_error "Service is not running"
        return 1
    fi
}

show_logs() {
    local lines=${1:-50}
    log_info "Showing last $lines log entries..."
    
    if [ -f "$LOG_FILE" ]; then
        echo
        echo "=== Recent Log Entries ==="
        tail -n $lines "$LOG_FILE"
        echo "========================="
    else
        log_warning "Log file not found: $LOG_FILE"
        log_info "Showing systemd journal logs instead..."
        sudo journalctl -u $APP_NAME.service -n $lines --no-pager
    fi
}

restart_service() {
    log_info "Restarting AI Boss Admin service..."
    
    if sudo systemctl restart $APP_NAME.service; then
        log_success "Service restarted successfully"
        
        # Wait and check status
        sleep 3
        if systemctl is-active --quiet $APP_NAME.service; then
            log_success "Service is running after restart"
        else
            log_error "Service failed to start after restart"
            show_logs 20
            return 1
        fi
    else
        log_error "Failed to restart service"
        return 1
    fi
}

stop_service() {
    log_info "Stopping AI Boss Admin service..."
    
    if sudo systemctl stop $APP_NAME.service; then
        log_success "Service stopped successfully"
    else
        log_error "Failed to stop service"
        return 1
    fi
}

start_service() {
    log_info "Starting AI Boss Admin service..."
    
    if sudo systemctl start $APP_NAME.service; then
        log_success "Service started successfully"
        
        # Wait and check status
        sleep 3
        if systemctl is-active --quiet $APP_NAME.service; then
            log_success "Service is running"
        else
            log_error "Service failed to start"
            show_logs 20
            return 1
        fi
    else
        log_error "Failed to start service"
        return 1
    fi
}

test_endpoints() {
    log_info "Testing API endpoints..."
    
    local host="localhost"
    local port="8000"
    local base_url="http://$host:$port"
    
    # Test health endpoint
    echo
    echo "Testing health endpoint:"
    if curl -s "$base_url/api/health" > /dev/null; then
        log_success "Health endpoint accessible"
        curl -s "$base_url/api/health" | python3 -m json.tool 2>/dev/null || curl -s "$base_url/api/health"
    else
        log_error "Health endpoint not accessible"
    fi
    
    # Test web interface
    echo
    echo "Testing web interface:"
    if curl -s "$base_url/" | grep -q "AI Boss Admin"; then
        log_success "Web interface accessible"
    else
        log_error "Web interface not accessible"
    fi
}

backup_data() {
    log_info "Creating backup..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="ai_boss_admin_backup_$timestamp"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    mkdir -p "$BACKUP_DIR"
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Backup application files
    if [ -d "/opt/ai-boss-admin" ]; then
        cp -r /opt/ai-boss-admin/* "$backup_path/" 2>/dev/null || true
        log_success "Application files backed up to $backup_path"
    else
        log_warning "Application directory not found"
    fi
    
    # Backup logs
    if [ -f "$LOG_FILE" ]; then
        cp "$LOG_FILE" "$backup_path/" 2>/dev/null || true
        log_success "Log files backed up"
    fi
    
    # Compress backup
    if command -v tar &> /dev/null; then
        cd "$BACKUP_DIR"
        tar -czf "${backup_name}.tar.gz" "$backup_name"
        rm -rf "$backup_name"
        log_success "Backup compressed: ${backup_name}.tar.gz"
    fi
    
    echo
    log_info "Backup completed in: $BACKUP_DIR"
}

cleanup_logs() {
    log_info "Cleaning up old logs..."
    
    # Clean application logs
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(du -h "$LOG_FILE" | cut -f1)
        log_info "Current log file size: $log_size"
        
        # Keep only last 1000 lines
        tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
        log_success "Log file trimmed"
    fi
    
    # Clean systemd journal (keep last 7 days)
    if command -v journalctl &> /dev/null; then
        sudo journalctl --vacuum-time=7d --vacuum-size=100M
        log_success "Systemd journal cleaned"
    fi
}

show_performance() {
    log_info "Showing performance metrics..."
    
    # Get service PID
    local pid=$(systemctl show $APP_NAME.service --property=MainPID --value)
    
    if [ "$pid" != "0" ]; then
        echo
        echo "=== Performance Metrics ==="
        
        # CPU and Memory usage
        ps -p $pid -o pid,pcpu,pmem,vsz,rss,cmd --no-headers
        
        # Network connections
        echo
        echo "Active Connections:"
        netstat -an | grep :8000 | grep ESTABLISHED | wc -l | xargs echo "Established connections:"
        
        # Disk usage
        echo
        echo "Disk Usage:"
        df -h /opt/ai-boss-admin 2>/dev/null | tail -1 || echo "Application directory disk info not available"
        
    else
        log_warning "Service is not running"
    fi
}

show_help() {
    echo "AI Boss Admin - Maintenance Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  status         Show service status and basic info"
    echo "  logs [lines]   Show recent logs (default: 50 lines)"
    echo "  restart        Restart the service"
    echo "  stop           Stop the service"
    echo "  start          Start the service"
    echo "  test           Test API endpoints"
    echo "  backup         Create data backup"
    echo "  cleanup        Clean up old logs"
    echo "  performance    Show performance metrics"
    echo "  help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs 100"
    echo "  $0 restart"
    echo "  $0 backup"
}

# Main execution
case "${1:-help}" in
    "status")
        show_status
        ;;
    "logs")
        show_logs "${2:-50}"
        ;;
    "restart")
        restart_service
        ;;
    "stop")
        stop_service
        ;;
    "start")
        start_service
        ;;
    "test")
        test_endpoints
        ;;
    "backup")
        backup_data
        ;;
    "cleanup")
        cleanup_logs
        ;;
    "performance")
        show_performance
        ;;
    "help"|*)
        show_help
        ;;
esac