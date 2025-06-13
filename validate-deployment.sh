#!/bin/bash

# Pre-deployment validation script for Music Campaign Backend
# Run this before deploying to catch configuration issues early

set -e

echo "🔍 Pre-Deployment Validation for Music Campaign Backend"
echo "========================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VALIDATION_PASSED=true

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    VALIDATION_PASSED=false
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check 1: Required files exist
echo "📁 Checking required files..."

required_files=(
    "docker-compose.production.yml"
    "Dockerfile"
    "nginx-cloudflare.conf"
    "requirements.txt"
    "src/app.py"
    "init-db.sql"
    ".env.example"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file is missing"
    fi
done
echo ""

# Check 2: Environment configuration
echo "🔧 Checking environment configuration..."

if [ -f ".env" ]; then
    print_success ".env file exists"
    
    # Check required environment variables
    source .env
    
    required_vars=("DB_PASSWORD" "CLOUDFLARE_TUNNEL_TOKEN" "FLASK_SECRET_KEY")
    for var in "${required_vars[@]}"; do
        if [ -n "${!var}" ] && [ "${!var}" != "your_${var,,}_here" ]; then
            print_success "$var is configured"
        else
            print_error "$var is not properly configured in .env"
        fi
    done
    
    # Validate password strength
    if [ ${#DB_PASSWORD} -lt 12 ]; then
        print_warning "DB_PASSWORD should be at least 12 characters long"
    fi
    
    # Check if secret key is strong enough
    if [ ${#FLASK_SECRET_KEY} -lt 32 ]; then
        print_warning "FLASK_SECRET_KEY should be at least 32 characters long"
    fi
    
else
    print_error ".env file does not exist. Copy from .env.example and configure it."
fi
echo ""

# Check 3: Docker and Docker Compose
echo "🐳 Checking Docker setup..."

if command -v docker &> /dev/null; then
    print_success "Docker is installed"
    docker --version
    
    # Check if Docker daemon is running
    if docker ps &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
    fi
else
    print_error "Docker is not installed"
fi

if command -v docker-compose &> /dev/null; then
    print_success "Docker Compose is installed"
    docker-compose --version
else
    print_error "Docker Compose is not installed"
fi
echo ""

# Check 4: Network connectivity
echo "🌐 Checking network connectivity..."

if ping -c 1 google.com &> /dev/null; then
    print_success "Internet connectivity is working"
else
    print_error "No internet connectivity"
fi

if ping -c 1 docker.io &> /dev/null; then
    print_success "Can reach Docker Hub"
else
    print_warning "Cannot reach Docker Hub - may affect image pulls"
fi

if ping -c 1 cloudflare.com &> /dev/null; then
    print_success "Can reach Cloudflare"
else
    print_warning "Cannot reach Cloudflare - tunnel may not work"
fi
echo ""

# Check 5: System resources
echo "💻 Checking system resources..."

# Check available memory (should have at least 1GB free)
FREE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}' 2>/dev/null || echo "0")
if [ "$FREE_MEM" -gt 1000 ]; then
    print_success "Sufficient free memory: ${FREE_MEM}MB"
elif [ "$FREE_MEM" -gt 500 ]; then
    print_warning "Low free memory: ${FREE_MEM}MB (recommended: >1GB)"
else
    print_error "Very low free memory: ${FREE_MEM}MB (minimum: 500MB)"
fi

# Check available disk space (should have at least 2GB free)
FREE_DISK=$(df -BG . | awk 'NR==2{printf "%.0f", $4}' | tr -d 'G' 2>/dev/null || echo "0")
if [ "$FREE_DISK" -gt 2 ]; then
    print_success "Sufficient free disk space: ${FREE_DISK}GB"
elif [ "$FREE_DISK" -gt 1 ]; then
    print_warning "Low free disk space: ${FREE_DISK}GB (recommended: >2GB)"
else
    print_error "Very low free disk space: ${FREE_DISK}GB (minimum: 1GB)"
fi
echo ""

# Check 6: Port availability
echo "🔌 Checking port availability..."

check_port() {
    local port=$1
    local service=$2
    
    if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_success "Port $port is available for $service"
    else
        print_warning "Port $port is already in use (needed for $service)"
    fi
}

check_port 80 "Nginx"
check_port 5432 "PostgreSQL"
check_port 5001 "Flask Backend"
check_port 3000 "React Frontend"
echo ""

# Check 7: Python requirements validation
echo "🐍 Validating Python requirements..."

if [ -f "requirements.txt" ]; then
    print_success "requirements.txt found"
    
    # Check for common issues
    if grep -q "psycopg2-binary" requirements.txt; then
        print_success "PostgreSQL adapter is included"
    else
        print_warning "psycopg2-binary not found in requirements.txt"
    fi
    
    if grep -q "flask" requirements.txt; then
        print_success "Flask is included"
    else
        print_error "Flask not found in requirements.txt"
    fi
    
    if grep -q "sqlalchemy" requirements.txt; then
        print_success "SQLAlchemy is included"
    else
        print_error "SQLAlchemy not found in requirements.txt"
    fi
else
    print_error "requirements.txt not found"
fi
echo ""

# Check 8: Docker Compose file validation
echo "🔍 Validating Docker Compose configuration..."

if docker-compose -f docker-compose.production.yml config &> /dev/null; then
    print_success "Docker Compose configuration is valid"
else
    print_error "Docker Compose configuration has errors"
    echo "Run: docker-compose -f docker-compose.production.yml config"
fi
echo ""

# Check 9: Nginx configuration validation
echo "🌐 Validating Nginx configuration..."

if [ -f "nginx-cloudflare.conf" ]; then
    # Basic syntax check using nginx container
    if docker run --rm -v "$(pwd)/nginx-cloudflare.conf:/etc/nginx/nginx.conf:ro" nginx:alpine nginx -t &> /dev/null; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration has syntax errors"
    fi
else
    print_error "nginx-cloudflare.conf not found"
fi
echo ""

# Check 10: SSL/TLS requirements for production
echo "🔒 Checking security configuration..."

if [ -f ".env" ] && source .env; then
    if [ "$FLASK_ENV" = "production" ]; then
        print_success "Flask environment set to production"
        
        if [ "$FLASK_DEBUG" = "false" ]; then
            print_success "Flask debug mode disabled"
        else
            print_warning "Flask debug mode should be disabled in production"
        fi
    else
        print_warning "Flask environment not set to production"
    fi
fi
echo ""

# Summary
echo "📊 Validation Summary"
echo "===================="

if [ "$VALIDATION_PASSED" = true ]; then
    print_success "All validations passed! ✨"
    echo ""
    echo "🚀 Ready to deploy! Run:"
    echo "   ./deploy-to-pi.sh"
    echo ""
else
    print_error "Some validations failed. Please fix the issues above before deploying."
    echo ""
    echo "🔧 Common fixes:"
    echo "   • Copy .env.example to .env and configure it"
    echo "   • Generate strong passwords and secrets"
    echo "   • Install Docker and Docker Compose"
    echo "   • Free up system resources"
    echo "   • Check file permissions"
    echo ""
    exit 1
fi

echo "📋 Next Steps After Deployment:"
echo "   1. Run ./system-status.sh to check system health"
echo "   2. Test your API at https://xsigned.ai/api/health"
echo "   3. Monitor logs with ./check-logs.sh"
echo "   4. Set up regular backups if not automated"
echo ""
echo "📚 Documentation: ./DEPLOYMENT.md"
