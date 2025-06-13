#!/bin/bash

# SSL Certificate Setup Script for Production Domain
# Run this on your Raspberry Pi to set up HTTPS for xsigned.ai

set -e

echo "🔒 Setting up SSL certificates for xsigned.ai..."

# Create SSL directory
mkdir -p ssl certbot

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

# Create temporary nginx config for initial certificate
cat > nginx-temp.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name xsigned.ai www.xsigned.ai;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$server_name$request_uri;
        }
    }
}
EOF

echo "📋 Starting temporary nginx for certificate generation..."

# Stop any running nginx
docker compose down nginx 2>/dev/null || true

# Run temporary nginx
docker run -d --name temp-nginx \
    -p 80:80 \
    -v $(pwd)/nginx-temp.conf:/etc/nginx/nginx.conf \
    -v $(pwd)/certbot:/var/www/certbot \
    nginx:alpine

echo "🔐 Generating SSL certificates with Let's Encrypt..."

# Generate certificates
docker run --rm \
    -v $(pwd)/ssl:/etc/letsencrypt \
    -v $(pwd)/certbot:/var/www/certbot \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    -d xsigned.ai \
    -d www.xsigned.ai

# Stop temporary nginx
docker stop temp-nginx
docker rm temp-nginx

# Copy certificates to correct location
mkdir -p ssl
cp ssl/live/xsigned.ai/fullchain.pem ssl/
cp ssl/live/xsigned.ai/privkey.pem ssl/

echo "✅ SSL certificates generated successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Update your email in docker-compose.production.yml"
echo "2. Deploy with: docker compose -f docker-compose.production.yml up -d"
echo "3. Set up automatic certificate renewal"

# Create renewal script
cat > renew-ssl.sh << 'EOF'
#!/bin/bash
echo "🔄 Renewing SSL certificates..."
docker compose -f docker-compose.production.yml exec certbot certbot renew --webroot --webroot-path=/var/www/certbot
docker compose -f docker-compose.production.yml restart nginx
echo "✅ Certificate renewal complete!"
EOF

chmod +x renew-ssl.sh

echo "📝 Created renew-ssl.sh script for automatic renewal"
echo "   Add to crontab: 0 12 * * * /path/to/renew-ssl.sh"
