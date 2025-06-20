#!/bin/bash

# 🌐 Domain DNS Update Helper Script
# ==================================

echo "🌐 XSigned Domain DNS Configuration for Cloud Run"
echo "================================================="

# Get Cloud Run service URL
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-xsigned-production}"
REGION="${GOOGLE_CLOUD_REGION:-us-central1}"
SERVICE_NAME="xsigned-backend"

SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)' 2>/dev/null)

if [ -z "$SERVICE_URL" ]; then
    echo "❌ Cloud Run service not found. Deploy first with: ./deploy-cloudrun.sh"
    exit 1
fi

echo "✅ Cloud Run service found: $SERVICE_URL"
echo ""

echo "📋 DNS Configuration Steps:"
echo "=========================="
echo ""
echo "1. 🌐 Go to Cloudflare Dashboard: https://dash.cloudflare.com/"
echo "2. 🎯 Select your domain: xsigned.ai"
echo "3. 📋 Go to DNS tab"
echo "4. 🗑️  Delete any existing A records for xsigned.ai"
echo "5. ➕ Add a new CNAME record:"
echo ""
echo "   Record Type: CNAME"
echo "   Name: @ (or xsigned.ai)"
echo "   Content: ghs.googlehosted.com"
echo "   Proxy status: Orange cloud (proxied)"
echo "   TTL: Auto"
echo ""
echo "6. 💾 Save the record"
echo ""

echo "🔗 Add Custom Domain to Cloud Run:"
echo "=================================="
echo ""
echo "Run this command to map your domain:"
echo ""
echo "gcloud run domain-mappings create \\"
echo "    --service $SERVICE_NAME \\"
echo "    --domain xsigned.ai \\"
echo "    --region $REGION"
echo ""

echo "📊 Verify Domain Mapping:"
echo "========================"
echo ""
echo "gcloud run domain-mappings describe xsigned.ai --region=$REGION"
echo ""

echo "🧪 Test Your Domain:"
echo "==================="
echo ""
echo "After DNS propagation (5-10 minutes), test:"
echo "curl https://xsigned.ai/health"
echo ""

echo "💡 Troubleshooting:"
echo "=================="
echo ""
echo "• DNS not resolving? Wait 5-10 minutes for propagation"
echo "• SSL certificate pending? Google automatically provisions it"
echo "• 502 errors? Check Cloud Run logs: gcloud run services logs read $SERVICE_NAME --region=$REGION"
echo ""

echo "🎉 Once complete, your backend will be available at:"
echo "   https://xsigned.ai"
echo "   (instead of the unreliable Pi setup)"
