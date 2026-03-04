#!/usr/bin/env python3
"""Simple script to wait for services to be available."""
import sys
import socket
import time

def wait_for_service(host, port, timeout=30):
    """Wait for a service to be available on host:port."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((host, port))
            sock.close()
            if result == 0:
                print(f"Service {host}:{port} is available")
                return True
        except Exception as e:
            pass
        time.sleep(1)
    print(f"Timeout waiting for {host}:{port}")
    return False

if __name__ == "__main__":
    services = []
    i = 1
    while i < len(sys.argv):
        if sys.argv[i] == "--service" and i + 1 < len(sys.argv):
            host, port = sys.argv[i + 1].split(":")
            services.append((host, int(port)))
            i += 2
        else:
            i += 1
    
    if not services:
        print("Usage: wait_for_service.py --service host:port [--service host:port ...]")
        sys.exit(1)
    
    all_available = True
    for host, port in services:
        if not wait_for_service(host, port):
            all_available = False
    
    sys.exit(0 if all_available else 1)
