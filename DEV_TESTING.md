# 🚀 Development Testing Guide for Raspberry Pi

This guide will help you set up and test your music campaign backend in development mode on your Raspberry Pi.

## 📋 Prerequisites

1. **Repository Structure** on your Pi:

   ```
   /home/your-username/
   ├── music-campaign-backend/    # This repo
   └── XSignedAI/                # Your frontend repo
   ```

2. **Required Software**:
   - Docker and Docker Compose
   - Git
   - curl (for testing)

## 🛠️ Setup Development Environment

### 1. Transfer Files to Pi

```bash
# On your local machine
scp -r music-campaign-backend/ ubuntu@192.168.86.70:~/
```

### 2. SSH to Pi and Setup

```bash
# SSH to your Pi
ssh ubuntu@192.168.86.70

# Navigate to backend
cd ~/music-campaign-backend

# Run initial development setup
./run.sh setup-dev
```

This will:

- ✅ Install Docker if needed
- ✅ Check repository structure
- ✅ Create development environment files
- ✅ Setup frontend dependencies
- ✅ Start development services

### 3. Test the Setup

```bash
# Test the development environment
./run.sh dev-test
```

## 🔧 Development Commands

### Start Development

```bash
./run.sh dev           # Start development environment
./run.sh dev-logs      # View logs (Ctrl+C to exit)
```

### Test Development

```bash
./run.sh dev-test      # Run comprehensive tests
curl http://192.168.86.70:5001/health  # Quick health check
```

### Stop Development

```bash
./run.sh dev-stop      # Stop all development services
```

## 🌐 Access URLs

When development is running:

- **Backend API**: http://192.168.86.70:5001
- **API Health**: http://192.168.86.70:5001/health
- **Database**: localhost:5432 (from Pi)

## 🧪 Testing API Endpoints

### Health Check

```bash
curl http://192.168.86.70:5001/health
```

### Create User

```bash
curl -X POST http://192.168.86.70:5001/api/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@dev.local","username":"devuser"}'
```

### Create Campaign

```bash
curl -X POST http://192.168.86.70:5001/api/campaigns \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"name":"Dev Campaign","description":"Testing campaign"}'
```

### List Users

```bash
curl http://192.168.86.70:5001/api/users
```

### List Campaigns

```bash
curl http://192.168.86.70:5001/api/campaigns
```

## 🎯 Frontend Development

### 1. Setup Frontend Environment

Your frontend should have these environment variables in `.env.development`:

```bash
VITE_API_URL=http://192.168.86.70/api
VITE_ENV=development
VITE_APP_NAME="XSignedAI - Music Campaign Manager (Dev)"
VITE_DEBUG=true
```

### 2. Start Frontend Development

```bash
# In your frontend directory
cd ~/XSignedAI
npm run dev
```

### 3. Test Integration

- Frontend should connect to backend API
- CORS should be configured properly
- API calls should work from browser

## 🔍 Troubleshooting

### Backend Issues

```bash
# Check service status
./run.sh dev-test

# View detailed logs
./run.sh dev-logs

# Restart backend only
docker-compose -f docker-compose.dev.yml restart backend

# Check database
docker-compose -f docker-compose.dev.yml exec postgres psql -U backend_user -d music_campaigns
```

### Network Issues

```bash
# Check Pi IP address
ip addr show

# Test from another device on network
curl http://192.168.86.70:5001/health

# Check firewall (if issues)
sudo ufw status
```

### Resource Issues

```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check Docker resources
docker system df
```

## 📊 Development Workflow

### 1. Daily Development

```bash
# Start development
./run.sh dev

# Make backend changes (hot reload enabled)
# Test changes
./run.sh dev-test

# View logs
./run.sh dev-logs
```

### 2. Frontend Development

```bash
# Start frontend dev server
cd ~/XSignedAI
npm run dev

# Frontend will auto-reload on changes
# Backend API available at http://192.168.86.70:5001/api
```

### 3. Database Changes

```bash
# Connect to database
./run.sh db-shell

# Reset database if needed (⚠️ destructive)
docker-compose -f docker-compose.dev.yml down -v
./run.sh dev
```

## 🚀 Ready for Production

When development testing is complete:

```bash
# Stop development
./run.sh dev-stop

# Switch to production
./run.sh validate
./run.sh deploy
```

## 📞 Need Help?

### Quick Diagnostics

```bash
./run.sh dev-test      # Comprehensive test
./run.sh help          # All available commands
docker-compose -f docker-compose.dev.yml ps  # Service status
```

### Common Issues

1. **Services won't start**: Check Docker is running, check memory
2. **Can't connect from frontend**: Verify IP address, check CORS
3. **Database issues**: Reset with `docker-compose down -v`
4. **Permission issues**: Check file permissions with `ls -la`

---

## 🎉 Success!

Your development environment is ready when:

- ✅ `./run.sh dev-test` passes all tests
- ✅ Backend API responds at http://192.168.86.70:5001
- ✅ Frontend can connect to backend
- ✅ Database operations work
- ✅ Hot reloading works for both frontend and backend

Happy coding! 🎵
