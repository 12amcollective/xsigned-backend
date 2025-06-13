#!/bin/bash

# Check Development Environment Status
# Tests if the development backend is running on Pi

set -e

PI_HOST="192.168.86.70"
PI_USER="colin"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "🔍 Checking Development Environment Status"
echo "========================================"

# Test 1: Pi connectivity
print_info "Testing Pi connectivity..."
if ping -c 1 "$PI_HOST" > /dev/null 2>&1; then
    print_success "Pi is reachable at $PI_HOST"
else
    print_error "Cannot reach Pi at $PI_HOST"
    exit 1
fi

# Test 2: Backend health
print_info "Testing backend health..."
if curl -sf "http://$PI_HOST:5001/health" > /dev/null 2>&1; then
    print_success "Backend is running and healthy"
    echo "   Response: $(curl -s "http://$PI_HOST:5001/health")"
else
    print_error "Backend is not responding"
    echo "   Try: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && ./run.sh dev'"
fi

# Test 3: API endpoints
print_info "Testing API endpoints..."
if curl -sf "http://$PI_HOST:5001/api/users" > /dev/null 2>&1; then
    print_success "API endpoints are accessible"
else
    print_error "API endpoints are not responding"
fi

# Test 4: CORS for frontend
print_info "Testing CORS for local frontend..."
CORS_TEST=$(curl -s -H "Origin: http://localhost:5173" \
    -H "Access-Control-Request-Method: GET" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -X OPTIONS \
    "http://$PI_HOST:5001/api/users" -w "%{http_code}" -o /dev/null)

if [ "$CORS_TEST" = "200" ]; then
    print_success "CORS is configured for local frontend development"
else
    print_warning "CORS test returned status: $CORS_TEST"
fi

# Test 5: SSH access to Pi
print_info "Testing SSH access to Pi..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes "$PI_USER@$PI_HOST" exit 2>/dev/null; then
    print_success "SSH access to Pi is working"
    
    # Get service status from Pi
    print_info "Getting service status from Pi..."
    ssh "$PI_USER@$PI_HOST" "cd /home/$PI_USER/xsigned-backend && docker-compose -f docker-compose.dev.yml ps" 2>/dev/null || print_warning "Could not get service status"
else
    print_warning "SSH access requires password (keys not set up)"
fi

echo ""
echo "🌐 Development URLs:"
echo "   • Backend Health: http://$PI_HOST:5001/health"
echo "   • Backend API: http://$PI_HOST:5001/api"
echo "   • Local Frontend: http://localhost:5173 (when running npm run dev)"
echo ""
echo "🔧 Quick Commands:"
echo "   • Deploy to Pi: ./run.sh deploy-dev"
echo "   • Check logs: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && ./run.sh dev-logs'"
echo "   • Restart backend: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && ./run.sh dev'"
echo ""
