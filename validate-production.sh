#!/bin/bash

# Pre-deployment validation script
# Checks if everything is ready for production deployment

set -e

echo "🔍 Pre-Deployment Validation..."
echo "==============================="

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

ERRORS=0

# Check environment file
print_info "Checking environment configuration..."

if [ ! -f ".env" ]; then
    print_error ".env file not found"
    echo "  Run: cp .env.production .env"
    ERRORS=$((ERRORS + 1))
else
    print_success ".env file exists"
    
    # Check for placeholder values
    if grep -q "your_secure_database_password_here" .env; then
        print_error "Database password not set in .env"
        echo "  Run: ./generate-secrets.sh"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "your_generated_flask_secret_key_here" .env; then
        print_error "Flask secret key not set in .env"
        echo "  Run: ./generate-secrets.sh"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "your-super-secret-jwt-key-change-this" .env; then
        print_error "JWT secret key not set in .env"
        echo "  Run: ./generate-secrets.sh"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ $ERRORS -eq 0 ]; then
        print_success "Environment variables configured"
    fi
fi

# Check Docker
print_info "Checking Docker installation..."

if ! command -v docker &> /dev/null; then
    print_error "Docker not installed"
    ERRORS=$((ERRORS + 1))
else
    print_success "Docker installed"
fi

if ! docker compose version &> /dev/null; then
    print_error "Docker Compose not available"
    ERRORS=$((ERRORS + 1))
else
    print_success "Docker Compose available"
fi

# Check required files
print_info "Checking required files..."

required_files=(
    "docker-compose.production.yml"
    "nginx-production.conf"
    "Dockerfile"
    "src/app.py"
    "src/routes/waitlist.py"
    "src/services/waitlist_service.py"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check directories
print_info "Checking required directories..."

required_dirs=(
    "src"
    "src/models"
    "src/routes" 
    "src/services"
    "logs"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_success "$dir directory exists"
    else
        print_error "$dir directory missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check Python syntax
print_info "Checking Python syntax..."

python_files=(
    "src/app.py"
    "src/routes/waitlist.py"
    "src/services/waitlist_service.py"
    "src/models/waitlist.py"
)

for file in "${python_files[@]}"; do
    if python3 -m py_compile "$file" 2>/dev/null; then
        print_success "$file syntax OK"
    else
        print_error "$file has syntax errors"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check development tests passed
print_info "Checking development status..."

if [ -f "test-waitlist.sh" ]; then
    print_success "Waitlist test script available"
else
    print_warning "Waitlist test script missing"
fi

# Summary
echo ""
echo "📊 Validation Summary:"
echo "====================="

if [ $ERRORS -eq 0 ]; then
    print_success "All checks passed! Ready for production deployment 🚀"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Ensure domain DNS points to your Pi"
    echo "  2. Run: ./deploy-production.sh"
    echo "  3. After deployment: ./test-production.sh"
    echo ""
    exit 0
else
    print_error "$ERRORS error(s) found. Please fix before deploying."
    echo ""
    echo "🔧 Common fixes:"
    echo "  • Generate secrets: ./generate-secrets.sh"
    echo "  • Copy environment: cp .env.production .env"
    echo "  • Check file permissions"
    echo ""
    exit 1
fi
