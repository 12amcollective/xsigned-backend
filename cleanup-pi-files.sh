#!/bin/bash

# 🧹 Pi Deployment Files Cleanup Script
# =====================================
# This script helps you organize Pi deployment files after migrating to Cloud Run

set -e

echo "🧹 Pi Deployment Files Cleanup"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
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

# Check if user wants to keep Pi files as backup
echo "You now have both Pi deployment files and Cloud Run files."
echo "What would you like to do?"
echo ""
echo "1. 🗂️  Organize files (move Pi files to archive folder)"
echo "2. 🗑️  Delete Pi-specific files (keep only Cloud Run)"
echo "3. 📦 Keep everything as-is"
echo "4. ❌ Cancel cleanup"
echo ""
read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo ""
        print_info "Creating archive folder for Pi deployment files..."
        
        # Create archive directory
        mkdir -p archive/pi-deployment
        
        # Pi-specific files to archive
        PI_FILES=(
            "docker-compose.production.yml"
            "docker-compose.dev.yml"
            "docker-compose.backend-only.yml"
            "nginx-production.conf"
            "nginx-production-http.conf"
            "nginx-dev.conf"
            "nginx-cloudflare.conf"
            "deploy-production.sh"
            "deploy-dev-to-pi.sh"
            "deploy-to-production.sh"
            "setup-cloudflare-tunnel.sh"
            "setup-dev.sh"
            "setup-ssl.sh"
            "test-production.sh"
            "test-dev.sh"
            "test-nginx-proxy.sh"
            "validate-deployment.sh"
            "validate-production.sh"
            "system-status.sh"
            "install-docker-pi.sh"
            "enable-ssh-pi.md"
            "CLOUDFLARE_TUNNEL_SETUP.md"
            "NGINX_PROXY_FIX.md"
            "PRODUCTION_DEPLOYMENT_CHECKLIST.md"
            "PRODUCTION_READY.md"
            "DEPLOYMENT_CHECKLIST.md"
            "DEPLOYMENT.md"
            "SECURITY_AUDIT.md"
            ".env.production"
            "generate-secrets.sh"
            "check-dev-status.sh"
        )
        
        print_info "Moving Pi deployment files to archive..."
        moved_count=0
        
        for file in "${PI_FILES[@]}"; do
            if [ -f "$file" ]; then
                mv "$file" "archive/pi-deployment/"
                echo "  📦 Moved: $file"
                ((moved_count++))
            elif [ -d "$file" ]; then
                mv "$file" "archive/pi-deployment/"
                echo "  📦 Moved: $file"
                ((moved_count++))
            fi
        done
        
        print_success "Moved $moved_count Pi deployment files to archive/pi-deployment/"
        
        # Create README in archive
        cat > archive/pi-deployment/README.md << 'EOF'
# Pi Deployment Files Archive

These files were used for deploying to Raspberry Pi before migrating to Google Cloud Run.

## Archived Files

- **Docker Compose**: Pi-specific container configurations
- **Nginx Configs**: Pi nginx proxy configurations
- **Deployment Scripts**: Pi deployment automation
- **Documentation**: Pi-specific setup guides
- **Cloudflare Tunnel**: Files for Pi tunnel setup

## Restoration

If you need to restore Pi deployment:

1. Copy files back to project root
2. Update IP addresses and domains as needed
3. Run Pi deployment scripts

## Cloud Run Migration

The project has been migrated to Google Cloud Run for better reliability.
See the main project files for Cloud Run deployment.
EOF
        
        print_success "Created archive README with restoration instructions"
        ;;
        
    2)
        echo ""
        print_warning "This will permanently delete Pi deployment files!"
        read -p "Are you sure? Type 'DELETE' to confirm: " confirm
        
        if [ "$confirm" = "DELETE" ]; then
            print_info "Deleting Pi deployment files..."
            
            # Files to delete
            DELETE_FILES=(
                "docker-compose.production.yml"
                "docker-compose.dev.yml"  
                "docker-compose.backend-only.yml"
                "nginx-production.conf"
                "nginx-production-http.conf"
                "nginx-dev.conf"
                "nginx-cloudflare.conf"
                "deploy-production.sh"
                "deploy-dev-to-pi.sh"
                "deploy-to-production.sh"
                "setup-cloudflare-tunnel.sh"
                "setup-dev.sh"
                "setup-ssl.sh"
                "test-production.sh"
                "test-dev.sh"
                "test-nginx-proxy.sh"
                "validate-deployment.sh"
                "validate-production.sh"
                "system-status.sh"
                "install-docker-pi.sh"
                "enable-ssh-pi.md"
                "CLOUDFLARE_TUNNEL_SETUP.md"
                "NGINX_PROXY_FIX.md"
                "PRODUCTION_DEPLOYMENT_CHECKLIST.md"
                "PRODUCTION_READY.md"
                "DEPLOYMENT_CHECKLIST.md"
                "DEPLOYMENT.md"
                "SECURITY_AUDIT.md"
                ".env.production"
                "generate-secrets.sh"
                "check-dev-status.sh"
            )
            
            deleted_count=0
            for file in "${DELETE_FILES[@]}"; do
                if [ -f "$file" ]; then
                    rm "$file"
                    echo "  🗑️  Deleted: $file"
                    ((deleted_count++))
                elif [ -d "$file" ]; then
                    rm -rf "$file"
                    echo "  🗑️  Deleted: $file"
                    ((deleted_count++))
                fi
            done
            
            print_success "Deleted $deleted_count Pi deployment files"
        else
            print_info "Deletion cancelled"
        fi
        ;;
        
    3)
        print_info "Keeping all files as-is"
        print_warning "You may want to organize them later for clarity"
        ;;
        
    4)
        print_info "Cleanup cancelled"
        exit 0
        ;;
        
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

echo ""
print_info "Cleanup summary:"
echo ""

# Show current Cloud Run files
echo "🚀 Cloud Run Files (active):"
echo "  • Dockerfile.cloudrun"
echo "  • deploy-cloudrun.sh"
echo "  • test-cloudrun.sh"
echo "  • cleanup-cloudrun.sh"
echo "  • setup-domain-cloudrun.sh"
echo "  • CLOUDRUN_MIGRATION.md"
echo "  • .env.cloudrun.template"
echo ""

# Show what's left
if [ -d "archive/pi-deployment" ]; then
    echo "📦 Archived Pi Files:"
    echo "  • archive/pi-deployment/ ($(ls archive/pi-deployment | wc -l) files)"
elif [ "$choice" = "2" ] && [ "$confirm" = "DELETE" ]; then
    echo "🗑️  Pi Files: Deleted"
else
    echo "📁 Pi Files: Still in project root"
fi

echo ""
print_success "🎉 Cleanup complete!"
echo ""
echo "📋 Next Steps:"
echo "  1. Deploy to Cloud Run: ./deploy-cloudrun.sh"
echo "  2. Test deployment: ./test-cloudrun.sh"
echo "  3. Update domain DNS: ./setup-domain-cloudrun.sh"
echo ""
echo "💡 Benefits of Cloud Run:"
echo "  • 99.95% uptime guarantee"
echo "  • No more Pi connectivity issues"
echo "  • Automatic scaling and SSL"
echo "  • Enterprise reliability"
