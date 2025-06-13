#!/bin/bash

# System Status Checker for Music Campaign Backend
# Run this script to get a comprehensive overview of your deployment

echo "🔍 Music Campaign Backend - System Status Check"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Docker is running
echo "🐳 Docker Status:"
if systemctl is-active --quiet docker; then
    print_success "Docker is running"
    docker --version
else
    print_error "Docker is not running"
fi
echo ""

# Check Docker Compose services
echo "📊 Service Status:"
if [ -f "docker-compose.production.yml" ]; then
    docker-compose -f docker-compose.production.yml ps
else
    print_warning "docker-compose.production.yml not found"
fi
echo ""

# Check individual service health
echo "🏥 Health Checks:"

# PostgreSQL
if docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U backend_user > /dev/null 2>&1; then
    print_success "PostgreSQL is healthy"
else
    print_error "PostgreSQL is not responding"
fi

# Backend API
if curl -sf http://localhost/health > /dev/null 2>&1; then
    print_success "Backend API is healthy"
else
    print_error "Backend API is not responding"
fi

# Frontend
if curl -sf http://localhost > /dev/null 2>&1; then
    print_success "Frontend is serving"
else
    print_error "Frontend is not responding"
fi

# Nginx
if docker-compose -f docker-compose.production.yml ps | grep nginx | grep -q "Up"; then
    print_success "Nginx is running"
else
    print_error "Nginx is not running"
fi

echo ""

# Check Cloudflare Tunnel
echo "☁️  Cloudflare Tunnel:"
if systemctl is-active --quiet cloudflared 2>/dev/null; then
    print_success "Cloudflare Tunnel service is running"
    
    # Check if tunnel is actually connected
    if sudo journalctl -u cloudflared --since "5 minutes ago" | grep -q "tunnel"; then
        print_success "Tunnel appears to be connected"
    else
        print_warning "Tunnel service running but connection status unclear"
    fi
elif docker-compose -f docker-compose.production.yml ps | grep cloudflared | grep -q "Up"; then
    print_success "Cloudflare Tunnel container is running"
else
    print_error "Cloudflare Tunnel is not running"
fi
echo ""

# Check system resources
echo "💻 System Resources:"
echo "Memory Usage:"
free -h | grep Mem | awk '{printf "  Used: %s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'

echo "Disk Usage:"
df -h / | tail -1 | awk '{printf "  Used: %s / %s (%s)\n", $3, $2, $5}'

echo "CPU Load:"
uptime | awk -F'load average:' '{print "  " $2}'
echo ""

# Check logs for recent errors
echo "📋 Recent Issues:"
ERROR_COUNT=0

# Check for recent Docker errors
if docker-compose -f docker-compose.production.yml logs --tail=50 --since="1h" 2>/dev/null | grep -i error > /dev/null; then
    print_warning "Found recent errors in Docker logs"
    ((ERROR_COUNT++))
fi

# Check for recent system errors
if journalctl --since="1 hour ago" --priority=err --quiet | head -1 > /dev/null 2>&1; then
    print_warning "Found recent system errors"
    ((ERROR_COUNT++))
fi

if [ $ERROR_COUNT -eq 0 ]; then
    print_success "No recent errors found"
fi
echo ""

# Check network connectivity
echo "🌐 Network Status:"

# Test local connectivity
if curl -sf http://localhost/health > /dev/null 2>&1; then
    print_success "Local API accessible"
else
    print_error "Local API not accessible"
fi

# Test external connectivity (if tunnel is configured)
if [ -f ".env" ] && grep -q "xsigned.ai" .env; then
    if curl -sf https://xsigned.ai/health > /dev/null 2>&1; then
        print_success "External site accessible (https://xsigned.ai)"
    else
        print_warning "External site not accessible or tunnel not configured"
    fi
fi
echo ""

# Database status
echo "🗄️  Database Status:"
if docker-compose -f docker-compose.production.yml exec -T postgres psql -U backend_user -d music_campaigns -c "SELECT COUNT(*) as user_count FROM users;" > /dev/null 2>&1; then
    USER_COUNT=$(docker-compose -f docker-compose.production.yml exec -T postgres psql -U backend_user -d music_campaigns -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' \n')
    CAMPAIGN_COUNT=$(docker-compose -f docker-compose.production.yml exec -T postgres psql -U backend_user -d music_campaigns -t -c "SELECT COUNT(*) FROM campaigns;" 2>/dev/null | tr -d ' \n')
    
    print_success "Database is accessible"
    print_info "Users: $USER_COUNT"
    print_info "Campaigns: $CAMPAIGN_COUNT"
else
    print_error "Cannot access database"
fi
echo ""

# Backup status
echo "💾 Backup Status:"
if [ -d "/home/$(whoami)/backups" ]; then
    BACKUP_COUNT=$(ls -1 /home/$(whoami)/backups/music_campaigns_*.sql 2>/dev/null | wc -l)
    if [ $BACKUP_COUNT -gt 0 ]; then
        LATEST_BACKUP=$(ls -t /home/$(whoami)/backups/music_campaigns_*.sql 2>/dev/null | head -1)
        BACKUP_DATE=$(stat -c %y "$LATEST_BACKUP" 2>/dev/null | cut -d' ' -f1)
        print_success "Found $BACKUP_COUNT backup(s)"
        print_info "Latest backup: $BACKUP_DATE"
    else
        print_warning "No backups found"
    fi
else
    print_warning "Backup directory not found"
fi

# Check cron jobs
if crontab -l 2>/dev/null | grep -q backup-database.sh; then
    print_success "Automatic backup scheduled"
else
    print_warning "Automatic backup not scheduled"
fi
echo ""

# Summary
echo "📊 Summary:"
echo "=================================================="

# Overall health score
HEALTH_SCORE=0
TOTAL_CHECKS=6

# Docker running
systemctl is-active --quiet docker && ((HEALTH_SCORE++))

# Services running
docker-compose -f docker-compose.production.yml ps | grep -q "Up" && ((HEALTH_SCORE++))

# API responding
curl -sf http://localhost/health > /dev/null 2>&1 && ((HEALTH_SCORE++))

# Database responding
docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U backend_user > /dev/null 2>&1 && ((HEALTH_SCORE++))

# Tunnel running
(systemctl is-active --quiet cloudflared || docker-compose -f docker-compose.production.yml ps | grep cloudflared | grep -q "Up") && ((HEALTH_SCORE++))

# No recent errors
[ $ERROR_COUNT -eq 0 ] && ((HEALTH_SCORE++))

HEALTH_PERCENTAGE=$((HEALTH_SCORE * 100 / TOTAL_CHECKS))

if [ $HEALTH_PERCENTAGE -ge 85 ]; then
    print_success "System Health: $HEALTH_PERCENTAGE% ($HEALTH_SCORE/$TOTAL_CHECKS) - Excellent! 🎉"
elif [ $HEALTH_PERCENTAGE -ge 70 ]; then
    print_warning "System Health: $HEALTH_PERCENTAGE% ($HEALTH_SCORE/$TOTAL_CHECKS) - Good, minor issues 👍"
else
    print_error "System Health: $HEALTH_PERCENTAGE% ($HEALTH_SCORE/$TOTAL_CHECKS) - Needs attention! 🔧"
fi

echo ""
echo "🔧 Quick Actions:"
echo "  • Restart services: ./restart-services.sh"
echo "  • View logs: ./check-logs.sh"
echo "  • Backup database: ./backup-database.sh"
echo "  • Full deployment: ./deploy-to-pi.sh"
echo ""
echo "📚 Documentation: ./DEPLOYMENT.md"
echo "=================================================="
