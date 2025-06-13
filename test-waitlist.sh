#!/bin/bash

# Test the waitlist endpoint
# Run this after deploying to verify the waitlist functionality works

set -e

echo "🧪 Testing Waitlist Endpoint..."
echo "=============================="

# Configuration
PI_HOST="192.168.86.70"
API_PORT="8080"
BASE_URL="http://$PI_HOST:$API_PORT/api"

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
    local endpoint=$3
    local data=$4
    local expected_status=${5:-200}
    
    print_info "Testing $name..."
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            -o /tmp/response.txt \
            "$endpoint" 2>/dev/null)
    else
        response=$(curl -s -w "%{http_code}" -o /tmp/response.txt "$endpoint" 2>/dev/null)
    fi
    
    status_code=${response}
    content=$(cat /tmp/response.txt)
    
    if [ "$status_code" -eq "$expected_status" ]; then
        print_success "$name: HTTP $status_code ✓"
        echo "Response: $content"
    else
        print_warning "$name: Expected $expected_status, got $status_code"
        echo "Response: $content"
    fi
    echo ""
}

# Test basic API health first
print_info "Testing basic API health..."
test_endpoint "API Health Check" "GET" "$BASE_URL/../health"

# Test waitlist endpoints
echo "Testing Waitlist Endpoints..."
echo ""

# 1. Test waitlist health
test_endpoint "Waitlist Health" "GET" "$BASE_URL/waitlist/health"

# 2. Test joining waitlist with valid email
test_endpoint "Join Waitlist (Valid Email)" "POST" "$BASE_URL/waitlist/join" \
    '{"email":"test@example.com"}' 201

# 3. Test joining waitlist with same email (should return 200)
test_endpoint "Join Waitlist (Duplicate Email)" "POST" "$BASE_URL/waitlist/join" \
    '{"email":"test@example.com"}' 200

# 4. Test joining waitlist with invalid email
test_endpoint "Join Waitlist (Invalid Email)" "POST" "$BASE_URL/waitlist/join" \
    '{"email":"invalid-email"}' 400

# 5. Test joining waitlist with no email
test_endpoint "Join Waitlist (No Email)" "POST" "$BASE_URL/waitlist/join" \
    '{}' 400

# 6. Test waitlist stats
test_endpoint "Waitlist Stats" "GET" "$BASE_URL/waitlist/stats"

# 7. Test getting all waitlist entries
test_endpoint "All Waitlist Entries" "GET" "$BASE_URL/waitlist/"

echo "🏁 Waitlist testing complete!"
echo ""
echo "📋 Test Results Summary:"
echo "  • If all tests passed, your waitlist endpoint is working correctly"
echo "  • The frontend can now POST to $BASE_URL/waitlist/join"
echo "  • Expected request format: {\"email\": \"user@example.com\"}"
echo ""
echo "🔧 Frontend Integration:"
echo "  • URL: $BASE_URL/waitlist/join"
echo "  • Method: POST"
echo "  • Content-Type: application/json"
echo "  • Body: {\"email\": \"user@example.com\"}"
echo ""
