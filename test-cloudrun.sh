#!/bin/bash

# 🧪 Google Cloud Run Testing Script
# ==================================

# Configuration
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-xsigned-production}"
REGION="${GOOGLE_CLOUD_REGION:-us-central1}"
SERVICE_NAME="xsigned-backend"

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)' 2>/dev/null)

if [ -z "$SERVICE_URL" ]; then
    echo "❌ Could not find Cloud Run service. Make sure it's deployed first."
    exit 1
fi

echo "🧪 Testing XSigned Cloud Run Deployment"
echo "======================================="
echo "🌐 Service URL: $SERVICE_URL"
echo ""

# Test health endpoint
echo "🔗 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$SERVICE_URL/health")
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$HEALTH_CODE" = "200" ]; then
    echo "✅ Health check passed"
    echo "Response: $(echo "$HEALTH_RESPONSE" | head -n -1)"
else
    echo "❌ Health check failed (HTTP $HEALTH_CODE)"
    echo "Response: $HEALTH_RESPONSE"
fi

echo ""

# Test waitlist endpoint
echo "📋 Testing waitlist signup..."
WAITLIST_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST "$SERVICE_URL/api/waitlist/join" \
    -H "Content-Type: application/json" \
    -d '{"email": "test@cloudrun.com", "name": "Cloud Run Test"}')

WAITLIST_CODE=$(echo "$WAITLIST_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$WAITLIST_CODE" = "201" ] || [ "$WAITLIST_CODE" = "200" ]; then
    echo "✅ Waitlist signup successful"
    echo "Response: $(echo "$WAITLIST_RESPONSE" | head -n -1)"
else
    echo "❌ Waitlist signup failed (HTTP $WAITLIST_CODE)"
    echo "Response: $WAITLIST_RESPONSE"
fi

echo ""

# Test waitlist stats
echo "📊 Testing waitlist stats..."
STATS_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$SERVICE_URL/api/waitlist/stats")
STATS_CODE=$(echo "$STATS_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$STATS_CODE" = "200" ]; then
    echo "✅ Waitlist stats retrieved"
    echo "Response: $(echo "$STATS_RESPONSE" | head -n -1)"
else
    echo "❌ Waitlist stats failed (HTTP $STATS_CODE)"
    echo "Response: $STATS_RESPONSE"
fi

echo ""

# Test users endpoint
echo "👥 Testing users endpoint..."
USERS_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$SERVICE_URL/api/users/")
USERS_CODE=$(echo "$USERS_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$USERS_CODE" = "200" ]; then
    echo "✅ Users endpoint accessible"
    echo "Response: $(echo "$USERS_RESPONSE" | head -n -1)"
else
    echo "❌ Users endpoint failed (HTTP $USERS_CODE)"
    echo "Response: $USERS_RESPONSE"
fi

echo ""

# Test campaigns endpoint
echo "📢 Testing campaigns endpoint..."
CAMPAIGNS_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$SERVICE_URL/api/campaigns/")
CAMPAIGNS_CODE=$(echo "$CAMPAIGNS_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$CAMPAIGNS_CODE" = "200" ]; then
    echo "✅ Campaigns endpoint accessible"
    echo "Response: $(echo "$CAMPAIGNS_RESPONSE" | head -n -1)"
else
    echo "❌ Campaigns endpoint failed (HTTP $CAMPAIGNS_CODE)"
    echo "Response: $CAMPAIGNS_RESPONSE"
fi

echo ""
echo "🏁 Cloud Run Testing Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. If all tests pass, your backend is ready for production!"
echo "2. Update your domain DNS to point to Cloud Run"
echo "3. Deploy your frontend to point to this backend URL"
echo ""
echo "🔍 Monitor logs: gcloud run services logs read $SERVICE_NAME --region=$REGION"
echo "📊 View metrics: gcloud run services describe $SERVICE_NAME --region=$REGION"
