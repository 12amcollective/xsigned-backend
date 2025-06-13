#!/bin/bash

# Cloudflare Tunnel Setup Script
# Alternative to port forwarding - more secure

echo "🌐 Setting up Cloudflare Tunnel for xsigned.ai..."

# Install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared.deb

# Login to Cloudflare
echo "🔐 Please login to Cloudflare..."
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create music-campaign

# Configure tunnel
cat > tunnel-config.yml << EOF
tunnel: music-campaign
credentials-file: /home/ubuntu/.cloudflared/[TUNNEL-ID].json

ingress:
  - hostname: xsigned.ai
    service: http://localhost:80
  - hostname: www.xsigned.ai
    service: http://localhost:80
  - service: http_status:404
EOF

echo "✅ Cloudflare tunnel configured!"
echo "📋 Next steps:"
echo "1. Update tunnel-config.yml with your actual tunnel ID"
echo "2. Run: cloudflared tunnel route dns music-campaign xsigned.ai"
echo "3. Run: cloudflared tunnel route dns music-campaign www.xsigned.ai"
echo "4. Start tunnel: cloudflared tunnel run music-campaign"
