# Redis Environment Variables Setup for Render.com

## Quick Fix for Your Current Issue

Your Redis connection is failing because it requires SSL. Here's what you need to set in your Render.com environment variables:

## Required Environment Variables

```bash
# Basic Redis Connection
REDIS_HOST=redis-206667-0.cloudclusters.net
REDIS_PORT=10023
REDIS_PASSWORD=nz4Sf22Yi35C

# IMPORTANT: Use rediss:// (with double 's') for SSL
REDIS_BROKER_URL=rediss://flight_blender:nz4Sf22Yi35C@redis-206667-0.cloudclusters.net:10023

# Optional: If you want to set username separately
REDIS_USERNAME=flight_blender
```

## Key Points

1. **SSL Required**: Your Redis server requires SSL/TLS encryption
2. **URL Format**: Use `rediss://` not `redis://` in `REDIS_BROKER_URL`
3. **Auto-Detection**: The Docker entrypoint script will automatically detect SSL requirement from:
   - `rediss://` in `REDIS_BROKER_URL`, OR
   - Non-standard port (not 6379) like your port 10023

## Setting in Render.com

1. Go to your **Web Service** in Render dashboard
2. Click on **"Environment"** tab
3. Add or update these variables:
   - `REDIS_HOST` = `redis-206667-0.cloudclusters.net`
   - `REDIS_PORT` = `10023`
   - `REDIS_PASSWORD` = `nz4Sf22Yi35C`
   - `REDIS_BROKER_URL` = `rediss://flight_blender:nz4Sf22Yi35C@redis-206667-0.cloudclusters.net:10023`
   - `REDIS_USERNAME` = `flight_blender` (optional, extracted from URL if not set)

4. Do the same for your **Worker Service**

5. **Redeploy** your services after updating environment variables

## Verification

After updating, check your deployment logs. You should see:
```
Detected SSL requirement from REDIS_BROKER_URL (rediss://)
Redis is ready!
```

If you see connection errors, verify:
- All environment variables are set correctly
- `REDIS_BROKER_URL` uses `rediss://` not `redis://`
- Password and username are correct
- Redis service is accessible from Render.com

## Troubleshooting

### Still seeing "Waiting for Redis..." errors?

1. **Check REDIS_BROKER_URL format**: Must be `rediss://` for SSL
2. **Verify credentials**: Username and password must match your Redis provider
3. **Check network**: Ensure Render.com can reach your Redis host
4. **Review logs**: Look for specific error messages in the deployment logs

### Connection timeout errors?

- The script will try for 30 attempts (60 seconds total)
- If it fails, check that your Redis host is accessible
- Verify firewall rules allow connections from Render.com IPs

## Updated Entrypoint Scripts

The Docker entrypoint scripts have been updated to:
- ✅ Auto-detect SSL requirement from non-standard ports
- ✅ Extract username from REDIS_BROKER_URL if not set separately
- ✅ Provide better error messages
- ✅ Show connection attempt progress

No code changes needed - just update your environment variables in Render.com!
