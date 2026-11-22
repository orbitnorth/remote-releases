#!/usr/bin/env bash
# ==============================================================================
# OrbitNorth Remote — Diagnostics Script
# ==============================================================================

set -u

echo "================================================="
echo "   OrbitNorth Remote VPS Health Check Diagnostic "
echo "================================================="

# 1. Process
echo -n "Checking PM2 process 'remote'... "
if pm2 describe remote >/dev/null 2>&1; then
  STATUS=$(pm2 jlist | grep -o '"pm2_env":{"status":"[^"]*"' | head -n1 | cut -d'"' -f6)
  echo "ONLINE (${STATUS})"
else
  echo "NOT RUNNING"
fi

# 2. Port listening
echo -n "Checking port 7682... "
if command -v ss >/dev/null 2>&1 && ss -tulpn | grep -q ":7682"; then
  echo "LISTENING"
elif command -v netstat >/dev/null 2>&1 && netstat -tulpn | grep -q ":7682"; then
  echo "LISTENING"
else
  echo "NOT DETECTED"
fi

# 3. HTTP Health
echo -n "Testing http://127.0.0.1:7682/health... "
HEALTH=$(curl -s http://127.0.0.1:7682/health || echo "FAILED")
if echo "$HEALTH" | grep -q "ok"; then
  echo "OK"
else
  echo "FAILED (${HEALTH})"
fi

# 4. Storage check
echo -n "Checking storage directory /opt/remote/data... "
if [ -d "/opt/remote/data" ]; then
  echo "EXISTS ($(du -sh /opt/remote/data | cut -f1))"
else
  echo "MISSING"
fi

echo "================================================="
