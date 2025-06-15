#!/bin/bash

# Generate secure keys for production deployment
# Run this script to generate all the secrets needed for .env file

echo "🔐 Generating Secure Keys for Production..."
echo "=========================================="

# Generate all secrets
DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
FLASK_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
ENCRYPTION_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

echo ""
echo "✅ Generated secure production secrets!"
echo ""

# Option 1: Display values to copy manually
echo "📋 Copy these values to your .env file:"
echo "========================================"
echo ""
echo "# Database Configuration"
echo "DB_PASSWORD=$DB_PASSWORD"
echo ""
echo "# Flask Configuration"
echo "FLASK_ENV=production"
echo "FLASK_DEBUG=false"
echo "FLASK_SECRET_KEY=$FLASK_SECRET_KEY"
echo ""
echo "# Security Keys"
echo "JWT_SECRET_KEY=$JWT_SECRET_KEY"
echo "ENCRYPTION_KEY=$ENCRYPTION_KEY"
echo ""

# Option 2: Create .env file automatically
read -p "🤖 Create production .env file automatically? (y/n): " create_env

if [[ $create_env =~ ^[Yy]$ ]]; then
    echo ""
    echo "📝 Creating production .env file..."
    
    # Use .env.production as template and replace placeholder values
    if [ -f ".env.production" ]; then
        echo "📋 Using .env.production as template..."
        cp .env.production .env
        
        # Replace placeholder values with generated secrets
        sed -i "s/your_secure_database_password_here/$DB_PASSWORD/g" .env
        sed -i "s/your_generated_flask_secret_key_here/$FLASK_SECRET_KEY/g" .env
        sed -i "s/your-super-secret-jwt-key-change-this/$JWT_SECRET_KEY/g" .env
        sed -i "s/your-32-byte-base64-key-change-this/$ENCRYPTION_KEY/g" .env
        
        echo "✅ .env file created from template with secure values!"
    else
        echo "📝 Creating new .env file..."
        cat > .env << EOF
# Database Configuration
DB_PASSWORD=$DB_PASSWORD

# Flask Configuration
FLASK_ENV=production
FLASK_DEBUG=false
FLASK_SECRET_KEY=$FLASK_SECRET_KEY

# Security Keys
JWT_SECRET_KEY=$JWT_SECRET_KEY
ENCRYPTION_KEY=$ENCRYPTION_KEY

# Optional: OAuth Configuration (for future use)
# AUTH0_DOMAIN=your-domain.auth0.com
# AUTH0_CLIENT_ID=your-client-id
# AUTH0_CLIENT_SECRET=your-client-secret
# SPOTIFY_CLIENT_ID=your-spotify-id
# SPOTIFY_CLIENT_SECRET=your-spotify-secret

# Optional: Cloudflare Tunnel (uncomment if using)
# CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here
EOF
        echo "✅ .env file created successfully!"
    fi
    
    echo ""
    echo "🔒 Security check:"
    if grep -q ".env" .gitignore 2>/dev/null; then
        echo "✅ .env is in .gitignore"
    else
        echo "⚠️  Adding .env to .gitignore..."
        echo ".env" >> .gitignore
        echo "✅ .env added to .gitignore"
    fi
    
    echo ""
    echo "📋 Environment file summary:"
    echo "  • .env.production = Template with placeholders"
    echo "  • .env = Active file with real secrets (used by Docker)"
    echo "  • .env is git-ignored for security"
else
    echo ""
    echo "📝 Manual setup:"
    echo "  1. Copy .env.production to .env: cp .env.production .env"
    echo "  2. Replace placeholder values with the secrets above"
    echo "  3. Verify .env is in .gitignore"
fi

echo ""
echo "🔐 Keys generated successfully!"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "  • Store these keys securely"
echo "  • Never commit .env to git (it should be in .gitignore)"
echo "  • Use different keys for dev/staging/production"
echo "  • Consider using a secrets manager for production"
echo ""
echo "📝 Environment File Structure:"
echo "  • .env.production = Template with placeholder values (safe to commit)"
echo "  • .env = Active file with real secrets (git-ignored, used by Docker)"
echo "  • .env.dev = Development environment (created separately)"
echo ""
echo "📝 Next steps:"
echo "  1. Verify your .env file has real secrets (no placeholder values)"
echo "  2. Run: ./validate-production.sh"
echo "  3. Run: ./deploy-to-production.sh"
echo ""
