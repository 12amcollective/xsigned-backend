#!/bin/bash

# 🧹 Cloud Run Cleanup Script
# ===========================

set -e

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-xsigned-production}"
REGION="${GOOGLE_CLOUD_REGION:-us-central1}"
SERVICE_NAME="xsigned-backend"
DATABASE_NAME="xsigned-db"

echo "🧹 Cleaning up Cloud Run resources"
echo "=================================="
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Ask for confirmation
read -p "⚠️  This will delete your Cloud Run service and database. Are you sure? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo "🗑️  Starting cleanup..."

# Delete Cloud Run service
echo "Deleting Cloud Run service..."
gcloud run services delete $SERVICE_NAME --region=$REGION --quiet || true

# Delete container images
echo "Deleting container images..."
gcloud container images delete gcr.io/$PROJECT_ID/$SERVICE_NAME --quiet || true

# Delete Cloud SQL instance
echo "Deleting Cloud SQL instance..."
gcloud sql instances delete $DATABASE_NAME --quiet || true

# Delete secrets
echo "Deleting secrets..."
gcloud secrets delete db-password --quiet || true
gcloud secrets delete jwt-secret --quiet || true
gcloud secrets delete flask-secret --quiet || true

# Clean up local files
echo "Cleaning up local files..."
rm -f .env.cloudrun

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💡 You can now:"
echo "1. Redeploy with: ./deploy-cloudrun.sh"
echo "2. Or switch back to Pi deployment"
