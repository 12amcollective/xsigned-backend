#!/bin/bash

# Development Setup Script for Raspberry Pi
# This script sets up the development environment with hot reloading

set -e

echo "🚀 Setting up Development Environment on Raspberry Pi..."
echo "======================================================="

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

# Check if we're on the Pi
if [[ $(uname -m) != "aarch64" && $(uname -m) != "armv7l" ]]; then
    print_warning "This script is designed for Raspberry Pi. Current architecture: $(uname -m)"
fi

# Check required repositories
print_info "Checking repository structure..."

BACKEND_DIR="/home/$USER/xsigned-backend"
FRONTEND_DIR="/home/$USER/xsigned"

if [ ! -d "$BACKEND_DIR" ]; then
    print_error "Backend repository not found at $BACKEND_DIR"
    echo "Please clone the backend repository first:"
    echo "git clone <your-backend-repo> $BACKEND_DIR"
    exit 1
fi

print_success "Backend repository verified"

# Frontend is optional for development - you can run it locally
if [ ! -d "$FRONTEND_DIR" ]; then
    print_warning "Frontend repository not found at $FRONTEND_DIR"
    print_info "For development, you can run the frontend locally with 'npm run dev'"
    print_info "The backend will be accessible at http://192.168.86.70:5001"
    print_info "Configure your local frontend to use VITE_API_URL=http://192.168.86.70:5001/api"
else
    print_success "Frontend repository found (optional for development)"
fi

# Check Docker
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_warning "Please log out and back in for Docker group changes to take effect"
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Installing..."
    sudo apt update
    sudo apt install -y docker-compose
fi

print_success "Docker is ready"

# Setup environment for development
print_info "Setting up development environment..."

cd "$BACKEND_DIR"

# Create development .env if it doesn't exist
if [ ! -f ".env.dev" ]; then
    print_info "Creating development environment file..."
    cat > .env.dev << EOF
# Development Environment Configuration
DB_PASSWORD=dev_password_123
FLASK_ENV=development
FLASK_DEBUG=true
FLASK_SECRET_KEY=dev_secret_key_for_development_only
LOG_LEVEL=DEBUG

# Development API URLs
API_URL=http://192.168.86.70/api
DOMAIN=192.168.86.70

# Frontend environment variables
VITE_API_URL=http://192.168.86.70:8080/api
VITE_ENV=development
VITE_APP_NAME="XSigned - Music Campaign Manager (Dev)"
EOF
    print_success "Development environment file created"
else
    print_success "Development environment file already exists"
fi

# Frontend setup is not needed on Pi - run locally instead
print_info "Frontend setup: Run locally on your development machine"
print_info "For your local frontend, use these environment variables:"
echo "  VITE_API_URL=http://192.168.86.70:8080/api"
echo "  VITE_ENV=development"
echo ""
print_info "Your Vite proxy should target: http://192.168.86.70:8080/api"

# Return to backend directory
cd "$BACKEND_DIR"

# Create necessary directories
print_info "Creating log directories..."
mkdir -p logs/nginx

# Build and start development services
print_info "Building and starting development services..."

# Stop any running services first
docker-compose -f docker-compose.dev.yml down 2>/dev/null || true

# Start development services
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d

print_info "Waiting for services to be ready..."
sleep 30

# Check service health
print_info "Checking service health..."

check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        echo "Waiting for $service_name... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    print_error "$service_name failed to start"
    return 1
}

# Check database
if docker-compose -f docker-compose.dev.yml exec -T postgres pg_isready -U backend_user > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_error "Database is not ready"
fi

# Check backend
check_service "Backend API" "http://localhost:5001/health"

# Check nginx proxy
check_service "Nginx Proxy" "http://localhost:8080/health"

print_success "Development environment is ready!"
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.dev.yml ps
echo ""
echo "🌐 Access URLs:"
echo "  • API via Nginx: http://192.168.86.70:8080/api/"
echo "  • API Direct: http://192.168.86.70:5001/api/"
echo "  • Health Check: http://192.168.86.70:8080/health"
echo "  • Database: localhost:5432 (from Pi)"
echo ""
echo "🛠️ Development Commands:"
echo "  • View all logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "  • View nginx logs: docker-compose -f docker-compose.dev.yml logs -f nginx"
echo "  • View backend logs: docker-compose -f docker-compose.dev.yml logs -f backend"
echo "  • Restart services: docker-compose -f docker-compose.dev.yml restart"
echo "  • Stop services: docker-compose -f docker-compose.dev.yml down"
echo "  • Database shell: docker-compose -f docker-compose.dev.yml exec postgres psql -U backend_user -d music_campaigns"
echo ""
echo "📝 Development Workflow:"
echo "  1. Run frontend locally: npm run dev (on your development machine)"
echo "  2. Your frontend Vite proxy should now work with http://192.168.86.70:8080/api"
echo "  3. Backend + Nginx running on Pi at http://192.168.86.70:8080"
echo "  4. Test API: curl http://192.168.86.70:8080/api/users"
echo "  5. Check logs if anything isn't working"
echo ""
print_success "Development setup completed! 🎉"
