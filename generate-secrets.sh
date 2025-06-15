#!/bin/bash

# Generate secure keys for production deployment
# Run this script to generate all the secrets needed for .env file

echo "🔐 Generating Secure Keys for Production..."
echo "=========================================="

echo ""
echo "Copy these values to your .env file:"
echo ""

echo "# Database Password (16 chars, URL-safe)"
DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
echo "DB_PASSWORD=$DB_PASSWORD"

echo ""
echo "# Flask Secret Key (32 chars hex)"
FLASK_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
echo "FLASK_SECRET_KEY=$FLASK_SECRET_KEY"

echo ""
echo "# JWT Secret Key (32 chars, URL-safe)"
JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
echo "JWT_SECRET_KEY=$JWT_SECRET_KEY"

echo ""
echo "🔐 Keys generated successfully!"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "  • Store these keys securely"
echo "  • Never commit them to git"
echo "  • Use different keys for dev/staging/production"
echo "  • Consider using a secrets manager for production"
echo ""
echo "📝 Next steps:"
echo "  1. Copy the values above to your .env file"
echo "  2. Verify .env is in .gitignore"
echo "  3. Run: ./deploy-production.sh"
echo ""
