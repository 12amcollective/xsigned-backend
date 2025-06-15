#!/bin/bash

# Complete Production Deployment Workflow
# This script guides you through the entire production deployment process

set -e

echo "🚀 XSigned Backend - Production Deployment Workflow"
echo "=================================================="

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

print_step() {
    echo -e "${BLUE}🔄 STEP: $1${NC}"
}

# Configuration
PI_HOST="192.168.86.70"
PI_USER="colin"
DOMAIN="xsigned.ai"

echo ""
print_info "This script will guide you through deploying to production on $DOMAIN"
echo ""

# Step 1: Pre-deployment checks
print_step "Pre-deployment Validation"
echo "Running validation checks..."

if ./validate-production.sh; then
    print_success "All validation checks passed!"
else
    print_error "Validation failed. Please fix issues before continuing."
    exit 1
fi

echo ""

# Step 2: Generate secrets if needed
print_step "Security Configuration"
echo ""

if ! grep -q "^DB_PASSWORD=" .env || grep -q "your_secure_database_password_here" .env; then
    print_warning "Secure keys need to be generated"
    echo ""
    read -p "Generate new secure keys? (y/n): " generate_keys
    if [[ $generate_keys =~ ^[Yy]$ ]]; then
        ./generate-secrets.sh
        echo ""
        print_warning "Please update your .env file with the generated keys above, then re-run this script."
        exit 0
    fi
else
    print_success "Environment variables are configured"
fi

echo ""

# Step 3: Domain verification
print_step "Domain Configuration Check"
echo ""

print_info "Checking if domain points to your Pi..."
domain_ip=$(dig +short $DOMAIN | head -n1)
pi_ip=$(curl -s ipinfo.io/ip || echo "unknown")

echo "Domain $DOMAIN resolves to: $domain_ip"
echo "Your Pi's public IP: $pi_ip"

if [ "$domain_ip" != "$pi_ip" ]; then
    print_warning "Domain may not point to your Pi yet"
    echo ""
    read -p "Continue anyway? (y/n): " continue_deploy
    if [[ ! $continue_deploy =~ ^[Yy]$ ]]; then
        echo "Please configure your domain DNS to point to $pi_ip and try again."
        exit 0
    fi
else
    print_success "Domain correctly points to your Pi"
fi

echo ""

# Step 4: Copy files to Pi
print_step "Copying Files to Pi"
echo ""

print_info "Copying backend files to Pi..."

# Create the directory structure on Pi if needed
ssh $PI_USER@$PI_HOST "mkdir -p /home/$PI_USER/xsigned-backend"

# Copy all necessary files
rsync -av --exclude='__pycache__' --exclude='.git' --exclude='node_modules' \
    --exclude='logs/*' --exclude='.env.dev' \
    ./ $PI_USER@$PI_HOST:/home/$PI_USER/xsigned-backend/

print_success "Files copied to Pi"

echo ""

# Step 5: Deploy on Pi
print_step "Production Deployment"
echo ""

print_info "Starting production deployment on Pi..."

ssh $PI_USER@$PI_HOST << 'EOF'
cd /home/colin/xsigned-backend

echo "🏗️  Starting production deployment..."

# Stop any development services
if docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
    echo "Stopping development services..."
    docker-compose -f docker-compose.dev.yml down
fi

# Make scripts executable
chmod +x *.sh

# Run production deployment
if ./deploy-production.sh; then
    echo "✅ Production deployment completed!"
else
    echo "❌ Production deployment failed!"
    exit 1
fi
EOF

if [ $? -eq 0 ]; then
    print_success "Production deployment completed on Pi!"
else
    print_error "Production deployment failed on Pi"
    exit 1
fi

echo ""

# Step 6: Wait for services to start
print_step "Service Startup"
echo ""

print_info "Waiting for services to be ready..."
sleep 60

echo ""

# Step 7: Test deployment
print_step "Production Testing"
echo ""

print_info "Running production tests..."

if ./test-production.sh; then
    print_success "All production tests passed! 🎉"
else
    print_warning "Some tests failed. Check the output above."
fi

echo ""

# Step 8: Final summary
print_step "Deployment Complete!"
echo ""

print_success "🎉 Production deployment workflow completed!"
echo ""
echo "📊 Deployment Summary:"
echo "======================"
echo "  • Domain: https://$DOMAIN"
echo "  • API: https://$DOMAIN/api/"
echo "  • Waitlist: https://$DOMAIN/api/waitlist/join"
echo "  • Status: Running on Pi ($PI_HOST)"
echo ""
echo "🔧 Management Commands:"
echo "  • SSH to Pi: ssh $PI_USER@$PI_HOST"
echo "  • View logs: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && docker-compose -f docker-compose.production.yml logs -f'"
echo "  • Restart: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && docker-compose -f docker-compose.production.yml restart'"
echo "  • Stop: ssh $PI_USER@$PI_HOST 'cd /home/$PI_USER/xsigned-backend && docker-compose -f docker-compose.production.yml down'"
echo ""
echo "📝 Next Steps:"
echo "  1. Update your frontend to use: https://$DOMAIN/api/"
echo "  2. Test the complete user flow"
echo "  3. Set up monitoring and backups"
echo "  4. Configure any additional domains/subdomains"
echo ""
echo "🔍 Quick Health Check:"
echo "  curl https://$DOMAIN/health"
echo "  curl https://$DOMAIN/api/waitlist/stats"
echo ""

print_success "Your XSigned backend is now live in production! 🚀"
