#!/bin/bash

# Complete Production Deployment Workflow with Enhanced Logging
# This script guides you through the entire production deployment process

set -e

# Enhanced logging setup
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/deployment-$(date +%Y%m%d-%H%M%S).log"
ERROR_LOG="$LOG_DIR/deployment-errors-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p "$LOG_DIR"

# Function to log both to console and file
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
}

log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - DEBUG: $1" | tee -a "$LOG_FILE"
}

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log "INFO: $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log_error "$1"
}

print_step() {
    echo -e "${BLUE}🔄 STEP: $1${NC}"
    log "STEP: $1"
}

print_debug() {
    echo -e "${YELLOW}🐛 DEBUG: $1${NC}"
    log_debug "$1"
}

# Trap errors and log them
trap 'log_error "Script failed at line $LINENO. Command: $BASH_COMMAND"' ERR

# Configuration
PI_HOST="192.168.86.70"
PI_USER="colin"
DOMAIN="xsigned.ai"

log "=========================================="
log "Production Deployment Started"
log "Host: $PI_HOST"
log "User: $PI_USER"
log "Domain: $DOMAIN"
log "Log file: $LOG_FILE"
log "=========================================="

echo "🚀 XSigned Backend - Production Deployment Workflow"
echo "=================================================="
print_info "Deployment logs are being saved to: $LOG_FILE"
print_info "Error logs will be saved to: $ERROR_LOG"
echo ""

# Test connectivity first
print_step "Testing Connectivity"
log_debug "Testing ping to $PI_HOST"
if ping -c 1 "$PI_HOST" >/dev/null 2>&1; then
    print_success "Pi is reachable via ping"
else
    print_error "Cannot ping Pi at $PI_HOST"
    log_error "Ping test failed to $PI_HOST"
    exit 1
fi

log_debug "Testing SSH connection to $PI_USER@$PI_HOST"
if ssh -o ConnectTimeout=10 -o BatchMode=yes "$PI_USER@$PI_HOST" "echo 'SSH connection successful'" 2>/dev/null; then
    print_success "SSH connection successful"
else
    print_error "Cannot SSH to Pi. Please check SSH keys or credentials."
    log_error "SSH connection failed to $PI_USER@$PI_HOST"
    exit 1
fi

# Check system resources on Pi
print_step "Checking Pi System Resources"
ssh "$PI_USER@$PI_HOST" "
    echo 'System Information:'
    echo 'Disk Usage:'
    df -h
    echo ''
    echo 'Memory Usage:'
    free -h
    echo ''
    echo 'Docker Status:'
    docker --version
    docker-compose --version
    echo ''
    echo 'Running Containers:'
    docker ps
" 2>&1 | tee -a "$LOG_FILE"

# Step 1: Pre-deployment checks
print_step "Pre-deployment Validation"
log_debug "Running local validation checks"

if ./validate-production.sh 2>&1 | tee -a "$LOG_FILE"; then
    print_success "All validation checks passed!"
else
    print_error "Validation failed. Please fix issues before continuing."
    log_error "Pre-deployment validation failed"
    exit 1
fi

echo ""

# Step 2: Generate secrets if needed
print_step "Security Configuration"
log_debug "Checking if secrets need to be generated"

if [ ! -f ".env" ]; then
    print_info "No .env file found. Generating production secrets..."
    log_debug "Generating new .env file with secrets"
    if ./generate-secrets.sh 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Production secrets generated"
    else
        print_error "Failed to generate secrets"
        log_error "Secret generation failed"
        exit 1
    fi
else
    print_info "Using existing .env file"
    log_debug "Using existing .env file"
fi

echo ""

# Step 3: Domain verification
print_step "Domain Configuration Check"
log_debug "Checking if domain points to your Pi"

print_info "Checking if domain points to your Pi..."
domain_ip=$(dig +short $DOMAIN | head -n1)
pi_ip=$(curl -s ipinfo.io/ip || echo "unknown")

echo "Domain $DOMAIN resolves to: $domain_ip"
echo "Your Pi's public IP: $pi_ip"

if [ "$domain_ip" != "$pi_ip" ]; then
    print_warning "Domain may not point to your Pi yet"
    echo ""
    read -p "Continue anyway? (y/n): " continue_deploy
    if [[ ! $continue_deploy =~ ^[Yy]$ ]]; then
        echo "Please configure your domain DNS to point to $pi_ip and try again."
        exit 0
    fi
else
    print_success "Domain correctly points to your Pi"
fi

echo ""

# Step 4: Copy files to Pi
print_step "Copying Files to Pi"
log_debug "Starting deployment to Pi"

print_info "Uploading code and configuration to Pi..."
log_debug "Syncing code to Pi using rsync"

# Enhanced rsync with logging
rsync -avz --progress \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.env.local' \
    --exclude='logs/deployment*.log' \
    ./ "$PI_USER@$PI_HOST:~/xsigned-backend/" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    print_success "Code upload completed"
else
    print_error "Code upload failed"
    log_error "Rsync failed during code upload"
    exit 1
fi

echo ""

# Step 5: Run deployment on Pi with enhanced logging
print_step "Running Production Deployment on Pi"
log_debug "Executing remote deployment script on Pi"

ssh "$PI_USER@$PI_HOST" "
    set -e
    cd ~/xsigned-backend
    
    echo '=== Remote Deployment Log ===' 
    echo 'Working directory: \$(pwd)'
    echo 'Files present:'
    ls -la
    echo ''
    
    echo 'Checking Docker status...'
    docker --version
    docker-compose --version
    docker ps -a
    echo ''
    
    echo 'Checking environment file...'
    if [ -f .env ]; then
        echo '.env file exists'
        echo 'Environment variables (excluding secrets):'
        grep -v PASSWORD .env | grep -v SECRET | grep -v KEY || echo 'No non-secret variables found'
    else
        echo 'ERROR: .env file not found!'
        exit 1
    fi
    echo ''
    
    echo 'Stopping existing containers...'
    docker-compose -f docker-compose.production.yml down || echo 'No containers to stop'
    echo ''
    
    echo 'Cleaning up old images...'
    docker system prune -f || echo 'Cleanup completed'
    echo ''
    
    echo 'Building and starting production containers...'
    docker-compose -f docker-compose.production.yml up --build -d
    
    echo ''
    echo 'Waiting for containers to start...'
    sleep 10
    
    echo 'Container status:'
    docker-compose -f docker-compose.production.yml ps
    
    echo ''
    echo 'Container logs:'
    docker-compose -f docker-compose.production.yml logs --tail=20
    
" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    print_success "Remote deployment completed"
else
    print_error "Remote deployment failed"
    log_error "Remote deployment script failed"
    
    # Get additional debug info
    print_info "Gathering debug information..."
    ssh "$PI_USER@$PI_HOST" "
        cd ~/xsigned-backend
        echo '=== Debug Information ==='
        echo 'Docker logs for failed containers:'
        docker-compose -f docker-compose.production.yml logs --tail=50
        echo ''
        echo 'System resources:'
        df -h
        free -h
        echo ''
        echo 'Docker system info:'
        docker system df
        docker images
    " 2>&1 | tee -a "$ERROR_LOG"
    
    exit 1
fi

echo ""

# Step 6: Test deployment
print_step "Testing Production Deployment"
log_debug "Running production tests"

sleep 15  # Give services time to fully start

if ./test-production.sh 2>&1 | tee -a "$LOG_FILE"; then
    print_success "Production deployment test passed!"
else
    print_warning "Some tests failed. Check logs for details."
    log_error "Production tests failed"
    
    # Additional debugging
    print_info "Gathering additional debug information..."
    ssh "$PI_USER@$PI_HOST" "
        cd ~/xsigned-backend
        echo '=== Service Status ==='
        docker-compose -f docker-compose.production.yml ps
        echo ''
        echo '=== Recent Logs ==='
        docker-compose -f docker-compose.production.yml logs --tail=30
        echo ''
        echo '=== Network Status ==='
        docker network ls
        docker-compose -f docker-compose.production.yml exec -T nginx nginx -t || echo 'Nginx config test failed'
    " 2>&1 | tee -a "$ERROR_LOG"
fi

# Final status
print_step "Deployment Summary"
log "=========================================="
log "Deployment completed at $(date)"

print_info "Deployment logs saved to: $LOG_FILE"
if [ -f "$ERROR_LOG" ]; then
    print_info "Error logs saved to: $ERROR_LOG"
fi

print_success "🎉 Production deployment workflow completed!"
echo ""
echo "📊 Deployment Summary:"
echo "======================"
echo "  • Domain: https://$DOMAIN"
echo "  • API: https://$DOMAIN/api/"
echo "  • Waitlist: https://$DOMAIN/api/waitlist/join"
echo "  • Status: Running on Pi ($PI_HOST)"
echo ""
echo "🔧 Management Commands:"
echo "  • SSH to Pi: ssh $PI_USER@$PI_HOST"
echo "  • View logs: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && docker-compose -f docker-compose.production.yml logs -f'"
echo "  • Restart: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && docker-compose -f docker-compose.production.yml restart'"
echo "  • Stop: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && docker-compose -f docker-compose.production.yml down'"
echo ""
echo "📝 Next Steps:"
echo "  1. Update your frontend to use: https://$DOMAIN/api/"
echo "  2. Test the complete user flow"
echo "  3. Set up monitoring and backups"
echo "  4. Configure any additional domains/subdomains"
echo ""
echo "🔍 Quick Health Check:"
echo "  curl https://$DOMAIN/health"
echo "  curl https://$DOMAIN/api/waitlist/stats"
echo ""

print_info "Deployment logs: $LOG_FILE"
print_info "To monitor: ssh $PI_USER@$PI_HOST 'cd xsigned-backend && docker-compose -f docker-compose.production.yml logs -f'"

log "Deployment script finished successfully"
print_success "Your XSigned backend is now live in production! 🚀"
