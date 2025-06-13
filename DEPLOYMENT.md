# Music Campaign Backend - Cloudflare Tunnel Deployment Guide

This guide will help you deploy the Music Campaign Backend to your Raspberry Pi using Cloudflare Tunnel for secure, reliable access without port forwarding.

## 🚀 Quick Start

### Prerequisites

- Raspberry Pi 4/5 with Ubuntu/Raspberry Pi OS
- Docker and Docker Compose installed
- Cloudflare account with a domain (xsigned.ai)
- SSH access to your Pi

### 1. Clone and Setup

```bash
# On your Raspberry Pi
git clone https://github.com/your-username/music-campaign-backend.git
cd music-campaign-backend

# Copy environment template
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` file with your values:

```bash
nano .env
```

**Required values:**

- `DB_PASSWORD`: Strong password for PostgreSQL
- `CLOUDFLARE_TUNNEL_TOKEN`: Get from Cloudflare dashboard
- `FLASK_SECRET_KEY`: Generate with `python -c "import secrets; print(secrets.token_hex(32))"`

### 3. Deploy Everything

```bash
# Make scripts executable
chmod +x deploy-to-pi.sh setup-cloudflare-tunnel.sh

# Run complete deployment
./deploy-to-pi.sh
```

This script will:

- ✅ Update system packages
- ✅ Install Docker and Docker Compose
- ✅ Set up Cloudflare Tunnel
- ✅ Build and start all services
- ✅ Configure monitoring scripts
- ✅ Set up automatic database backups

### 4. Verify Deployment

```bash
# Check all services are running
docker-compose -f docker-compose.production.yml ps

# Check application health
curl http://localhost/health

# View logs
./check-logs.sh
```

## 🔧 Manual Cloudflare Tunnel Setup

If you prefer to set up the tunnel manually:

### 1. Get Cloudflare Tunnel Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Zero Trust** → **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Name it `music-campaign`
5. Choose **Cloudflared** connector
6. Copy the token and add it to `.env` file

### 2. Configure Domain

In the tunnel configuration:

- **Public hostname**: `xsigned.ai`
- **Service**: `http://localhost:80`
- Add additional hostname: `www.xsigned.ai`

## 🌐 Service Architecture

```
Internet → Cloudflare → Tunnel → Nginx → Backend/Frontend
                                    ↓
                               PostgreSQL
```

### Services:

- **Frontend**: React app (port 3000)
- **Backend**: Flask API (port 5001)
- **Database**: PostgreSQL (port 5432)
- **Proxy**: Nginx (port 80)
- **Tunnel**: Cloudflared

## 📊 Monitoring & Maintenance

### Check Service Status

```bash
./check-logs.sh
```

### Restart Services

```bash
./restart-services.sh
```

### Backup Database

```bash
./backup-database.sh
```

### View Real-time Logs

```bash
# All services
docker-compose -f docker-compose.production.yml logs -f

# Specific service
docker-compose -f docker-compose.production.yml logs -f backend
```

### Check Cloudflare Tunnel

```bash
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -f
```

## 🔍 Troubleshooting

### Services Won't Start

1. **Check Docker:**

   ```bash
   sudo systemctl status docker
   docker --version
   ```

2. **Check environment variables:**

   ```bash
   cat .env
   ```

3. **Check available resources:**
   ```bash
   free -h
   df -h
   ```

### Database Connection Issues

1. **Check PostgreSQL:**

   ```bash
   docker-compose -f docker-compose.production.yml exec postgres pg_isready -U backend_user
   ```

2. **Reset database:**
   ```bash
   docker-compose -f docker-compose.production.yml down -v
   docker-compose -f docker-compose.production.yml up -d
   ```

### Tunnel Connection Issues

1. **Check tunnel status:**

   ```bash
   sudo systemctl status cloudflared
   ```

2. **Restart tunnel:**

   ```bash
   sudo systemctl restart cloudflared
   ```

3. **Check Cloudflare dashboard:**
   - Verify tunnel is connected
   - Check DNS records

### Application Not Loading

1. **Check nginx:**

   ```bash
   docker-compose -f docker-compose.production.yml logs nginx
   ```

2. **Test locally:**

   ```bash
   curl http://localhost/health
   ```

3. **Check frontend build:**
   ```bash
   docker-compose -f docker-compose.production.yml logs frontend
   ```

## 🔒 Security Features

- ✅ Cloudflare Tunnel (no open ports)
- ✅ CORS properly configured
- ✅ Rate limiting enabled
- ✅ Security headers set
- ✅ Real IP detection from Cloudflare
- ✅ Database password protection
- ✅ Environment variable isolation

## 📈 Performance Optimizations

- ✅ PostgreSQL tuned for Raspberry Pi
- ✅ Nginx caching configured
- ✅ Docker health checks
- ✅ Automatic restarts
- ✅ Log rotation
- ✅ Database connection pooling

## 🔄 Updates & Deployment

### Update Application

```bash
git pull origin main
docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml up -d
```

### Rollback

```bash
# Stop current version
docker-compose -f docker-compose.production.yml down

# Restore from backup if needed
./backup-database.sh

# Start previous version
git checkout previous-commit
docker-compose -f docker-compose.production.yml up -d
```

## 📞 Support

If you encounter issues:

1. Check the logs with `./check-logs.sh`
2. Review this troubleshooting guide
3. Check GitHub issues
4. Verify Cloudflare tunnel status

## 🎉 Success!

Once deployed, your music campaign backend will be available at:

- **Production**: https://xsigned.ai
- **API**: https://xsigned.ai/api
- **Health Check**: https://xsigned.ai/health

The system includes:

- ✅ Automatic backups (daily at 2 AM)
- ✅ Health monitoring
- ✅ Log rotation
- ✅ Automatic service restart
- ✅ Secure tunnel connection
