# 🚀 Production Deployment Checklist for XSigned Backend

## Pre-Deployment Requirements

### ✅ **Environment Setup**
- [ ] Domain configured and pointing to your Pi (xsigned.ai)
- [ ] Pi accessible on port 80/443 from internet
- [ ] Docker and Docker Compose installed on Pi
- [ ] SSL certificates ready (Let's Encrypt)

### ✅ **Code Verification**
- [x] Development environment tested successfully
- [x] Waitlist endpoint working (`/api/waitlist/join`)
- [x] All API endpoints tested
- [x] Database migrations ready
- [x] Production nginx configuration includes waitlist routes

### ✅ **Security Configuration**
- [ ] Strong database password set in `.env`
- [ ] JWT secret key generated (32+ characters)
- [ ] Flask secret key generated
- [ ] CORS origins configured for production domain
- [ ] SSL certificates obtained

## Deployment Steps

### 1. **Prepare Environment File**
```bash
# Copy and edit production environment
cp .env.production .env

# Edit the following in .env:
# - DB_PASSWORD (use strong password)
# - JWT_SECRET_KEY (generate secure key)
# - FLASK_SECRET_KEY (generate secure key)
```

### 2. **Generate Secure Keys**
```bash
# Generate JWT secret (run on your machine)
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate Flask secret (run on your machine)  
python3 -c "import secrets; print(secrets.token_hex(16))"

# Generate strong database password
python3 -c "import secrets; print(secrets.token_urlsafe(16))"
```

### 3. **Deploy to Production**
```bash
# On your Pi, run:
./deploy-production.sh
```

### 4. **Verify Deployment**
```bash
# Test all endpoints
./test-production.sh  # We'll create this
```

## Post-Deployment Verification

### ✅ **API Endpoints to Test**
- [ ] `https://xsigned.ai/health` - Health check
- [ ] `https://xsigned.ai/api/waitlist/join` - Waitlist signup
- [ ] `https://xsigned.ai/api/waitlist/stats` - Waitlist stats
- [ ] `https://xsigned.ai/api/users/` - Users endpoint
- [ ] `https://xsigned.ai/api/campaigns/` - Campaigns endpoint

### ✅ **Security Verification**
- [ ] HTTPS redirects working (HTTP → HTTPS)
- [ ] SSL certificate valid
- [ ] CORS headers present
- [ ] Rate limiting active
- [ ] Security headers present

### ✅ **Performance & Monitoring**
- [ ] All containers running and healthy
- [ ] Database accessible
- [ ] Logs being written properly
- [ ] Nginx serving correctly
- [ ] Frontend loading from production

## Environment Variables Required

```bash
# Database
DB_PASSWORD=your_secure_password_here

# Flask Configuration  
FLASK_ENV=production
FLASK_DEBUG=false
FLASK_SECRET_KEY=your_generated_secret_key
JWT_SECRET_KEY=your_generated_jwt_secret

# Optional (for future features)
# CLOUDFLARE_TUNNEL_TOKEN=your_token_here
```

## Common Issues & Solutions

### **Issue**: SSL certificates not working
**Solution**: 
```bash
sudo ./setup-ssl.sh
# Make sure domain DNS is properly configured
```

### **Issue**: 502 Bad Gateway
**Solution**: 
```bash
docker-compose -f docker-compose.production.yml logs backend
# Check backend container logs
```

### **Issue**: CORS errors
**Solution**: 
- Verify production domain in `src/app.py` CORS configuration
- Check nginx headers in `nginx-production.conf`

### **Issue**: Database connection failed
**Solution**: 
```bash
docker-compose -f docker-compose.production.yml logs postgres
# Verify DB_PASSWORD in .env matches compose file
```

## Rollback Plan

If deployment fails:
```bash
# Stop production services
docker-compose -f docker-compose.production.yml down

# Restore from backup (if needed)
# Start development environment
docker-compose -f docker-compose.dev.yml up -d
```

## Success Criteria

Deployment is successful when:
- ✅ All containers are running and healthy
- ✅ HTTPS website loads correctly
- ✅ Waitlist signup works from frontend
- ✅ API endpoints return expected responses
- ✅ SSL certificate is valid
- ✅ Performance is acceptable

---

**Ready to deploy?** Run through this checklist and then execute: `./deploy-production.sh`
