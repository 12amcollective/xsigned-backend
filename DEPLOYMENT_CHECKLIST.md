# 🚀 Music Campaign Backend - Deployment Checklist

Follow this checklist to deploy your music marketing campaign backend to Raspberry Pi with Cloudflare Tunnel.

## ✅ Pre-Deployment Checklist

### 1. Prerequisites
- [ ] Raspberry Pi 4/5 with Ubuntu/Raspberry Pi OS installed
- [ ] SSH access to your Pi configured
- [ ] Cloudflare account with domain (xsigned.ai) configured
- [ ] Basic familiarity with terminal/command line

### 2. Environment Setup
- [ ] Copy `.env.example` to `.env`
- [ ] Generate strong `DB_PASSWORD` (12+ characters)
- [ ] Generate `FLASK_SECRET_KEY` using: `python -c "import secrets; print(secrets.token_hex(32))"`
- [ ] Configure `CLOUDFLARE_TUNNEL_TOKEN` (get from Cloudflare dashboard)
- [ ] Set `DOMAIN=xsigned.ai` and `API_URL=https://xsigned.ai/api`

### 3. Validation
- [ ] Run `./validate-deployment.sh` and fix any issues
- [ ] Ensure all required files are present
- [ ] Verify Docker and Docker Compose are ready

## 🚀 Deployment Steps

### Step 1: Transfer Files to Pi
```bash
# On your local machine
scp -r music-campaign-backend/ ubuntu@YOUR_PI_IP:~/
```

### Step 2: SSH to Pi and Deploy
```bash
# SSH to your Pi
ssh ubuntu@YOUR_PI_IP

# Navigate to project
cd ~/music-campaign-backend

# Run deployment
./deploy-to-pi.sh
```

### Step 3: Configure Cloudflare Tunnel
If not using token method:
```bash
./setup-cloudflare-tunnel.sh
```

### Step 4: Verify Deployment
```bash
# Check system status
./system-status.sh

# Test API endpoints
./test-api.sh

# Check logs
./check-logs.sh
```

## 🔍 Post-Deployment Verification

### Local Tests (on Pi)
- [ ] Health check: `curl http://localhost/health`
- [ ] API health: `curl http://localhost/api/health`
- [ ] Frontend loads: `curl http://localhost`
- [ ] Database connection works

### External Tests
- [ ] Site accessible: https://xsigned.ai
- [ ] API accessible: https://xsigned.ai/api/health
- [ ] Frontend loads properly
- [ ] CORS headers present

### System Health
- [ ] All Docker containers running
- [ ] Cloudflare tunnel connected
- [ ] No error logs
- [ ] Reasonable response times (<2 seconds)

## 🛠️ Troubleshooting

### Services Won't Start
1. Check Docker: `sudo systemctl status docker`
2. Check logs: `./check-logs.sh`
3. Restart services: `./restart-services.sh`
4. Check resources: `free -h && df -h`

### Tunnel Not Working
1. Check tunnel status: `sudo systemctl status cloudflared`
2. View tunnel logs: `sudo journalctl -u cloudflared -f`
3. Verify token in `.env` file
4. Check Cloudflare dashboard for tunnel status

### Database Issues
1. Check PostgreSQL: `docker-compose -f docker-compose.production.yml exec postgres pg_isready -U backend_user`
2. Reset database: `docker-compose -f docker-compose.production.yml down -v && docker-compose -f docker-compose.production.yml up -d`
3. Check environment variables

### Performance Issues
1. Monitor resources: `htop` or `top`
2. Check Docker stats: `docker stats`
3. Review logs for errors
4. Consider increasing Pi memory split

## 📊 Monitoring & Maintenance

### Daily Checks
- [ ] Run `./system-status.sh`
- [ ] Check site accessibility
- [ ] Review error logs

### Weekly Maintenance
- [ ] Run `./backup-database.sh`
- [ ] Update system packages: `sudo apt update && sudo apt upgrade`
- [ ] Clean Docker: `docker system prune -f`

### Monthly Tasks
- [ ] Review and rotate logs
- [ ] Check disk space usage
- [ ] Verify backup integrity
- [ ] Update application if needed

## 🔧 Useful Commands

### Service Management
```bash
# Start services
docker-compose -f docker-compose.production.yml up -d

# Stop services
docker-compose -f docker-compose.production.yml down

# Restart specific service
docker-compose -f docker-compose.production.yml restart backend

# View logs
docker-compose -f docker-compose.production.yml logs -f backend
```

### System Monitoring
```bash
# System status
./system-status.sh

# API tests
./test-api.sh

# Check logs
./check-logs.sh

# Service status
docker-compose -f docker-compose.production.yml ps
```

### Database Operations
```bash
# Backup database
./backup-database.sh

# Connect to database
docker-compose -f docker-compose.production.yml exec postgres psql -U backend_user -d music_campaigns

# View database size
docker-compose -f docker-compose.production.yml exec postgres psql -U backend_user -d music_campaigns -c "SELECT pg_size_pretty(pg_database_size('music_campaigns'));"
```

## 🎯 Success Criteria

Your deployment is successful when:

✅ **System Health**
- All services show "Up" status
- Health endpoints return 200 OK
- No critical errors in logs
- System resources are stable

✅ **Functionality**
- Users can be created via API
- Campaigns can be created and managed
- Database operations work correctly
- CORS headers are present

✅ **External Access**
- https://xsigned.ai loads correctly
- API endpoints accessible externally
- Cloudflare tunnel shows "Connected"
- SSL/TLS certificate is valid

✅ **Performance**
- Response times < 2 seconds
- Database queries execute quickly
- No memory leaks or resource exhaustion
- Automatic restarts work properly

## 📞 Support Resources

### Documentation
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Comprehensive deployment guide
- [README.md](./README.md) - Project overview
- Cloudflare Tunnel docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

### Quick Commands
```bash
# Complete status check
./system-status.sh

# Validate configuration
./validate-deployment.sh

# Test all endpoints
./test-api.sh

# Emergency restart
./restart-services.sh
```

### Log Files
- Application logs: `./logs/`
- Nginx logs: `docker-compose logs nginx`
- System logs: `sudo journalctl -u cloudflared`

---

## 🎉 Congratulations!

Once all items are checked, your Music Campaign Backend is successfully deployed and ready for production use at **https://xsigned.ai**!

**Next Steps:**
1. Start building your React frontend
2. Implement OAuth authentication
3. Add social media integrations
4. Set up monitoring and alerting
5. Plan for scaling and backups
