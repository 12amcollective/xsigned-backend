#!/bin/bash

# Music Campaign Backend - Task Runner
# Provides convenient commands for common operations

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Function to show usage
show_usage() {
    echo "🎵 Music Campaign Backend - Task Runner"
    echo "======================================="
    echo ""
    echo "Usage: ./run.sh <command>"
    echo ""
    echo "Available commands:"
    echo ""
    echo "🚀 Deployment:"
    echo "  validate      - Validate deployment configuration"
    echo "  deploy        - Deploy to Raspberry Pi (full deployment)"
    echo "  setup-tunnel  - Set up Cloudflare Tunnel"
    echo ""
    echo "📊 Monitoring:"
    echo "  status        - Check system status"
    echo "  logs          - View recent logs"
    echo "  test          - Run API integration tests"
    echo "  health        - Quick health check"
    echo ""
    echo "🔧 Service Management:"
    echo "  start         - Start all services"
    echo "  stop          - Stop all services"
    echo "  restart       - Restart all services"
    echo "  rebuild       - Rebuild and restart services"
    echo ""
    echo "🗄️  Database:"
    echo "  backup        - Create database backup"
    echo "  db-shell      - Connect to database shell"
    echo "  db-reset      - Reset database (⚠️  destructive)"
    echo ""
    echo "🧹 Maintenance:"
    echo "  clean         - Clean up Docker resources"
    echo "  update        - Update and restart services"
    echo "  env-setup     - Set up environment file"
    echo ""
    echo "Examples:"
    echo "  ./run.sh validate    # Check if ready to deploy"
    echo "  ./run.sh deploy      # Full deployment to Pi"
    echo "  ./run.sh status      # Check system health"
    echo "  ./run.sh test        # Test all API endpoints"
}

# Function implementations
case "${1:-help}" in
    "validate")
        print_header "🔍 Validating deployment configuration..."
        ./validate-deployment.sh
        ;;
    
    "deploy")
        print_header "🚀 Starting full deployment..."
        ./validate-deployment.sh
        ./deploy-to-pi.sh
        print_success "Deployment completed!"
        ;;
    
    "setup-tunnel")
        print_header "🌐 Setting up Cloudflare Tunnel..."
        ./setup-cloudflare-tunnel.sh
        ;;
    
    "status")
        print_header "📊 Checking system status..."
        ./system-status.sh
        ;;
    
    "logs")
        print_header "📋 Viewing recent logs..."
        ./check-logs.sh
        ;;
    
    "test")
        print_header "🧪 Running API integration tests..."
        ./test-api.sh
        ;;
    
    "health")
        print_header "🏥 Quick health check..."
        echo "Local health:"
        curl -sf http://localhost/health && echo " ✅" || echo " ❌"
        echo "API health:"
        curl -sf http://localhost/api/health && echo " ✅" || echo " ❌"
        echo "Services:"
        docker-compose -f docker-compose.production.yml ps
        ;;
    
    "start")
        print_header "▶️  Starting all services..."
        docker-compose -f docker-compose.production.yml up -d
        print_success "Services started"
        ;;
    
    "stop")
        print_header "⏹️  Stopping all services..."
        docker-compose -f docker-compose.production.yml down
        print_success "Services stopped"
        ;;
    
    "restart")
        print_header "🔄 Restarting all services..."
        ./restart-services.sh
        ;;
    
    "rebuild")
        print_header "🔨 Rebuilding and restarting services..."
        docker-compose -f docker-compose.production.yml down
        docker-compose -f docker-compose.production.yml build --no-cache
        docker-compose -f docker-compose.production.yml up -d
        print_success "Services rebuilt and restarted"
        ;;
    
    "backup")
        print_header "💾 Creating database backup..."
        ./backup-database.sh
        ;;
    
    "db-shell")
        print_header "🗄️  Connecting to database shell..."
        docker-compose -f docker-compose.production.yml exec postgres psql -U backend_user -d music_campaigns
        ;;
    
    "db-reset")
        print_header "⚠️  Resetting database..."
        read -p "This will delete all data. Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose -f docker-compose.production.yml down -v
            docker-compose -f docker-compose.production.yml up -d
            print_success "Database reset completed"
        else
            print_info "Database reset cancelled"
        fi
        ;;
    
    "clean")
        print_header "🧹 Cleaning up Docker resources..."
        docker system prune -f
        docker volume prune -f
        print_success "Cleanup completed"
        ;;
    
    "update")
        print_header "🔄 Updating and restarting services..."
        git pull origin main
        docker-compose -f docker-compose.production.yml pull
        docker-compose -f docker-compose.production.yml build
        docker-compose -f docker-compose.production.yml up -d
        print_success "Update completed"
        ;;
    
    "env-setup")
        print_header "⚙️  Setting up environment file..."
        if [ ! -f ".env" ]; then
            cp .env.example .env
            print_success ".env file created from template"
            print_info "Please edit .env file with your configuration"
        else
            print_info ".env file already exists"
        fi
        ;;
    
    "dev")
        print_header "🛠️  Starting development environment..."
        docker-compose -f docker-compose.dev.yml up -d
        print_success "Development environment started"
        ;;
    
    "dev-logs")
        print_header "📋 Development logs..."
        docker-compose -f docker-compose.dev.yml logs -f
        ;;
    
    "shell")
        print_header "🐚 Opening backend shell..."
        docker-compose -f docker-compose.production.yml exec backend /bin/bash
        ;;
    
    "help"|*)
        show_usage
        ;;
esac
