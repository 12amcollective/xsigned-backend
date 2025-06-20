# 🚀 Google Cloud Run Migration Guide

## Overview

This guide helps you migrate your XSigned backend from Raspberry Pi to Google Cloud Run for better reliability, scalability, and uptime.

## 🌟 Benefits of Cloud Run

- **99.95% uptime SLA** - No more Pi connectivity issues
- **Serverless scaling** - Automatically scales to zero when not used
- **Global availability** - Fast access worldwide
- **Built-in HTTPS** - Automatic SSL certificates
- **Cost-effective** - Pay only for actual usage
- **Easy deployment** - One command deployment

## 📋 Prerequisites

1. **Google Cloud Account** with billing enabled
2. **gcloud CLI** installed and authenticated
3. **Docker** (for local testing)
4. **Your existing codebase** ready to deploy

### Install gcloud CLI

```bash
# macOS
brew install google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

### Authenticate with Google Cloud

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

## 🚀 Quick Migration Steps

### 1. Deploy to Cloud Run

```bash
# Set your project ID
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_REGION="us-central1"

# Deploy with one command
./deploy-cloudrun.sh
```

### 2. Test the Deployment

```bash
# Test all endpoints
./test-cloudrun.sh
```

### 3. Update Your Domain DNS

In your Cloudflare DNS settings:

1. **Delete** any existing A records for `xsigned.ai`
2. **Add a CNAME record**:
   - **Name**: `@` (or `xsigned.ai`)
   - **Content**: `ghs.googlehosted.com`
   - **Proxy status**: Orange cloud (proxied)

### 4. Add Custom Domain in Google Cloud

```bash
# Add your custom domain to Cloud Run
gcloud run domain-mappings create \
    --service xsigned-backend \
    --domain xsigned.ai \
    --region us-central1
```

## 🗄️ Database Migration

Your data migration options:

### Option 1: Migrate from Pi PostgreSQL to Cloud SQL

```bash
# Export from Pi (if accessible)
pg_dump -h 192.168.86.70 -U postgres xsigned_db > backup.sql

# Import to Cloud SQL
gcloud sql import sql xsigned-db backup.sql --database=xsigned_db
```

### Option 2: Start Fresh (Recommended for Testing)

The deployment script creates a new Cloud SQL instance automatically. You can start with a clean database and test the waitlist functionality.

## 🔧 Configuration Files

### Dockerfile.cloudrun

- Optimized for Cloud Run environment
- Uses gunicorn for production serving
- Includes health checks

### deploy-cloudrun.sh

- One-command deployment script
- Sets up Cloud SQL database
- Configures secrets management
- Deploys the service

### test-cloudrun.sh

- Comprehensive testing script
- Tests all API endpoints
- Validates deployment health

## 🔐 Security Features

- **Secret management** via Google Secret Manager
- **IAM-based access control**
- **VPC networking** for database connections
- **Automatic security updates**

## 💰 Cost Estimation

**Cloud Run Pricing** (us-central1):

- First 2 million requests/month: **FREE**
- Additional requests: ~$0.40/million
- CPU time: $0.00002400/vCPU-second
- Memory: $0.00000250/GiB-second

**Cloud SQL Pricing**:

- db-f1-micro (0.6 GB RAM): ~$7/month
- 10 GB SSD storage: ~$1.70/month

**Estimated monthly cost**: ~$10-15/month for moderate usage

## 📊 Monitoring & Logs

### View Logs

```bash
# Real-time logs
gcloud run services logs tail xsigned-backend --region=us-central1

# Read recent logs
gcloud run services logs read xsigned-backend --region=us-central1
```

### Monitor Performance

```bash
# Service details
gcloud run services describe xsigned-backend --region=us-central1

# Traffic and metrics available in Google Cloud Console
```

## 🔄 Rollback Plan

If you need to rollback to Pi:

1. **Update DNS** back to Pi IP
2. **Stop Cloud Run service** (to avoid charges)
3. **Export data** from Cloud SQL if needed

```bash
# Stop the service
gcloud run services update xsigned-backend --region=us-central1 --min-instances=0

# Delete if needed
gcloud run services delete xsigned-backend --region=us-central1
```

## 🧹 **File Cleanup & Organization**

Since you now have both Pi deployment files and Cloud Run files, you may want to organize your workspace:

```bash
# Organize Pi files into archive folder
./cleanup-pi-files.sh
```

**Options:**

1. **Archive Pi files** - Move to `archive/pi-deployment/` folder
2. **Delete Pi files** - Remove Pi-specific files permanently
3. **Keep everything** - No changes (good for comparison)

**Recommended:** Archive Pi files so you can restore them if needed, but keep your workspace focused on Cloud Run deployment.

## 🎯 Production Checklist

- [ ] **Deploy to Cloud Run** (`./deploy-cloudrun.sh`)
- [ ] **Test all endpoints** (`./test-cloudrun.sh`)
- [ ] **Update DNS records** in Cloudflare
- [ ] **Add custom domain** to Cloud Run
- [ ] **Migrate data** (if needed)
- [ ] **Update frontend** to use new backend URL
- [ ] **Monitor logs** for any issues
- [ ] **Set up alerts** in Google Cloud Console

## 🆘 Troubleshooting

### Service won't start

```bash
# Check logs for errors
gcloud run services logs read xsigned-backend --region=us-central1 --limit=50
```

### Database connection issues

```bash
# Verify Cloud SQL instance
gcloud sql instances describe xsigned-db

# Check secrets
gcloud secrets versions access latest --secret="db-password"
```

### Custom domain not working

```bash
# Check domain mapping status
gcloud run domain-mappings describe xsigned.ai --region=us-central1
```

## 🎉 Success!

Once deployed successfully:

- ✅ **Backend**: `https://your-service-url.run.app`
- ✅ **Custom Domain**: `https://xsigned.ai`
- ✅ **Database**: Fully managed Cloud SQL
- ✅ **Monitoring**: Google Cloud Console
- ✅ **Scaling**: Automatic based on traffic

Your XSigned backend is now running on enterprise-grade infrastructure with 99.95% uptime guarantee!
