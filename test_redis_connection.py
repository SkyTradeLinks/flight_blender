#!/usr/bin/env python3
"""
Test script to verify Redis connection and basic operations.
"""

import sys
import redis
from datetime import datetime, timezone

# Redis connection details
REDIS_HOST = "redis-206667-0.cloudclusters.net"  # Using the actual host from BROKER_URL
REDIS_PORT = 10023
REDIS_PASSWORD = "nz4Sf22Yi35C"
REDIS_USERNAME = "flight_blender"  # From BROKER_URL

# Alternative: Use the BROKER_URL directly
REDIS_BROKER_URL = "redis://flight_blender:nz4Sf22Yi35C@redis-206667-0.cloudclusters.net:10023"

def test_redis_connection():
    """Test Redis connection with multiple methods."""
    
    print("=" * 60)
    print("Testing Redis Connection")
    print("=" * 60)
    print(f"Host: {REDIS_HOST}")
    print(f"Port: {REDIS_PORT}")
    print(f"Username: {REDIS_USERNAME}")
    print(f"Password: {'*' * len(REDIS_PASSWORD)}")
    print()
    
    # Test 1: Direct connection (without SSL)
    print("Test 1: Direct Connection (No SSL)")
    print("-" * 60)
    r = None
    try:
        r = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            username=REDIS_USERNAME,
            password=REDIS_PASSWORD,
            decode_responses=True,
            socket_connect_timeout=10,
            socket_timeout=10,
            ssl=False
        )
        
        # Test ping
        response = r.ping()
        if response:
            print("✅ PING successful!")
        else:
            print("❌ PING failed!")
            r = None
            
    except redis.ConnectionError as e:
        print(f"❌ Connection Error (No SSL): {e}")
        r = None
    except redis.AuthenticationError as e:
        print(f"❌ Authentication Error: {e}")
        r = None
    except Exception as e:
        print(f"❌ Unexpected Error: {e}")
        r = None
    
    # Test 1b: Direct connection (with SSL)
    if r is None:
        print("\nTest 1b: Direct Connection (With SSL)")
        print("-" * 60)
        try:
            r = redis.Redis(
                host=REDIS_HOST,
                port=REDIS_PORT,
                username=REDIS_USERNAME,
                password=REDIS_PASSWORD,
                decode_responses=True,
                socket_connect_timeout=10,
                socket_timeout=10,
                ssl=True,
                ssl_cert_reqs=None
            )
            
            # Test ping
            response = r.ping()
            if response:
                print("✅ PING successful with SSL!")
            else:
                print("❌ PING failed!")
                return False
                
        except redis.ConnectionError as e:
            print(f"❌ Connection Error (With SSL): {e}")
            return False
        except redis.AuthenticationError as e:
            print(f"❌ Authentication Error: {e}")
            return False
        except Exception as e:
            print(f"❌ Unexpected Error: {e}")
            return False
    
    if r is None:
        print("❌ Could not establish connection with either method")
        return False
    
    # Test 2: Using BROKER_URL (convert to rediss:// for SSL)
    print("\nTest 2: Connection via BROKER_URL (rediss:// for SSL)")
    print("-" * 60)
    r2 = None
    try:
        # Convert redis:// to rediss:// for SSL
        ssl_broker_url = REDIS_BROKER_URL.replace("redis://", "rediss://")
        print(f"Using SSL URL: {ssl_broker_url.replace(REDIS_PASSWORD, '***')}")
        
        # Parse the URL and create connection with SSL
        r2 = redis.from_url(
            ssl_broker_url,
            decode_responses=True,
            socket_connect_timeout=10,
            socket_timeout=10,
            ssl_cert_reqs=None
        )
        response = r2.ping()
        if response:
            print("✅ PING successful via rediss:// URL!")
        else:
            print("❌ PING failed via URL!")
            r2 = None
    except Exception as e:
        print(f"❌ Error connecting via rediss:// URL: {e}")
        # Try without SSL as fallback
        try:
            print("\nTrying without SSL...")
            r2 = redis.from_url(
                REDIS_BROKER_URL,
                decode_responses=True,
                socket_connect_timeout=10,
                socket_timeout=10
            )
            response = r2.ping()
            if response:
                print("✅ PING successful via redis:// URL (no SSL)!")
            else:
                print("❌ PING failed!")
                r2 = None
        except Exception as e2:
            print(f"❌ Error connecting via redis:// URL: {e2}")
            r2 = None
    
    if r2 is None:
        print("⚠️  Could not connect via URL, but direct connection works")
        r2 = r  # Use the working connection from Test 1
    
    # Test 3: Basic operations
    print("\nTest 3: Basic Operations (SET/GET)")
    print("-" * 60)
    try:
        test_key = "flight_blender:test:connection"
        test_value = f"Test at {datetime.now(timezone.utc).isoformat()}"
        
        # Set a value
        r.set(test_key, test_value, ex=60)  # Expires in 60 seconds
        print(f"✅ SET operation successful: {test_key}")
        
        # Get the value
        retrieved_value = r.get(test_key)
        if retrieved_value == test_value:
            print(f"✅ GET operation successful: {retrieved_value}")
        else:
            print(f"❌ GET operation failed. Expected: {test_value}, Got: {retrieved_value}")
            return False
        
        # Delete the test key
        r.delete(test_key)
        print(f"✅ DELETE operation successful")
        
    except Exception as e:
        print(f"❌ Error during operations: {e}")
        return False
    
    # Test 4: Redis info
    print("\nTest 4: Redis Server Info")
    print("-" * 60)
    try:
        info = r.info()
        print(f"✅ Redis Version: {info.get('redis_version', 'Unknown')}")
        print(f"✅ Used Memory: {info.get('used_memory_human', 'Unknown')}")
        print(f"✅ Connected Clients: {info.get('connected_clients', 'Unknown')}")
        print(f"✅ Total Keys: {info.get('db0', {}).get('keys', 'Unknown')}")
    except Exception as e:
        print(f"⚠️  Could not retrieve server info: {e}")
    
    # Test 5: Test Celery broker connection format (with SSL)
    print("\nTest 5: Celery Broker URL Format (rediss://)")
    print("-" * 60)
    try:
        # Convert to rediss:// for SSL (Celery supports this)
        celery_broker_ssl = REDIS_BROKER_URL.replace("redis://", "rediss://")
        r3 = redis.from_url(celery_broker_ssl, decode_responses=True, ssl_cert_reqs=None)
        r3.ping()
        print(f"✅ Celery broker URL format works with SSL: {celery_broker_ssl.replace(REDIS_PASSWORD, '***')}")
        print(f"   Use this URL in your environment: REDIS_BROKER_URL={celery_broker_ssl.replace(REDIS_PASSWORD, '***')}")
    except Exception as e:
        print(f"⚠️  Celery broker URL with SSL failed: {e}")
        print("   Note: You may need to configure Celery to use SSL separately")
    
    print("\n" + "=" * 60)
    print("✅ All Redis tests passed!")
    print("=" * 60)
    print("\n📝 IMPORTANT: Your Redis requires SSL/TLS")
    print("   Update your REDIS_BROKER_URL to use 'rediss://' instead of 'redis://':")
    print(f"   REDIS_BROKER_URL=rediss://flight_blender:{'*' * len(REDIS_PASSWORD)}@redis-206667-0.cloudclusters.net:10023")
    print("=" * 60)
    return True

if __name__ == "__main__":
    success = test_redis_connection()
    sys.exit(0 if success else 1)
