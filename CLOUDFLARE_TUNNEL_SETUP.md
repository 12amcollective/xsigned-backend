# 🌐 Cloudflare Tunnel Setup Guide

## Step 1: Login to Cloudflare Dashboard

1. Go to [https://dash.cloudflare.com/](https://dash.cloudflare.com/)
2. Login with your Cloudflare account
3. Select your domain (`xsigned.ai`)

## Step 2: Create a Tunnel

1. In the left sidebar, click **"Zero Trust"**
2. Go to **"Access"** > **"Tunnels"**
3. Click **"Create a tunnel"**
4. Choose **"Cloudflared"** as the connector type
5. Name your tunnel (e.g., "xsigned-backend-production")
6. Click **"Save tunnel"**

## Step 3: Get Your Tunnel Token

After creating the tunnel, you'll see:

```
Install and run a connector:
sudo cloudflared service install <LONG_TOKEN_HERE>
```

**Copy the long token from this command** - this is your `CLOUDFLARE_TUNNEL_TOKEN`

## Step 4: Configure Public Hostnames

1. In the tunnel configuration, add a **Public hostname**:

   - **Subdomain**: Leave blank (for root domain) or use `api`
   - **Domain**: `xsigned.ai`
   - **Path**: Leave blank
   - **Service Type**: `HTTP`
   - **URL**: `localhost:80` (nginx will handle routing)

2. Click **"Save tunnel"**

## Step 5: Update Your Environment

Add the token to your `.env` file on the Pi:

```bash
CLOUDFLARE_TUNNEL_TOKEN=your_very_long_token_here
```

## Alternative: Backend-Only Deployment (Skip Cloudflare for now)

If you want to test the backend first without Cloudflare:

1. Skip the tunnel setup for now
2. Access the backend directly via Pi IP: `http://192.168.86.70`
3. Set up Cloudflare later for production domain access

## Verification

After setup, your backend will be accessible at:

- Local: `http://192.168.86.70` (direct Pi access)
- Public: `https://xsigned.ai` (through Cloudflare tunnel)
