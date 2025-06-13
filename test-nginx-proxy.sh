#!/bin/bash

# Test nginx proxy functionality
# Run this script to verify that nginx is properly proxying API requests

set -e

echo "🔍 Testing Nginx Proxy Configuration..."
echo "======================================"

PI_HOST="192.168.86.70"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    print_info "Testing $name: $url"
    
    if response=$(curl -s -w "%{http_code}" -o /tmp/response.txt "$url" 2>/dev/null); then
        status_code=${response}
        content=$(cat /tmp/response.txt)
        
        if [ "$status_code" -eq "$expected_status" ]; then
            print_success "$name: HTTP $status_code ✓"
            echo "Response: $content" | head -c 200
            echo ""
        else
            print_warning "$name: Expected $expected_status, got $status_code"
            echo "Response: $content"
        fi
    else
        print_error "$name: Connection failed"
    fi
    echo ""
}

# Test endpoints
echo "Testing endpoints..."
echo ""

# 1. Test health endpoint (should work)
test_endpoint "Health Check (via nginx)" "http://$PI_HOST/health"

# 2. Test API endpoint (main test)
test_endpoint "API Users Endpoint" "http://$PI_HOST/api/users"

# 3. Test direct backend (for comparison)
test_endpoint "Direct Backend Health" "http://$PI_HOST:5001/health"

# 4. Test direct backend API
test_endpoint "Direct Backend API" "http://$PI_HOST:5001/api/users"

# 5. Test root endpoint
test_endpoint "Root Endpoint" "http://$PI_HOST/"

echo "🏁 Testing complete!"
echo ""
echo "📋 What to check if tests fail:"
echo "  • Is Docker running? docker ps"
echo "  • Are services up? docker-compose -f docker-compose.dev.yml ps"
echo "  • Check nginx logs: docker-compose -f docker-compose.dev.yml logs nginx"
echo "  • Check backend logs: docker-compose -f docker-compose.dev.yml logs backend"
echo "  • Test from Pi directly: ssh colin@$PI_HOST 'curl http://localhost/health'"
echo ""
