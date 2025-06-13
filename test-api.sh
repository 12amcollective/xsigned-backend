#!/bin/bash

# API Integration Test Suite for Music Campaign Backend
# Tests all endpoints to ensure they work correctly after deployment

set -e

echo "🧪 API Integration Test Suite"
echo "============================="
echo ""

# Configuration
API_BASE_URL="${1:-http://localhost}"
TEST_EMAIL="test@xsigned.ai"
TEST_USERNAME="testuser"
TEST_CAMPAIGN="Test Campaign"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_test() {
    echo -e "${YELLOW}🧪 Testing: $1${NC}"
}

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_status="$3"
    
    print_test "$test_name"
    
    response=$(eval "$command" 2>/dev/null)
    status=$?
    
    if [ $status -eq $expected_status ]; then
        print_success "$test_name passed"
        echo "   Response: $response"
    else
        print_error "$test_name failed (exit code: $status, expected: $expected_status)"
        echo "   Response: $response"
    fi
    echo ""
}

# Wait for services to be ready
print_info "Waiting for services to be ready..."
sleep 10

# Test 1: Health Check
print_test "Health Check Endpoint"
if curl -sf "$API_BASE_URL/health" > /dev/null; then
    health_response=$(curl -s "$API_BASE_URL/health")
    print_success "Health check passed"
    echo "   Response: $health_response"
else
    print_error "Health check failed"
fi
echo ""

# Test 2: API Health Check
print_test "API Health Check"
if curl -sf "$API_BASE_URL/api/health" > /dev/null; then
    api_health_response=$(curl -s "$API_BASE_URL/api/health")
    print_success "API health check passed"
    echo "   Response: $api_health_response"
else
    print_error "API health check failed"
fi
echo ""

# Test 3: CORS Headers
print_test "CORS Headers"
cors_response=$(curl -sI -X OPTIONS "$API_BASE_URL/api/users" -H "Origin: https://xsigned.ai")
if echo "$cors_response" | grep -qi "Access-Control-Allow-Origin"; then
    print_success "CORS headers present"
else
    print_error "CORS headers missing"
fi
echo ""

# Test 4: Create User
print_test "Create User"
create_user_response=$(curl -s -X POST "$API_BASE_URL/api/users" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"username\":\"$TEST_USERNAME\"}")

if echo "$create_user_response" | grep -q "id"; then
    print_success "User creation passed"
    USER_ID=$(echo "$create_user_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo "   User ID: $USER_ID"
    echo "   Response: $create_user_response"
else
    print_error "User creation failed"
    echo "   Response: $create_user_response"
fi
echo ""

# Test 5: Get Users
print_test "Get All Users"
get_users_response=$(curl -s "$API_BASE_URL/api/users")
if echo "$get_users_response" | grep -q "$TEST_EMAIL"; then
    print_success "Get users passed"
    echo "   Found test user in response"
else
    print_error "Get users failed or test user not found"
    echo "   Response: $get_users_response"
fi
echo ""

# Test 6: Get Specific User
if [ -n "$USER_ID" ]; then
    print_test "Get Specific User"
    get_user_response=$(curl -s "$API_BASE_URL/api/users/$USER_ID")
    if echo "$get_user_response" | grep -q "$TEST_EMAIL"; then
        print_success "Get specific user passed"
        echo "   Response: $get_user_response"
    else
        print_error "Get specific user failed"
        echo "   Response: $get_user_response"
    fi
    echo ""
fi

# Test 7: Create Campaign
if [ -n "$USER_ID" ]; then
    print_test "Create Campaign"
    create_campaign_response=$(curl -s -X POST "$API_BASE_URL/api/campaigns" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\":$USER_ID,\"name\":\"$TEST_CAMPAIGN\",\"description\":\"Test campaign description\",\"target_audience\":\"Test audience\"}")
    
    if echo "$create_campaign_response" | grep -q "id"; then
        print_success "Campaign creation passed"
        CAMPAIGN_ID=$(echo "$create_campaign_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        echo "   Campaign ID: $CAMPAIGN_ID"
        echo "   Response: $create_campaign_response"
    else
        print_error "Campaign creation failed"
        echo "   Response: $create_campaign_response"
    fi
    echo ""
fi

# Test 8: Get Campaigns
print_test "Get All Campaigns"
get_campaigns_response=$(curl -s "$API_BASE_URL/api/campaigns")
if echo "$get_campaigns_response" | grep -q "$TEST_CAMPAIGN"; then
    print_success "Get campaigns passed"
    echo "   Found test campaign in response"
else
    print_error "Get campaigns failed or test campaign not found"
    echo "   Response: $get_campaigns_response"
fi
echo ""

# Test 9: Get User Campaigns
if [ -n "$USER_ID" ]; then
    print_test "Get User Campaigns"
    get_user_campaigns_response=$(curl -s "$API_BASE_URL/api/users/$USER_ID/campaigns")
    if echo "$get_user_campaigns_response" | grep -q "$TEST_CAMPAIGN"; then
        print_success "Get user campaigns passed"
        echo "   Response: $get_user_campaigns_response"
    else
        print_error "Get user campaigns failed"
        echo "   Response: $get_user_campaigns_response"
    fi
    echo ""
fi

# Test 10: Update Campaign
if [ -n "$CAMPAIGN_ID" ]; then
    print_test "Update Campaign"
    update_campaign_response=$(curl -s -X PUT "$API_BASE_URL/api/campaigns/$CAMPAIGN_ID" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Updated $TEST_CAMPAIGN\",\"description\":\"Updated description\"}")
    
    if echo "$update_campaign_response" | grep -q "Updated"; then
        print_success "Campaign update passed"
        echo "   Response: $update_campaign_response"
    else
        print_error "Campaign update failed"
        echo "   Response: $update_campaign_response"
    fi
    echo ""
fi

# Test 11: Error Handling - Invalid User
print_test "Error Handling - Invalid User"
invalid_user_response=$(curl -s "$API_BASE_URL/api/users/99999")
if echo "$invalid_user_response" | grep -q "error\|not found"; then
    print_success "Error handling for invalid user passed"
else
    print_error "Error handling for invalid user failed"
fi
echo ""

# Test 12: Error Handling - Invalid JSON
print_test "Error Handling - Invalid JSON"
invalid_json_response=$(curl -s -X POST "$API_BASE_URL/api/users" \
    -H "Content-Type: application/json" \
    -d "{invalid json}")
if echo "$invalid_json_response" | grep -q "error"; then
    print_success "Error handling for invalid JSON passed"
else
    print_error "Error handling for invalid JSON failed"
fi
echo ""

# Test 13: Rate Limiting (if enabled)
print_test "Rate Limiting Check"
rate_limit_status=0
for i in {1..15}; do
    curl -s "$API_BASE_URL/api/health" > /dev/null
    if [ $? -ne 0 ]; then
        rate_limit_status=1
        break
    fi
done

if [ $rate_limit_status -eq 1 ]; then
    print_success "Rate limiting appears to be working"
else
    print_info "Rate limiting not triggered (may not be configured)"
fi
echo ""

# Performance Test
print_test "Basic Performance Test"
start_time=$(date +%s%N)
for i in {1..5}; do
    curl -s "$API_BASE_URL/api/health" > /dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))

if [ $duration -lt 5000 ]; then
    print_success "Performance test passed (${duration}ms for 5 requests)"
else
    print_error "Performance test failed (${duration}ms for 5 requests - too slow)"
fi
echo ""

# Cleanup Test Data
if [ -n "$CAMPAIGN_ID" ]; then
    print_test "Cleanup - Delete Campaign"
    delete_campaign_response=$(curl -s -X DELETE "$API_BASE_URL/api/campaigns/$CAMPAIGN_ID")
    if [ $? -eq 0 ]; then
        print_success "Campaign deletion passed"
    else
        print_error "Campaign deletion failed"
    fi
    echo ""
fi

# Summary
echo "📊 Test Results Summary"
echo "======================="
echo ""
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! ($TESTS_PASSED/$TOTAL_TESTS)${NC}"
    echo ""
    echo "✅ Your API is working correctly!"
    echo "✅ All endpoints are responding"
    echo "✅ Error handling is working"
    echo "✅ Basic functionality verified"
elif [ $SUCCESS_RATE -ge 80 ]; then
    echo -e "${YELLOW}⚠️  Most tests passed ($TESTS_PASSED/$TOTAL_TESTS) - $SUCCESS_RATE% success rate${NC}"
    echo ""
    echo "✅ Core functionality is working"
    echo "⚠️  Some issues detected - check failed tests above"
else
    echo -e "${RED}❌ Many tests failed ($TESTS_FAILED/$TOTAL_TESTS failed) - $SUCCESS_RATE% success rate${NC}"
    echo ""
    echo "❌ Significant issues detected"
    echo "🔧 Review the failed tests and fix issues before production use"
fi

echo ""
echo "🔍 Additional Checks:"
echo "   • Monitor logs: ./check-logs.sh"
echo "   • System status: ./system-status.sh"
echo "   • View API docs at: $API_BASE_URL/api/"
echo ""

exit $TESTS_FAILED
