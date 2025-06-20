#!/bin/bash

echo "🧪 Testing Live XSigned.ai Deployment"
echo "======================================="

# Test basic connectivity
echo -e "\n🔗 Testing HTTPS connectivity..."
curl -k -s -o /dev/null -w "HTTP Status: %{http_code}\nConnect Time: %{time_connect}s\nTotal Time: %{time_total}s\n" https://xsigned.ai/health

echo -e "\n📋 Testing Waitlist API..."
curl -k -X POST https://xsigned.ai/api/waitlist/join \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "name": "Test User"}' \
  -w "\nHTTP Status: %{http_code}\n"

echo -e "\n📊 Testing Waitlist Stats..."
curl -k -s https://xsigned.ai/api/waitlist/stats -w "\nHTTP Status: %{http_code}\n"

echo -e "\n🌐 Testing Frontend..."
curl -k -s -o /dev/null -w "Frontend HTTP Status: %{http_code}\n" https://xsigned.ai/

echo -e "\n✅ Live site testing complete!"
