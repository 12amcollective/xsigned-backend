#!/bin/bash

# 🚀 Google Cloud Run Deployment Script for XSigned Backend
# =========================================================

set -e  # Exit on any error

echo "🚀 Deploying XSigned to Google Cloud Run"
echo "========================================"

# Configuration - Update these values
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-xsignedai}"
REGION="${GOOGLE_CLOUD_REGION:-us-central1}"
SERVICE_NAME="xsigned-backend"
DATABASE_NAME="xsigned-db"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}📋 $1${NC}"
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

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first:"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "Not authenticated with gcloud. Please run: gcloud auth login"
    exit 1
fi

# Set the project
print_status "Setting Google Cloud project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Enable required APIs
print_status "Enabling required Google Cloud APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sql-component.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable secretmanager.googleapis.com

print_success "APIs enabled successfully"

# Create secrets for environment variables
print_status "Creating secrets for environment variables..."

# Generate secure secrets if they don't exist
if [ ! -f .env.cloudrun ]; then
    print_status "Generating secure environment variables..."
    
    DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
    JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    FLASK_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(16))")
    
    cat > .env.cloudrun << EOF
# Google Cloud Run Environment Variables
DB_HOST=/cloudsql/$PROJECT_ID:$REGION:$DATABASE_NAME
DB_USER=postgres
DB_PASSWORD=$DB_PASSWORD
DB_NAME=xsigned_db
JWT_SECRET_KEY=$JWT_SECRET
FLASK_SECRET_KEY=$FLASK_SECRET
FLASK_ENV=production
FLASK_DEBUG=false
CORS_ORIGINS=https://xsigned.ai,https://www.xsigned.ai
EOF
    
    print_success "Environment file created: .env.cloudrun"
fi

# Create secrets in Secret Manager
print_status "Creating/updating secrets in Google Secret Manager..."

# Function to create or update secret
create_or_update_secret() {
    local secret_name=$1
    local secret_value=$2
    
    if gcloud secrets describe "$secret_name" --quiet 2>/dev/null; then
        print_status "Updating existing secret: $secret_name"
        echo "$secret_value" | gcloud secrets versions add "$secret_name" --data-file=-
    else
        print_status "Creating new secret: $secret_name"
        echo "$secret_value" | gcloud secrets create "$secret_name" --data-file=- --replication-policy="automatic"
    fi
}

create_or_update_secret "db-password" "$DB_PASSWORD"
create_or_update_secret "jwt-secret" "$JWT_SECRET"
create_or_update_secret "flask-secret" "$FLASK_SECRET"

print_success "Secrets created in Secret Manager"

# Grant Secret Manager access to the default Compute Engine service account
print_status "Setting up IAM permissions for Secret Manager..."

# Get the project number (required for service account email)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
COMPUTE_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

print_status "Project Number: $PROJECT_NUMBER"
print_status "Granting Secret Manager access to service account: $COMPUTE_SA"

# Grant Secret Manager Secret Accessor role to the service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$COMPUTE_SA" \
    --role="roles/secretmanager.secretAccessor"

print_success "IAM permissions configured"

# Build the container
print_status "Building container image..."

# Create a temporary cloudbuild.yaml for custom dockerfile
cat > cloudbuild.yaml << EOF
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-f', 'Dockerfile.cloudrun', '-t', 'gcr.io/$PROJECT_ID/$SERVICE_NAME', '.']
images:
- 'gcr.io/$PROJECT_ID/$SERVICE_NAME'
EOF

gcloud builds submit --config=cloudbuild.yaml .

# Clean up temporary file
rm cloudbuild.yaml

print_success "Container built and pushed to Google Container Registry"

# Create Cloud SQL instance (if it doesn't exist)
print_status "Setting up Cloud SQL database..."

if ! gcloud sql instances describe $DATABASE_NAME --quiet 2>/dev/null; then
    print_status "Creating Cloud SQL PostgreSQL instance..."
    gcloud sql instances create $DATABASE_NAME \
        --database-version=POSTGRES_14 \
        --tier=db-f1-micro \
        --region=$REGION \
        --root-password="$DB_PASSWORD" \
        --storage-type=SSD \
        --storage-size=10GB \
        --storage-auto-increase
    
    print_success "Cloud SQL instance created"
else
    print_success "Cloud SQL instance already exists"
fi

# Create the database
print_status "Creating application database..."
gcloud sql databases create xsigned_db --instance=$DATABASE_NAME || true

print_success "Database setup complete"

# Deploy to Cloud Run
print_status "Deploying to Cloud Run..."

gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --timeout 300 \
    --concurrency 80 \
    --add-cloudsql-instances $PROJECT_ID:$REGION:$DATABASE_NAME \
    --set-env-vars "DB_HOST=/cloudsql/$PROJECT_ID:$REGION:$DATABASE_NAME,DB_USER=postgres,DB_NAME=xsigned_db,FLASK_ENV=production,FLASK_DEBUG=false,CORS_ORIGINS=https://xsigned.ai;https://www.xsigned.ai" \
    --set-secrets "DB_PASSWORD=db-password:latest,JWT_SECRET_KEY=jwt-secret:latest,FLASK_SECRET_KEY=flask-secret:latest"

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)')

print_success "Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "======================"
echo "🌐 Service URL: $SERVICE_URL"
echo "🗄️  Database: $PROJECT_ID:$REGION:$DATABASE_NAME"
echo "📍 Region: $REGION"
echo ""
echo "🔗 Next Steps:"
echo "1. Test your deployment: curl $SERVICE_URL/health"
echo "2. Update your domain DNS to point to Cloud Run:"
echo "   - In Cloudflare DNS, create a CNAME record:"
echo "   - Name: @ (or xsigned.ai)"
echo "   - Content: ghs.googlehosted.com"
echo "3. Add your custom domain in Cloud Run console"
echo ""
echo "💡 Monitor your service:"
echo "   gcloud run services logs read $SERVICE_NAME --region=$REGION"
echo ""
print_success "🎉 XSigned backend is now running on Google Cloud Run!"
