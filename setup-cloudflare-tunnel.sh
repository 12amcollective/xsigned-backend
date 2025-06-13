#!/bin/bash

# Cloudflare Tunnel Setup Script for Music Campaign Backend
# Alternative to port forwarding - more secure and reliable

set -e  # Exit on any error

echo "🌐 Setting up Cloudflare Tunnel for xsigned.ai..."

# Check if running on ARM64 (Raspberry Pi)
ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo "📱 Detected ARM64 architecture (Raspberry Pi)"
    CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb"
else
    echo "💻 Detected x86_64 architecture"
    CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
fi

# Install cloudflared if not already installed
if ! command -v cloudflared &> /dev/null; then
    echo "📦 Installing cloudflared..."
    curl -L --output cloudflared.deb "$CLOUDFLARED_URL"
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
    echo "✅ cloudflared installed successfully"
else
    echo "✅ cloudflared already installed"
fi

# Check if already logged in
if [ ! -d "$HOME/.cloudflared" ]; then
    echo "🔐 Please login to Cloudflare..."
    echo "This will open a browser window for authentication."
    cloudflared tunnel login
else
    echo "✅ Already logged in to Cloudflare"
fi

# Create tunnel if it doesn't exist
TUNNEL_NAME="music-campaign"
if ! cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo "🔧 Creating tunnel: $TUNNEL_NAME"
    cloudflared tunnel create "$TUNNEL_NAME"
else
    echo "✅ Tunnel '$TUNNEL_NAME' already exists"
fi

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
echo "📋 Tunnel ID: $TUNNEL_ID"

# Create tunnel configuration
echo "📝 Creating tunnel configuration..."
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: /home/$USER/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: xsigned.ai
    service: http://localhost:80
  - hostname: www.xsigned.ai
    service: http://localhost:80
  - hostname: "*.xsigned.ai"
    service: http://localhost:80
  - service: http_status:404
EOF

# Set up DNS records
echo "🌍 Setting up DNS records..."
cloudflared tunnel route dns "$TUNNEL_NAME" xsigned.ai
cloudflared tunnel route dns "$TUNNEL_NAME" www.xsigned.ai

# Create systemd service for auto-startup
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/cloudflared tunnel run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

echo ""
echo "✅ Cloudflare Tunnel setup completed!"
echo ""
echo "📋 Configuration Summary:"
echo "  • Tunnel Name: $TUNNEL_NAME"
echo "  • Tunnel ID: $TUNNEL_ID"
echo "  • Domains: xsigned.ai, www.xsigned.ai"
echo "  • Service: Auto-starting via systemd"
echo ""
echo "🔍 Check tunnel status:"
echo "  sudo systemctl status cloudflared"
echo ""
echo "📊 View tunnel logs:"
echo "  sudo journalctl -u cloudflared -f"
echo ""
echo "🌐 Your site should be accessible at: https://xsigned.ai"
