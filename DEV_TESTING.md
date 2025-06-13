# 🚀 Development Testing Guide for Raspberry Pi

This guide covers the optimal development workflow:

- **Backend**: Runs on Raspberry Pi via Docker (http://192.168.86.70:5001)
- **Frontend**: Runs locally with `npm run dev` (connects to Pi backend)
- **Database**: PostgreSQL on Pi via Docker

## 📋 Prerequisites

1. **Repository Structure** on your Pi:

   ```
   /home/colin/
   ├── xsigned-backend/          # This repo (backend)
   └── xsigned/                  # Your frontend repo (optional)
   ```

   **Recommended Workflow**: Run frontend locally on your development machine for faster iteration, while backend and database run on Pi.

2. **Required Software**:
   - **On Pi**: Docker and Docker Compose, Git
   - **Local Machine**: Node.js, npm, curl (for testing)

## 🛠️ Setup Development Environment

### Step 1: Deploy Backend to Pi

```bash
# Option 1: Use the automated deployment script (recommended)
./run.sh deploy-dev

# Option 2: Manual deployment
scp -r . colin@192.168.86.70:/home/colin/xsigned-backend/
ssh colin@192.168.86.70 "cd /home/colin/xsigned-backend && ./setup-dev.sh"
```

### Step 2: Setup Local Frontend

```bash
# On your local machine, in your frontend directory
cd /path/to/your/xsigned-frontend

# Create development environment file
cat > .env.development << EOF
VITE_API_URL=http://192.168.86.70:5001/api
VITE_ENV=development
VITE_APP_NAME=XSigned - Music Campaign Manager (Dev)
VITE_DEBUG=true
EOF

# Install dependencies and start development server
npm install
npm run dev
```

### Step 3: Test Integration

```bash
# Test backend health from your local machine
curl http://192.168.86.70:5001/health

# Test CORS (should work from your frontend)
curl -H "Origin: http://localhost:5173" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     http://192.168.86.70:5001/api/users
```

### Step 3: Test Integration

```bash
# Test backend health from your local machine
curl http://192.168.86.70:5001/health

# Test CORS (should work from your frontend)
curl -H "Origin: http://localhost:5173" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     http://192.168.86.70:5001/api/users
```

## 💻 Daily Development Workflow

### The Optimal Setup

1. **Backend & Database**: Running on Pi (http://192.168.86.70:5001)
2. **Frontend**: Running locally on your machine (http://localhost:5173)
3. **Code Changes**: Edit locally, sync to Pi as needed

### Starting Your Development Session

```bash
# 1. Ensure backend is running on Pi
ssh colin@192.168.86.70 "cd /home/colin/xsigned-backend && ./run.sh dev"

# 2. Start frontend locally (from your machine)
cd /path/to/your/frontend
npm run dev
```

### Making Changes

#### Frontend Changes (Instant Feedback)

- Edit your React components locally
- Changes automatically reload at http://localhost:5173
- API calls go to http://192.168.86.70:5001/api

#### Backend Changes (Deploy to Pi)

```bash
# Option 1: Quick sync (for small changes)
rsync -av --exclude node_modules --exclude .git . colin@192.168.86.70:/home/colin/xsigned-backend/

# Option 2: Git workflow (recommended)
git add . && git commit -m "Backend changes"
git push
ssh colin@192.168.86.70 "cd /home/colin/xsigned-backend && git pull && docker-compose -f docker-compose.dev.yml restart backend"
```

### Testing Your Changes

```bash
# Test API from your local machine
curl http://192.168.86.70:5001/api/users

# Test CORS from frontend origin
curl -H "Origin: http://localhost:5173" http://192.168.86.70:5001/api/users

# Full development test on Pi
ssh colin@192.168.86.70 "cd /home/colin/xsigned-backend && ./run.sh dev-test"
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

### Development Environment

- **Frontend**: http://localhost:5173 (running locally with `npm run dev`)
- **Backend API**: http://192.168.86.70:5001 (running on Pi)
- **API Health**: http://192.168.86.70:5001/health
- **Database**: localhost:5432 (accessible from Pi only)

### Key Configuration

- Frontend connects to: `VITE_API_URL=http://192.168.86.70:5001/api`
- CORS enabled for: `http://localhost:5173`
- Hot reloading: Frontend (instant), Backend (on Pi restart)

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

## 🎯 Frontend Development (Recommended: Local)

### 1. Setup Local Frontend Environment

Create `.env.development` in your local frontend directory:

```bash
# In your local frontend directory
cat > .env.development << EOF
VITE_API_URL=http://192.168.86.70:5001/api
VITE_ENV=development
VITE_APP_NAME=XSigned - Music Campaign Manager (Dev)
VITE_DEBUG=true
EOF
```

### 2. Start Local Frontend Development

```bash
# On your local machine
cd /path/to/your/xsigned-frontend
npm install  # First time only
npm run dev  # Starts at http://localhost:5173
```

### 3. Development Benefits

- ⚡ **Instant Hot Reload**: Changes appear immediately
- 🔧 **Full Dev Tools**: Browser dev tools, React DevTools, etc.
- 🚀 **Fast Iteration**: No file transfer delays
- 🌐 **CORS Handled**: Backend configured for localhost:5173

### 4. Test Integration

```bash
# Test API connectivity from your browser console
fetch('http://192.168.86.70:5001/api/users')
  .then(r => r.json())
  .then(console.log)

# Or test from command line
curl -H "Origin: http://localhost:5173" http://192.168.86.70:5001/api/users
```

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
