# Nginx Proxy Fix for Development Environment

## Problem Summary

The frontend Vite proxy was correctly configured, but the Pi's development environment was missing nginx to route `/api` requests to the backend container.

## What Was Fixed

### 1. Added nginx Service to Development Docker Compose

- **File**: `docker-compose.dev.yml`
- **Added**: nginx service that proxies `/api/*` requests to the backend container
- **Port**: nginx now listens on port 80 (standard HTTP port)

### 2. Created Development-Specific nginx Configuration

- **File**: `nginx-dev.conf` (new)
- **Features**:
  - Proxies `/api/*` to backend container on port 5001
  - Proper CORS headers for development
  - Health check endpoint
  - Rate limiting and security headers
  - Proper error handling

### 3. Updated Setup Scripts

- **File**: `setup-dev.sh`
- **Changes**:
  - Creates nginx log directory
  - Tests nginx proxy health
  - Updated documentation with correct URLs

### 4. Updated Deployment Script

- **File**: `deploy-dev-to-pi.sh`
- **Changes**: Updated instructions to reflect nginx proxy setup

### 5. Created Test Script

- **File**: `test-nginx-proxy.sh` (new)
- **Purpose**: Test nginx proxy functionality and troubleshoot issues

## New Architecture

```
Frontend (localhost:5173)
    ↓ Vite proxy forwards /api/* to
Pi nginx (192.168.86.70:80)
    ↓ /api/* → backend container
Backend Container (backend:5001)
```

## URLs After Fix

- **API Endpoint**: `http://192.168.86.70/api/`
- **Health Check**: `http://192.168.86.70/health`
- **Direct Backend** (for debugging): `http://192.168.86.70:5001/api/`

## Frontend Configuration

Your Vite proxy should target:

```javascript
// vite.config.js
proxy: {
  '/api': {
    target: 'http://192.168.86.70',  // nginx proxy
    changeOrigin: true,
  }
}
```

## Testing

1. **Deploy to Pi**: `./deploy-dev-to-pi.sh`
2. **Test proxy**: `./test-nginx-proxy.sh`
3. **Test frontend**: Your email signup should now work!

## Troubleshooting

If the API still doesn't work:

1. Check services are running:

   ```bash
   ssh colin@192.168.86.70 'cd /home/colin/xsigned-backend && docker-compose -f docker-compose.dev.yml ps'
   ```

2. Check nginx logs:

   ```bash
   ssh colin@192.168.86.70 'cd /home/colin/xsigned-backend && docker-compose -f docker-compose.dev.yml logs nginx'
   ```

3. Test from Pi directly:
   ```bash
   ssh colin@192.168.86.70 'curl http://localhost/api/users'
   ```

## What This Fixes

✅ **Frontend**: Already working correctly  
✅ **Vite proxy**: Already working correctly  
✅ **nginx routing**: Now properly configured  
✅ **Backend container**: Already working correctly

The email signup and all other API calls should now work properly through the nginx proxy!
