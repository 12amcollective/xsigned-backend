#!/bin/bash

# Development Testing Script for Raspberry Pi
# Tests the development environment setup

echo "🧪 Testing Development Environment..."
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}🧪 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local command="$2"
    
    print_test "$test_name"
    
    if eval "$command" > /dev/null 2>&1; then
        print_success "$test_name passed"
        ((TESTS_PASSED++))
    else
        print_error "$test_name failed"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Docker services are running
print_test "Checking Docker services..."
if docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
    print_success "Docker services are running"
    ((TESTS_PASSED++))
else
    print_error "Docker services are not running"
    ((TESTS_FAILED++))
fi

# Test 2: Database connectivity
run_test "Database connectivity" "docker-compose -f docker-compose.dev.yml exec -T postgres pg_isready -U backend_user"

# Test 3: Backend health check
run_test "Backend health check" "curl -sf http://localhost:5001/health"

# Test 4: API endpoints
run_test "API health endpoint" "curl -sf http://localhost:5001/api/health"

# Test 5: CORS headers
print_test "CORS headers test"
cors_response=$(curl -sI -X OPTIONS "http://localhost:5001/api/users" -H "Origin: http://localhost:3000" 2>/dev/null)
if echo "$cors_response" | grep -qi "access-control-allow-origin"; then
    print_success "CORS headers present"
    ((TESTS_PASSED++))
else
    print_error "CORS headers missing"
    ((TESTS_FAILED++))
fi

# Test 6: Create test user
print_test "Create test user"
create_response=$(curl -s -X POST "http://localhost:5001/api/users" \
    -H "Content-Type: application/json" \
    -d '{"email":"test@dev.local","username":"devtester"}' 2>/dev/null)

if echo "$create_response" | grep -q "id"; then
    print_success "User creation works"
    ((TESTS_PASSED++))
    
    # Extract user ID for campaign test
    USER_ID=$(echo "$create_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    
    # Test 7: Create test campaign
    print_test "Create test campaign"
    campaign_response=$(curl -s -X POST "http://localhost:5001/api/campaigns" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\":$USER_ID,\"name\":\"Dev Test Campaign\",\"description\":\"Testing in development\"}" 2>/dev/null)
    
    if echo "$campaign_response" | grep -q "id"; then
        print_success "Campaign creation works"
        ((TESTS_PASSED++))
    else
        print_error "Campaign creation failed"
        ((TESTS_FAILED++))
    fi
else
    print_error "User creation failed"
    ((TESTS_FAILED++))
fi

# Test 8: Network connectivity from Pi
print_test "External network connectivity"
if ping -c 1 google.com > /dev/null 2>&1; then
    print_success "External network works"
    ((TESTS_PASSED++))
else
    print_error "External network failed"
    ((TESTS_FAILED++))
fi

# Test 9: Resource usage
print_test "Resource usage check"
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
if (( $(echo "$MEMORY_USAGE < 80" | bc -l) )); then
    print_success "Memory usage OK (${MEMORY_USAGE}%)"
    ((TESTS_PASSED++))
else
    print_error "High memory usage (${MEMORY_USAGE}%)"
    ((TESTS_FAILED++))
fi

# Summary
echo ""
echo "📊 Test Results Summary"
echo "======================="
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! ($TESTS_PASSED/$TOTAL_TESTS)${NC}"
    echo ""
    echo "✅ Development environment is ready!"
    echo "✅ Backend API is working"
    echo "✅ Database connectivity verified"
    echo "✅ CORS configured properly"
    echo ""
    echo "🚀 Ready for frontend development!"
else
    echo -e "${YELLOW}⚠️  $TESTS_PASSED/$TOTAL_TESTS tests passed ($SUCCESS_RATE% success rate)${NC}"
    echo ""
    if [ $TESTS_FAILED -gt 0 ]; then
        echo "🔧 Issues to fix:"
        echo "   • Check failed tests above"
        echo "   • View logs: docker-compose -f docker-compose.dev.yml logs"
    fi
fi

echo ""
echo "📋 Development Info:"
echo "   • Backend API: http://192.168.86.70:5001"
echo "   • Health check: http://192.168.86.70:5001/health"
echo "   • Database: localhost:5432"
echo ""
echo "🛠️ Useful Commands:"
echo "   • View logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "   • Restart: docker-compose -f docker-compose.dev.yml restart"
echo "   • Stop: docker-compose -f docker-compose.dev.yml down"
echo ""

exit $TESTS_FAILED
