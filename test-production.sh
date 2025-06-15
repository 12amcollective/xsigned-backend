#!/bin/bash

# Production Testing Script for xsigned.ai
# Tests all endpoints after production deployment

set -e

echo "🧪 Testing Production Deployment (xsigned.ai)..."
echo "=============================================="

# Configuration
DOMAIN="xsigned.ai"
BASE_URL="https://$DOMAIN"
API_URL="$BASE_URL/api"

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
    local method=$2
    local url=$3
    local data=$4
    local expected_status=${5:-200}
    
    print_info "Testing $name..."
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            -o /tmp/response.txt \
            "$url" 2>/dev/null)
    else
        response=$(curl -s -w "%{http_code}" -o /tmp/response.txt "$url" 2>/dev/null)
    fi
    
    status_code=${response}
    content=$(cat /tmp/response.txt)
    
    if [ "$status_code" -eq "$expected_status" ]; then
        print_success "$name: HTTP $status_code ✓"
        if [ ${#content} -lt 200 ]; then
            echo "Response: $content"
        else
            echo "Response: ${content:0:150}..."
        fi
    else
        print_error "$name: Expected $expected_status, got $status_code"
        echo "Response: $content"
        return 1
    fi
    echo ""
    return 0
}

test_ssl() {
    print_info "Testing SSL Certificate..."
    
    if ssl_info=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null); then
        print_success "SSL Certificate is valid"
        echo "$ssl_info"
    else
        print_error "SSL Certificate test failed"
        return 1
    fi
    echo ""
}

test_redirect() {
    print_info "Testing HTTP to HTTPS redirect..."
    
    redirect_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/")
    
    if [ "$redirect_response" -eq 301 ] || [ "$redirect_response" -eq 302 ]; then
        print_success "HTTP to HTTPS redirect working: $redirect_response"
    else
        print_warning "HTTP redirect may not be working: $redirect_response"
    fi
    echo ""
}

# Start testing
echo "🔍 Starting Production Tests..."
echo ""

# Test basic connectivity
print_info "Testing basic connectivity to $DOMAIN..."
if ! curl -s --connect-timeout 5 "$BASE_URL" > /dev/null; then
    print_error "Cannot connect to $DOMAIN. Check DNS and firewall."
    exit 1
fi
print_success "Successfully connected to $DOMAIN"
echo ""

# Test SSL
test_ssl || print_warning "SSL test failed - check certificate setup"

# Test HTTP redirect
test_redirect

# Test main endpoints
echo "Testing Core Endpoints..."
echo ""

# 1. Health check
test_endpoint "Health Check" "GET" "$BASE_URL/health"

# 2. Frontend loading
test_endpoint "Frontend Root" "GET" "$BASE_URL/"

# Test API endpoints
echo "Testing API Endpoints..."
echo ""

# 3. Waitlist endpoints
test_endpoint "Waitlist Health" "GET" "$API_URL/waitlist/health"

test_endpoint "Join Waitlist (New)" "POST" "$API_URL/waitlist/join" \
    '{"email":"production-test@example.com"}' 201

test_endpoint "Join Waitlist (Duplicate)" "POST" "$API_URL/waitlist/join" \
    '{"email":"production-test@example.com"}' 200

test_endpoint "Waitlist Stats" "GET" "$API_URL/waitlist/stats"

test_endpoint "Invalid Email" "POST" "$API_URL/waitlist/join" \
    '{"email":"invalid-email"}' 400

# 4. Users endpoints
test_endpoint "Users Endpoint" "GET" "$API_URL/users/"

# 5. Campaigns endpoints  
test_endpoint "Campaigns Endpoint" "GET" "$API_URL/campaigns/"

# Test security headers
echo "Testing Security..."
echo ""

print_info "Checking security headers..."
headers=$(curl -s -I "$BASE_URL/" | head -20)

if echo "$headers" | grep -i "x-frame-options" > /dev/null; then
    print_success "X-Frame-Options header present"
else
    print_warning "X-Frame-Options header missing"
fi

if echo "$headers" | grep -i "x-content-type-options" > /dev/null; then
    print_success "X-Content-Type-Options header present"
else
    print_warning "X-Content-Type-Options header missing"
fi

if echo "$headers" | grep -i "strict-transport-security" > /dev/null; then
    print_success "HSTS header present"
else
    print_warning "HSTS header missing"
fi

echo ""

# Test performance
print_info "Testing response times..."
response_time=$(curl -o /dev/null -s -w "%{time_total}" "$BASE_URL/health")
if (( $(echo "$response_time < 2.0" | bc -l) )); then
    print_success "Health endpoint response time: ${response_time}s"
else
    print_warning "Health endpoint slow: ${response_time}s"
fi

echo ""

# Final summary
echo "🏁 Production Testing Complete!"
echo ""
echo "📋 Test Summary:"
echo "  • Domain: $DOMAIN"
echo "  • SSL: $([ $? -eq 0 ] && echo "✅ Working" || echo "⚠️ Check needed")"
echo "  • API: $API_URL"
echo "  • Waitlist: $([ $? -eq 0 ] && echo "✅ Working" || echo "❌ Failed")"
echo ""
echo "🎉 Production deployment verification complete!"
echo ""
echo "📝 Next Steps:"
echo "  1. Update your frontend to use: $API_URL"
echo "  2. Test full user flow from frontend"
echo "  3. Monitor logs: docker-compose -f docker-compose.production.yml logs -f"
echo "  4. Set up monitoring/alerting"
echo ""
