# 🚀 Quick Start - Development Setup

This is the fastest way to get your XSigned backend running on Pi with local frontend development.

## ⚡ One-Command Setup

```bash
# Deploy backend to Pi and start development
./run.sh deploy-dev
```

This will:

- ✅ Transfer files to Pi
- ✅ Install Docker if needed
- ✅ Start backend + database services
- ✅ Verify everything is working

## 🖥️ Frontend Development

```bash
# In your local frontend directory
echo "VITE_API_URL=http://192.168.86.70:5001/api" > .env.development
npm run dev
```

Your frontend runs at http://localhost:5173 and connects to the Pi backend.

## 🧪 Test Everything Works

```bash
# Test backend health
curl http://192.168.86.70:5001/health

# Test API
curl http://192.168.86.70:5001/api/users
```

## 🔧 Development Commands

```bash
# Deploy/redeploy backend to Pi
./run.sh deploy-dev

# Check if everything is working
./run.sh dev-status

# View backend logs from Pi
ssh colin@192.168.86.70 "cd /home/colin/xsigned-backend && ./run.sh dev-logs"

# Stop backend on Pi
ssh colin@192.168.86.70 "cd /home/colin/xsigned-backend && ./run.sh dev-stop"
```

## 📁 Project Structure

```
Your Machine:
├── xsigned-backend/     # This repo - deploy to Pi
└── xsigned-frontend/    # Run locally with npm run dev

Raspberry Pi:
└── /home/colin/xsigned-backend/  # Backend + Database running here
```

## 🌐 Access URLs

- **Frontend**: http://localhost:5173 (local development)
- **Backend API**: http://192.168.86.70:5001 (on Pi)
- **Backend Health**: http://192.168.86.70:5001/health

## ❓ Need Help?

See [DEV_TESTING.md](./DEV_TESTING.md) for detailed instructions and troubleshooting.

---

**Ready to code!** Make changes locally, frontend auto-reloads, backend runs on Pi. 🎵
